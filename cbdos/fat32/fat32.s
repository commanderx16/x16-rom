;-----------------------------------------------------------------------------
; fat32.s
; Copyright (C) 2020 Frank van den Hoef
;
; TODO:
; - implement fat32_seek
;-----------------------------------------------------------------------------

	.include "fat32.inc"
	.include "lib.inc"
	.include "sdcard.inc"
	.include "text_input.inc"

	.import sector_buffer, sector_buffer_end, sector_lba

	.import match_name, match_type

CONTEXT_SIZE = 32

FLAG_IN_USE = 1<<0  ; Context in use
FLAG_DIRTY  = 1<<1  ; Buffer is dirty
FLAG_DIRENT = 1<<2  ; Directory entry needs to be updated on close

.struct context
flags           .byte    ; Flag bits
cluster         .dword   ; Current cluster
lba             .dword   ; Sector of current cluster
cluster_sector  .byte    ; Sector index within current cluster
bufptr          .word    ; Pointer within sector_buffer
file_size       .dword   ; Size of current file
file_offset     .dword   ; Offset in current file
dirent_lba      .dword   ; Sector containing directory entry for this file
dirent_bufptr   .word    ; Offset to start of directory entry 
.endstruct

	.bss
_fat32_bss_start:

fat32_size:
	.res 4 ; dword - Used for fat32_get_free_space result
fat32_cwd_cluster:
	.res 4 ; dword - Cluster of current directory
fat32_dirent:
	.res 22 ; 22 bytes - Buffer containing decoded directory entry
fat32_errno:
	.byte 0 ; byte - last error

; Static filesystem parameters
rootdir_cluster:     .dword 0      ; Cluster of root directory
sectors_per_cluster: .byte 0       ; Sectors per cluster
cluster_shift:       .byte 0       ; Log2 of sectors_per_cluster
lba_partition:       .dword 0      ; Start sector of FAT32 partition
partition_type:      .byte 0       ; MBR Partition type
partition_blocks:    .dword 0      ; Number of blocks in partition
fat_size:            .dword 0      ; Size in sectors of each FAT table
lba_fat:             .dword 0      ; Start sector of first FAT table
lba_data:            .dword 0      ; Start sector of first data cluster
cluster_count:       .dword 0      ; Total number of cluster on volume
lba_fsinfo:          .dword 0      ; Sector number of FS info

; Variables
free_clusters:       .dword 0      ; Number of free clusters (from FS info)
free_cluster:        .dword 0      ; Cluster to start search for free clusters, also holds result of find_free_cluster
filename_buf:        .res 11       ; Used for filename conversion

; Temp buffers
bytecnt:             .word 0       ; Used by fat32_write
tmp_buf:             .res 4        ; Used by save_sector_buffer, fat32_rename
next_sector_arg:     .byte 0       ; Used by next_sector to store argument
tmp_bufptr:          .word 0       ; Used by next_sector
tmp_sector_lba:      .dword 0      ; Used by next_sector

name_offset:         .byte 0
tmp_dir_cluster:     .dword 0

; Contexts
context_idx:         .byte 0       ; Index of current context
cur_context:         .tag context  ; Current file descriptor state
contexts_inuse:      .res FAT32_CONTEXTS

.if FAT32_CONTEXTS > 1
contexts:            .res CONTEXT_SIZE * FAT32_CONTEXTS
.endif

.if CONTEXT_SIZE * FAT32_CONTEXTS > 256
.error "FAT32_CONTEXTS > 8"
.endif

.if .sizeof(context) > CONTEXT_SIZE
.error "Context too big"
.endif

_fat32_bss_end:

	.code

;-----------------------------------------------------------------------------
; set_errno
;
; Only set errno if it wasn't already set.
; If a read error causes a file not found error, it's still a read error.
;-----------------------------------------------------------------------------
set_errno:
	clc
	pha
	lda fat32_errno
	bne @1
	pla
	sta fat32_errno
	rts

@1:	pla
	rts

;-----------------------------------------------------------------------------
; sync_sector_buffer
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
sync_sector_buffer:
	; Write back sector buffer if dirty
	lda cur_context + context::flags
	bit #FLAG_DIRTY
	beq @done
	jmp save_sector_buffer

@done:	sec
	rts

;-----------------------------------------------------------------------------
; load_sector_buffer
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
load_sector_buffer:
	; Check if sector is already loaded
	cmp32_ne cur_context + context::lba, sector_lba, @do_load
	sec
	rts

@do_load:
	jsr sync_sector_buffer
	set32 sector_lba, cur_context + context::lba
	jsr sdcard_read_sector
	bcc @1
	rts

@1:
	lda #ERRNO_READ
	jmp set_errno

;-----------------------------------------------------------------------------
; save_sector_buffer
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
save_sector_buffer:
	; Determine if this is FAT area write (sector_lba - lba_fat < fat_size)
	sub32 tmp_buf, sector_lba, lba_fat
	lda tmp_buf + 2
	ora tmp_buf + 3
	bne @normal
	sec
	lda tmp_buf + 0
	sbc fat_size + 0
	lda tmp_buf + 1
	sbc fat_size + 1
	bcs @normal

	; Write second FAT
	set32 tmp_buf, sector_lba
	add32 sector_lba, sector_lba, fat_size
	jsr sdcard_write_sector
	php
	set32 sector_lba, tmp_buf
	plp
	bcc @error_write

@normal:
	jsr sdcard_write_sector
	bcc @error_write

	; Clear dirty bit
	lda cur_context + context::flags
	and #(FLAG_DIRTY ^ $FF)
	sta cur_context + context::flags

	sec
	rts

@error_write:
	lda #ERRNO_WRITE
	jmp set_errno

;-----------------------------------------------------------------------------
; calc_cluster_lba
;-----------------------------------------------------------------------------
calc_cluster_lba:
	; lba = lba_data + ((cluster - 2) << cluster_shift)
	sub32_val cur_context + context::lba, cur_context + context::cluster, 2
	ldy cluster_shift
	beq @shift_done
@1:	shl32 cur_context + context::lba
	dey
	bne @1
@shift_done:

	add32 cur_context + context::lba, cur_context + context::lba, lba_data
	stz cur_context + context::cluster_sector
	rts

;-----------------------------------------------------------------------------
; load_fat_sector_for_cluster
;
; Load sector that hold cluster entry for cur_context.cluster
; On return fat32_bufptr points to cluster entry in sector_buffer.
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
load_fat_sector_for_cluster:
	; Calculate sector where cluster entry is located

	; lba = lba_fat + (cluster / 128)
	lda cur_context + context::cluster + 1
	sta cur_context + context::lba + 0
	lda cur_context + context::cluster + 2
	sta cur_context + context::lba + 1
	lda cur_context + context::cluster + 3
	sta cur_context + context::lba + 2
	stz cur_context + context::lba + 3
	lda cur_context + context::cluster + 0
	asl	; upper bit in C
	rol cur_context + context::lba + 0
	rol cur_context + context::lba + 1
	rol cur_context + context::lba + 2
	rol cur_context + context::lba + 3
	add32 cur_context + context::lba, cur_context + context::lba, lba_fat

	; Read FAT sector
	jsr load_sector_buffer
	bcs @1
	rts	; Failure
@1:
	; fat32_bufptr = sector_buffer + (cluster & 127) * 4
	lda cur_context + context::cluster
	asl
	asl
	sta fat32_bufptr + 0
	lda #0
	bcc @2
	lda #1
@2:	sta fat32_bufptr + 1
	add16_val fat32_bufptr, fat32_bufptr, sector_buffer

	; Success
	sec
	rts

;-----------------------------------------------------------------------------
; is_end_of_cluster_chain 
;-----------------------------------------------------------------------------
is_end_of_cluster_chain:
	; Check if this is the end of cluster chain (entry >= 0x0FFFFFF8)
	lda cur_context + context::cluster + 3
	and #$0F	; Ignore upper 4 bits
	cmp #$0F
	bne @no
	lda cur_context + context::cluster + 2
	cmp #$FF
	bne @no
	lda cur_context + context::cluster + 1
	cmp #$FF
	bne @no
	lda cur_context + context::cluster + 0
	cmp #$F8
	bcs @yes
@no:	clc
@yes:	rts

;-----------------------------------------------------------------------------
; next_cluster
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
next_cluster:
	; End of cluster chain?
	jsr is_end_of_cluster_chain
	bcs @error

	; Load correct FAT sector
	jsr load_fat_sector_for_cluster
	bcc @error

	; Copy next cluster from FAT
	ldy #0
@1:	lda (fat32_bufptr), y
	sta cur_context + context::cluster, y
	iny
	cpy #4
	bne @1

	sec
	rts

@error:	clc
	rts

;-----------------------------------------------------------------------------
; unlink_cluster_chain
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
unlink_cluster_chain:
	; Don't unlink cluster 0
	lda cur_context + context::cluster + 0
	ora cur_context + context::cluster + 1
	ora cur_context + context::cluster + 2
	ora cur_context + context::cluster + 3
	bne @next
	sec
	rts

@next:	jsr next_cluster
	bcs @0
	lda fat32_errno
	beq @done
	clc
	rts

@0:
	; Set this cluster as new search start point if lower than current start point
	ldy #3
	lda free_cluster + 3
	cmp (fat32_bufptr), y
	bcc @2
	dey
	lda free_cluster + 2
	cmp (fat32_bufptr), y
	bcc @2
	dey
	lda free_cluster + 1
	cmp (fat32_bufptr), y
	bcc @2
	dey
	lda free_cluster + 0
	cmp (fat32_bufptr), y
	bcc @2
	beq @2

	ldy #0
@1:	lda (fat32_bufptr), y
	sta free_cluster, y
	iny
	cpy #4
	bne @1
@2:
	; Set entry as free
	lda #0
	ldy #0
	sta (fat32_bufptr), y
	iny
	sta (fat32_bufptr), y
	iny
	sta (fat32_bufptr), y
	iny
	sta (fat32_bufptr), y

	; Increment free clusters
	inc32 free_clusters

	; Set sector as dirty
	lda cur_context + context::flags
	ora #FLAG_DIRTY
	sta cur_context + context::flags

	bra @next

	; Make sure dirty sectors are written to disk
@done:	jsr sync_sector_buffer
	bcs @3
	rts

@3:	jmp update_fs_info

;-----------------------------------------------------------------------------
; find_free_cluster
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
find_free_cluster:
	; Start search at free_cluster
	set32 cur_context + context::cluster, free_cluster
	jsr load_fat_sector_for_cluster
	bcs @next
	rts

@next:	; Check for free entry
	ldy #3
	lda (fat32_bufptr), y
	and #$0F	; Ignore upper 4 bits of 32-bit entry
	dey
	ora (fat32_bufptr), y
	dey
	ora (fat32_bufptr), y
	dey
	ora (fat32_bufptr), y
	bne @not_free

	; Return found free cluster
	set32 free_cluster, cur_context + context::cluster
	sec
	rts

@not_free:
	; fat32_bufptr += 4
	add16_val fat32_bufptr, fat32_bufptr, 4

	; cluster += 1
	inc32 cur_context + context::cluster

	; Check if at end of FAT table
	cmp32_ne cur_context + context::cluster, cluster_count, @1
	clc
	rts
@1:
	; Load next FAT sector if at end of buffer
	cmp16_val_ne fat32_bufptr, sector_buffer_end, @next
	inc32 cur_context + context::lba
	jsr load_sector_buffer
	bcs @2
	rts
@2:	set16_val fat32_bufptr, sector_buffer
	jmp @next

;-----------------------------------------------------------------------------
; fat32_alloc_context
;-----------------------------------------------------------------------------
fat32_alloc_context:
	ldx #0
@1:	lda contexts_inuse, x
	beq @found_free
	inx
	cpx #FAT32_CONTEXTS
	bne @1

@fat32_alloc_context_error:
	clc
	rts

@found_free:
	lda #1
	sta contexts_inuse, x
	txa
	sec
@fat32_alloc_context_ok:
	rts

;-----------------------------------------------------------------------------
; fat32_free_context
;-----------------------------------------------------------------------------
fat32_free_context:
	cmp #FAT32_CONTEXTS
	bcc @1
@fail:	clc
	rts
@1:
	tax
	lda contexts_inuse, x
	beq @fail
	stz contexts_inuse, x
	sec
	rts

;-----------------------------------------------------------------------------
; update_fs_info
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
update_fs_info:
	; Load FS info sector
	set32 cur_context + context::lba, lba_fsinfo
	jsr load_sector_buffer
	bcs @1
	rts
@1:
	; Get number of free clusters
	set32 sector_buffer + 488, free_clusters

	; Save sector
	jmp save_sector_buffer

;-----------------------------------------------------------------------------
; allocate_cluster
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
allocate_cluster:
	; Find free entry
	jsr find_free_cluster
	bcs @1
	rts
@1:
	; Set cluster as end-of-chain
	ldy #0
	lda #$FF
	sta (fat32_bufptr), y
	iny
	sta (fat32_bufptr), y
	iny
	sta (fat32_bufptr), y
	iny
	lda (fat32_bufptr), y
	ora #$0F	; Preserve upper 4 bits
	sta (fat32_bufptr), y

	; Save FAT sector
	jsr save_sector_buffer
	bcs @2
	rts
@2:
	; Decrement free clusters and update FS info
	dec32 free_clusters
	jmp update_fs_info

;-----------------------------------------------------------------------------
; validate_char
;-----------------------------------------------------------------------------
validate_char:
	; Allowed: 33, 35-41, 45, 48-57, 64-90, 94-96, 123, 125, 126
	cmp #33
	beq @ok
	cmp #35
	bcc @not_ok
	cmp #41+1
	bcc @ok
	cmp #45
	beq @ok
	cmp #48
	bcc @not_ok
	cmp #57+1
	bcc @ok
	cmp #64
	bcc @not_ok
	cmp #90+1
	bcc @ok
	cmp #94
	bcc @not_ok
	cmp #96
	bcc @ok
	cmp #123
	beq @ok
	cmp #125
	beq @ok
	cmp #126
	beq @ok

@not_ok:
	clc
	rts
@ok:	sec
	rts

;-----------------------------------------------------------------------------
; convert_filename
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
convert_filename:
	ldy name_offset

	; Disallow empty string or string starting with '.'
	lda (fat32_ptr), y
	beq @not_ok
	cmp #'.'
	beq @not_ok

	; Copy name part
	ldx #0
@loop1:	lda (fat32_ptr), y
	beq @name_pad
	cmp #'.'
	beq @name_pad
	jsr to_upper
	jsr validate_char
	bcc @not_ok
	sta filename_buf, x
	inx
	iny
	cpx #8
	bne @loop1

	; Pad name with spaces
@name_pad:
	lda #' '
@loop2:	cpx #8
	beq @name_pad_done
	sta filename_buf, x
	inx
	bra @loop2
@name_pad_done:

	; Check next character
	lda (fat32_ptr), y
	beq @ext_pad
	cmp #'.'
	beq @ext
	bra @not_ok

	; Copy extension part
@ext:	iny	; Skip '.'

@loop3:	lda (fat32_ptr), y
	beq @ext_pad
	jsr to_upper
	jsr validate_char
	bcc @not_ok
	sta filename_buf, x
	inx
	iny
	cpx #11
	bne @loop3

	; Check for end of string
	lda (fat32_ptr), y
	bne @not_ok

	; Pad extension with spaces
@ext_pad:
	lda #' '
@loop4:	cpx #11
	beq @ext_pad_done
	sta filename_buf, x
	inx
	bra @loop4
@ext_pad_done:

	; Done
	sec
	rts

@not_ok:
	lda #ERRNO_ILLEGAL_FILENAME
	jmp set_errno

;-----------------------------------------------------------------------------
; open_cluster
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
open_cluster:
	; Check if cluster == 0 -> modify into root dir
	lda cur_context + context::cluster + 0
	ora cur_context + context::cluster + 1
	ora cur_context + context::cluster + 2
	ora cur_context + context::cluster + 3
	bne @readsector
	set32 cur_context + context::cluster, rootdir_cluster

@readsector:
	; Read first sector of cluster
	jsr calc_cluster_lba
	jsr load_sector_buffer
	bcc @done

	; Reset buffer pointer
	set16_val fat32_bufptr, sector_buffer

	sec
@done:	rts

;-----------------------------------------------------------------------------
; clear_cluster
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
clear_cluster:
	; Fill sector buffer with 0
	lda #0
	ldy #0
@1:	sta sector_buffer, y
	sta sector_buffer + 256, y
	iny
	bne @1

	; Write sectors
	jsr calc_cluster_lba
@2:	set32 sector_lba, cur_context + context::lba
	jsr sdcard_write_sector
	bcs @3
	rts
@3:	lda cur_context + context::cluster_sector
	inc
	cmp sectors_per_cluster
	beq @wrdone
	sta cur_context + context::cluster_sector
	inc32 cur_context + context::lba
	bra @2

@wrdone:
	sec
	rts

;-----------------------------------------------------------------------------
; next_sector
; A: bit0 - allocate cluster if at end of cluster chain
;    bit1 - clear allocated cluster
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
next_sector:
	; Save argument
	sta next_sector_arg

	; Last sector of cluster?
	lda cur_context + context::cluster_sector
	inc
	cmp sectors_per_cluster
	beq @end_of_cluster
	sta cur_context + context::cluster_sector

	; Load next sector
	inc32 cur_context + context::lba
@read_sector:
	jsr load_sector_buffer
	bcc @error
	set16_val fat32_bufptr, sector_buffer
	sec
	rts

@end_of_cluster:
	jsr next_cluster
	bcc @error
	jsr is_end_of_cluster_chain
	bcs @end_of_chain
@read_cluster:
	jsr calc_cluster_lba
	bra @read_sector

@end_of_chain:
	; Request to allocate new cluster?
	lda next_sector_arg
	bit #$01
	beq @error

	; Save location of cluster entry in FAT
	set16 tmp_bufptr, fat32_bufptr
	set32 tmp_sector_lba, sector_lba

	; Allocate a new cluster
	jsr allocate_cluster
	bcc @error

	; Load back the cluster sector
	set32 cur_context + context::lba, tmp_sector_lba
	jsr load_sector_buffer
	bcs @1
@error:	clc
	rts
@1:
	set16 fat32_bufptr, tmp_bufptr
	
	; Write allocated cluster number in FAT
	ldy #0
@2:	lda free_cluster, y
	sta (fat32_bufptr), y
	iny
	cpy #4
	bne @2

	; Save FAT sector
	jsr save_sector_buffer
	bcc @error

	; Set allocated cluster as current
	set32 cur_context + context::cluster, free_cluster

	; Request to clear new cluster?
	lda next_sector_arg
	bit #$02
	beq @wrdone
	jsr clear_cluster
	bcc @error

@wrdone:
	; Retry
	jmp @read_cluster

;-----------------------------------------------------------------------------
; find_dirent
;
; Find directory entry with path specified in string pointed to by fat32_ptr
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
find_dirent:
	stz name_offset

	; If path starts with a slash, use root directory as base,
	; otherwise the current directory.
	lda (fat32_ptr)
	cmp #'/'
	bne @use_current
	set32_val cur_context + context::cluster, 0
	inc name_offset

	; Does path only consists of a slash?
	ldy name_offset
	lda (fat32_ptr), y
	bne @open

	; Fake a directory entry for the root directory
	lda #'/'
	sta fat32_dirent + dirent::name
	stz fat32_dirent + dirent::name + 1
	lda #$10
	sta fat32_dirent + dirent::attributes
	ldx #0
@clr:	stz fat32_dirent + dirent::size, x
	inx
	cpx #8
	bne @clr

	sec
	rts

@use_current:
	set32 cur_context + context::cluster, fat32_cwd_cluster

@open:	set32 tmp_dir_cluster, cur_context + context::cluster

	jsr open_cluster
	bcc @error

@next:	; Read entry
	jsr fat32_read_dirent
	bcc @error

	ldy name_offset
	jsr match_name
	bcc @next

	; Check for '/'
	lda (fat32_ptr), y
	cmp #'/'
	beq @chdir

	lda fat32_dirent + dirent::attributes
	jsr match_type
	bcc @next

@found:	; Found
	sec
	rts

@error:	clc
	rts

@chdir:	iny
	lda (fat32_ptr), y
	beq @found

	; Is this a directory?
	lda fat32_dirent + dirent::attributes
	bit #$10
	beq @error

	sty name_offset

	set32 cur_context + context::cluster, fat32_dirent + dirent::cluster
	set32 tmp_dir_cluster, fat32_dirent + dirent::cluster
	jmp @open

;-----------------------------------------------------------------------------
; find_file
;
; Same as find_dirent, but with file type check
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
find_file:
	; Find directory entry
	jsr find_dirent
	bcc @error

	; Check if this is a file
	lda fat32_dirent + dirent::attributes
	bit #$10
	bne @error

	; Success
	sec
	rts

@error:	clc
	rts

;-----------------------------------------------------------------------------
; find_dir
;
; Same as find_dirent, but with directory type check
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
find_dir:
	; Find directory entry
	jsr find_dirent
	bcc @error

	; Check if this is a directory
	lda fat32_dirent + dirent::attributes
	bit #$10
	beq @error

	; Success
	sec
	rts

@error:	clc
	rts

;-----------------------------------------------------------------------------
; delete_file
;
; * c=0: failure; sets errno
; * does not set errno = ERRNO_FILE_NOT_FOUND!
;-----------------------------------------------------------------------------
delete_file:
	; Find file
	jsr find_file
	bcc @error

	set16 fat32_bufptr, cur_context + context::dirent_bufptr

	ldy #11
	lda (fat32_bufptr),y
	and #1
	beq @1

	; read-only file
	lda #ERRNO_FILE_READ_ONLY
	jmp set_errno

@1:	; Mark file as deleted
	lda #$E5
	sta (fat32_bufptr)

	; Write sector buffer to disk
	jsr save_sector_buffer
	bcc @error

	; Unlink cluster chain
	set32 cur_context + context::cluster, fat32_dirent + dirent::cluster
	jmp unlink_cluster_chain

@error:	rts

;-----------------------------------------------------------------------------
; fat32_init
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_init:
	stz fat32_errno

	; Initialize SD card
	jsr sdcard_init
	bcs @0
	lda #ERRNO_NO_MEDIA
	jmp set_errno

@0:
	; Clear FAT32 BSS
	set16_val fat32_bufptr, _fat32_bss_start
	lda #0
@1:	sta (fat32_bufptr)
	inc fat32_bufptr + 0
	bne @2
	inc fat32_bufptr + 1
@2:	ldx fat32_bufptr + 0
	cpx #<_fat32_bss_end
	bne @1
	ldx fat32_bufptr + 1
	cpx #>_fat32_bss_end
	bne @1

	; Make sure sector_lba is non-zero
	lda #$FF
	sta sector_lba

	; Set initial start point for free cluster search
	set32_val free_cluster, 2

	; Read partition table (sector 0)
	; cur_context::lba already 0
	jsr load_sector_buffer
	bcs @2a
@error:	clc
	rts

@2a:	; Check partition type of first partition
	lda sector_buffer + $1BE + 4
	sta partition_type
	cmp #$0B
	beq @3
	cmp #$0C
	beq @3
	lda #ERRNO_NO_FS
	jmp set_errno

@3:
	; Get LBA of first partition
	set32 lba_partition, sector_buffer + $1BE + 8
	set32 partition_blocks, sector_buffer + $1BE + 12

	; Read first sector of partition
	set32 cur_context + context::lba, lba_partition
	jsr load_sector_buffer
	bcc @error

	; Some sanity checks
	lda sector_buffer + 510 ; Check signature
	cmp #$55
	beq :+
@fs_inconsistent:
	lda #ERRNO_FS_INCONSISTENT
	jmp set_errno
:	lda sector_buffer + 511
	cmp #$AA
	bne @fs_inconsistent
	lda sector_buffer + 16 ; # of FATs should be 2
	cmp #2
	bne @fs_inconsistent
	lda sector_buffer + 17 ; Root entry count = 0 for FAT32
	bne @fs_inconsistent
	lda sector_buffer + 18
	bne @fs_inconsistent

	; Get sectors per cluster
	lda sector_buffer + 13
	sta sectors_per_cluster
	beq @fs_inconsistent

	; Calculate shift amount based on sectors per cluster
	; cluster_shift already 0
@4:	lsr
	beq @5
	inc cluster_shift
	bra @4
@5:
	; FAT size in sectors
	set32 fat_size, sector_buffer + 36

	; Root cluster
	set32 rootdir_cluster, sector_buffer + 44

	; Calculate LBA of first FAT
	add32_16 lba_fat, lba_partition, sector_buffer + 14

	; Calculate LBA of first data sector
	add32 lba_data, lba_fat, fat_size
	add32 lba_data, lba_data, fat_size

	; Calculate number of clusters on volume: (total_sectors - lba_data) >> cluster_shift
	set32 cluster_count, sector_buffer + 32
	sub32 cluster_count, cluster_count, lba_data
	ldy cluster_shift
	beq @7
@6:	shr32 cluster_count
	dey
	bne @6
@7:
	; Get FS info sector
	add32_16 lba_fsinfo, lba_partition, sector_buffer + 48

	; Load FS info sector
	set32 cur_context + context::lba, lba_fsinfo
	jsr load_sector_buffer
	bcs @8
	rts
@8:
	; Get number of free clusters
	set32 free_clusters, sector_buffer + 488

	; Success
	sec
	rts

;-----------------------------------------------------------------------------
; fat32_set_context
;
; context index in A
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
; TODO: even in the error case, the context must always been set, otherwise
; we are stuck.
fat32_set_context:
	stz fat32_errno

	; Already selected?
	cmp context_idx
	beq @done

	; Valid context index?
	cmp #FAT32_CONTEXTS
	bcs @error

.if ::FAT32_CONTEXTS > 1
	; Save new context index
	pha

	; Save dirty sector
	jsr sync_sector_buffer
	bcc @error

	; Put zero page variables in current context
	set16 cur_context + context::bufptr, fat32_bufptr

	; Copy current context back
	lda context_idx   ; X=A*32
	asl
	asl
	asl
	asl
	asl
	tax

	ldy #0
@1:	lda cur_context, y
	sta contexts, x
	inx
	iny
	cpy #(.sizeof(context))
	bne @1

	; Copy new context to current
	pla              ; Get new context idx
	sta context_idx  ; X=A*32
	asl
	asl
	asl
	asl
	asl
	tax

	ldy #0
@2:	lda contexts, x
	sta cur_context, y
	inx
	iny
	cpy #(.sizeof(context))
	bne @2

	; Restore zero page variables from current context
	set16 fat32_bufptr, cur_context + context::bufptr

	; Reload sector
	lda cur_context + context::flags
	bit #FLAG_IN_USE
	beq @reload_done
	jsr load_sector_buffer
	bcc @error
@reload_done:
.endif

@done:	sec
	rts
@error:	clc
	rts

;-----------------------------------------------------------------------------
; fat32_get_context
;-----------------------------------------------------------------------------
fat32_get_context:
	lda context_idx
	rts

;-----------------------------------------------------------------------------
; fat32_open_dir
;
; Open current working directory
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_open_dir:
	stz fat32_errno

	; Check if context is free
	lda cur_context + context::flags
	bne @error

	; Use current directory if fat32_ptr is zero
	cmp16_z fat32_ptr, @cur_dir

	; Find directory and use it
	jsr find_dir
	bcs @1
	lda #ERRNO_FILE_NOT_FOUND
	jmp set_errno

@1:
	set32 cur_context + context::cluster, fat32_dirent + dirent::cluster
	bra @open

@cur_dir:
	; Open current directory
	set32 cur_context + context::cluster, fat32_cwd_cluster

@open:	jsr open_cluster
	bcc @error

	; Set context as in-use
	lda #FLAG_IN_USE
	sta cur_context + context::flags

	; Success
	sec
	rts

@error:	clc
	rts

;-----------------------------------------------------------------------------
; fat32_find_dirent
;-----------------------------------------------------------------------------
fat32_find_dirent:
	; Check if context is free
	lda cur_context + context::flags
	bne @error

	; Open current directory
	jmp find_dirent

@error:	clc
	rts

;-----------------------------------------------------------------------------
; fat32_read_dirent
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_read_dirent:
	stz fat32_errno

	; Load next sector if at end of buffer
	cmp16_val_ne fat32_bufptr, sector_buffer_end, @1
	lda #0
	jsr next_sector
	bcs @1
@error:	clc     ; Indicate error
	rts
@1:
	; Skip volume label entries
	ldy #11
	lda (fat32_bufptr), y
	sta fat32_dirent + dirent::attributes
	and #8
	beq @2
	jmp @next_entry
@2:
	; Last entry?
	ldy #0
	lda (fat32_bufptr), y
	beq @error

	; Skip empty entries
	cmp #$E5
	bne @3
	jmp @next_entry
@3:
	; Copy first part of file name
	ldy #0
@4:	lda (fat32_bufptr), y
	cmp #' '
	beq @skip_spaces
	sta fat32_dirent + dirent::name, y
	iny
	cpy #8
	bne @4

	; Skip any following spaces
@skip_spaces:
	tya
	tax
@5:	cpy #8
	beq @6
	lda (fat32_bufptr), y
	iny
	cmp #' '
	beq @5
@6:
	; If extension starts with a space, we're done
	lda (fat32_bufptr), y
	cmp #' '
	beq @name_done

	; Add dot to output
	lda #'.'
	sta fat32_dirent + dirent::name, x
	inx

	; Copy extension part of file name
@7:	lda (fat32_bufptr), y
	cmp #' '
	beq @name_done
	sta fat32_dirent + dirent::name, x
	iny
	inx
	cpy #11
	bne @7

@name_done:
	; Add zero-termination to output
	lda #0
	sta fat32_dirent + dirent::name, x

	; Copy file size
	ldy #28
	ldx #0
@8:	lda (fat32_bufptr), y
	sta fat32_dirent + dirent::size, x
	iny
	inx
	cpx #4
	bne @8

	; Copy cluster
	ldy #26
	lda (fat32_bufptr), y
	sta fat32_dirent + dirent::cluster + 0
	iny
	lda (fat32_bufptr), y
	sta fat32_dirent + dirent::cluster + 1
	ldy #20
	lda (fat32_bufptr), y
	sta fat32_dirent + dirent::cluster + 2
	iny
	lda (fat32_bufptr), y
	sta fat32_dirent + dirent::cluster + 3

	; Save lba + fat32_bufptr
	set32 cur_context + context::dirent_lba,    cur_context + context::lba
	set16 cur_context + context::dirent_bufptr, fat32_bufptr

	; Increment buffer pointer to next entry
	add16_val fat32_bufptr, fat32_bufptr, 32

	sec
	rts

@next_entry:
	add16_val fat32_bufptr, fat32_bufptr, 32
	jmp fat32_read_dirent


;-----------------------------------------------------------------------------
; fat32_read_dirent_filtered
;
; Returns next dirent that matches the name/pattern in (fat32_ptr)
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_read_dirent_filtered:
	stz fat32_errno

	jsr fat32_read_dirent
	bcc @error

	cmp16_z fat32_ptr, @ok

	ldy #0
	jsr match_name
	bcc fat32_read_dirent_filtered
@ok:
	sec
	rts

@error:
	clc
	rts

;-----------------------------------------------------------------------------
; fat32_chdir
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_chdir:
	stz fat32_errno

	; Check if context is free
	lda cur_context + context::flags
	bne @error

	; Find directory
	jsr find_dir
	bcs @1
	lda #ERRNO_FILE_NOT_FOUND
	jmp set_errno

@1:
	; Set as current directory
	set32 fat32_cwd_cluster, fat32_dirent + dirent::cluster

	sec
	rts

@error:	clc
	rts

;-----------------------------------------------------------------------------
; fat32_rename
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_rename:
	stz fat32_errno

	; Check if context is free
	lda cur_context + context::flags
	beq @0
@error:	clc
	rts

@0:
	; Save first argument
	set16 tmp_buf, fat32_ptr

	; Make sure target name doesn't exist
	set16 fat32_ptr, fat32_ptr2
	jsr find_dirent
	bcc @1
	; Error, file exists
	lda #ERRNO_FILE_EXISTS
	jmp set_errno

@1:
	; Convert target filename into directory entry format
	jsr convert_filename
	bcc @error

	; Find file to rename
	set16 fat32_ptr, tmp_buf
	jsr find_dirent
	bcs @3
	lda #ERRNO_FILE_NOT_FOUND
	jmp set_errno

@3:
	; Copy new filename into sector buffer
	set16 fat32_bufptr, cur_context + context::dirent_bufptr
	ldy #0
@2:	lda filename_buf, y
	sta (fat32_bufptr), y
	iny
	cpy #11
	bne @2

	; Write sector buffer to disk
	jmp save_sector_buffer

;-----------------------------------------------------------------------------
; fat32_set_attribute
;
; A: File attribute
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_set_attribute:
	stz fat32_errno

	and #$ff-$10 ; clear directory bit
	sta tmp_buf

	; Check if context is free
	lda cur_context + context::flags
	beq @0
@error:	clc
	rts

@0:
	; Find file
	jsr find_dirent
	bcs @3
	lda #ERRNO_FILE_NOT_FOUND
	jmp set_errno

@3:
	; Set attribute
	set16 fat32_bufptr, cur_context + context::dirent_bufptr
	ldy #11
	lda (fat32_bufptr), y
	and #$10 ; preserve directory bit
	ora tmp_buf
	sta (fat32_bufptr), y

	; Write sector buffer to disk
	jmp save_sector_buffer

;-----------------------------------------------------------------------------
; fat32_delete
;-----------------------------------------------------------------------------
fat32_delete:
	stz fat32_errno

	; Check if context is free
	lda cur_context + context::flags
	bne @error

	jsr delete_file
	bcs @1
	lda #ERRNO_FILE_NOT_FOUND
	jmp set_errno

@error:	clc
@1:	rts

;-----------------------------------------------------------------------------
; fat32_rmdir
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_rmdir:
	stz fat32_errno

	; Check if context is free
	lda cur_context + context::flags
	beq @1
@error:	clc
	rts
@1:
	; Find directory
	jsr find_dir
	bcs @2
	lda #ERRNO_FILE_NOT_FOUND
	jmp set_errno

@2:
	; Open directory
	set32 cur_context + context::cluster, fat32_dirent + dirent::cluster
	jsr open_cluster
	bcc @error

	; Make sure directory is empty
@next:	jsr fat32_read_dirent
	bcs @3
	lda fat32_errno
	beq @done
	clc
	rts

@3:	lda fat32_dirent + dirent::name
	cmp #'.'	; Allow for dot-entries
	beq @next
	lda #ERRNO_DIR_NOT_EMPTY
	jmp set_errno

@done:
	; Find directory
	jsr find_dir
	bcc @error

	; Mark file as deleted
	set16 fat32_bufptr, cur_context + context::dirent_bufptr
	lda #$E5
	sta (fat32_bufptr)

	; Write sector buffer to disk
	jsr save_sector_buffer
	bcc @error

	; Unlink cluster chain
	set32 cur_context + context::cluster, fat32_dirent + dirent::cluster
	jmp unlink_cluster_chain

;-----------------------------------------------------------------------------
; fat32_open
;
; Open file specified in string pointed to by fat32_ptr
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_open:
	stz fat32_errno

	; Check if context is free
	lda cur_context + context::flags
	bne @error

	; Find file
	jsr find_file
	bcs @1
	lda #ERRNO_FILE_NOT_FOUND
	jmp set_errno

@1:
	; Open file
	set32_val cur_context + context::file_offset, 0
	set32 cur_context + context::file_size, fat32_dirent + dirent::size
	set32 cur_context + context::cluster, fat32_dirent + dirent::cluster
	jsr open_cluster
	bcc @error

	; Set context as in-use
	lda #FLAG_IN_USE
	sta cur_context + context::flags

	; Success
	sec
	rts

@error:	clc
	rts

;-----------------------------------------------------------------------------
; create_dir_entry
;
; A: File attribute
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
create_dir_entry:
	sta tmp_buf

	; Convert file name
	jsr convert_filename
	bcc @error

	; Find free directory entry
	set32 cur_context + context::cluster, tmp_dir_cluster
	jsr open_cluster
	bcc @error

@next_entry:
	; Load next sector if at end of buffer (allocate and clear new cluster if needed)
	cmp16_val_ne fat32_bufptr, sector_buffer_end, @1
	lda #3
	jsr next_sector
	bcs @1
@error:	clc
	rts
@1:
	; Is this entry free?
	lda (fat32_bufptr)
	beq @free_entry
	cmp #$E5
	beq @free_entry

	; Increment buffer pointer to next entry
	add16_val fat32_bufptr, fat32_bufptr, 32
	bra @next_entry

	; Free directory entry found
@free_entry:
	; Copy filename in new entry
	ldy #0
@2:	lda filename_buf, y
	sta (fat32_bufptr), y
	iny
	cpy #11
	bne @2

	; File attribute
	lda tmp_buf
	sta (fat32_bufptr), y
	iny

	; Zero fill rest of entry
	lda #0
@3:	sta (fat32_bufptr), y
	iny
	cpy #32
	bne @3

	; Save lba + fat32_bufptr
	set32 cur_context + context::dirent_lba,    cur_context + context::lba
	set16 cur_context + context::dirent_bufptr, fat32_bufptr

	; Write sector buffer to disk
	jsr save_sector_buffer
	bcc @error

	; Set context as in-use
	lda #FLAG_IN_USE
	sta cur_context + context::flags

	; Set up fat32_bufptr to trigger cluster allocation at first write
	set16_val fat32_bufptr, sector_buffer_end

	sec
	rts

;-----------------------------------------------------------------------------
; fat32_create
;
; Create file. Delete it if it already exists.
;-----------------------------------------------------------------------------
fat32_create:
	stz fat32_errno

	; Check if context is free
	lda cur_context + context::flags
	beq @1
@error:	clc
	rts
@1:
	; Check if directory entry already exists?
	jsr find_dirent
	bcs @exists
	lda fat32_errno
	bne @error
	bra @ok

@exists:
	; Delete file first if it exists
	jsr delete_file
	bcc @error

@ok:	; Create directory entry
	lda #0
	jmp create_dir_entry

;-----------------------------------------------------------------------------
; fat32_mkdir
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_mkdir:
	stz fat32_errno

	; Check if context is free
	lda cur_context + context::flags
	bne @error

	; Check if directory doesn't exist yet
	jsr find_dirent
	bcc @0
	lda #ERRNO_FILE_EXISTS
	jsr set_errno
	bra @error

@0:
	; Create directory entry
	lda #$10
	jsr create_dir_entry
	bcc @error

	; Allocate the cluster
	jsr allocate_first_cluster
	bcc @error
	jsr clear_cluster
	bcc @error
	jsr open_cluster
	bcs @1
@error:	jmp error_clear_context

@1:
	; Create '.' and '..' entries
	ldy #0
	lda #' '
@2:	sta sector_buffer + 0, y
	sta sector_buffer + 32, y
	iny
	cpy #11
	bne @2

	lda #'.'	; Name
	sta sector_buffer + 0
	sta sector_buffer + 32 + 0
	sta sector_buffer + 32 + 1

	lda #$10	; Directory attribute
	sta sector_buffer + 11
	sta sector_buffer + 32 + 11

	lda free_cluster + 0
	sta sector_buffer + 26
	lda free_cluster + 1
	sta sector_buffer + 27
	lda free_cluster + 2
	sta sector_buffer + 20
	lda free_cluster + 3
	sta sector_buffer + 21

	lda tmp_dir_cluster + 0
	sta sector_buffer + 32 + 26
	lda tmp_dir_cluster + 1
	sta sector_buffer + 32 + 27
	lda tmp_dir_cluster + 2
	sta sector_buffer + 32 + 20
	lda tmp_dir_cluster + 3
	sta sector_buffer + 32 + 21

	; Set sector as dirty
	lda cur_context + context::flags
	ora #FLAG_DIRTY
	sta cur_context + context::flags
	
	jmp fat32_close

;-----------------------------------------------------------------------------
; fat32_close
;
; Close current file
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_close:
	stz fat32_errno

	lda cur_context + context::flags
	beq @done

	; Write current sector if dirty
	jsr sync_sector_buffer
	bcc error_clear_context

	; Update directory entry with new size if needed
	lda cur_context + context::flags
	bit #FLAG_DIRENT
	beq @done
	and #(FLAG_DIRENT ^ $FF)	; Clear bit
	sta cur_context + context::flags

	; Load sector of directory entry
	set32 cur_context + context::lba, cur_context + context::dirent_lba
	jsr load_sector_buffer
	bcc error_clear_context

	; Write size to directory entry
	set16 fat32_bufptr, cur_context + context::dirent_bufptr
	ldy #28
	lda cur_context + context::file_size + 0
	sta (fat32_bufptr), y
	iny
	lda cur_context + context::file_size + 1
	sta (fat32_bufptr), y
	iny
	lda cur_context + context::file_size + 2
	sta (fat32_bufptr), y
	iny
	lda cur_context + context::file_size + 3
	sta (fat32_bufptr), y

	; Write directory sector
	jsr save_sector_buffer
	bcc error_clear_context
@done:
	clear_bytes cur_context, .sizeof(context)

	sec
	rts

;-----------------------------------------------------------------------------
; error_clear_context
;
; Call this instead of fat32_close if there has been an error to avoid cached
; writes and possible further inconsistencies.
;-----------------------------------------------------------------------------
error_clear_context:
	clear_bytes cur_context, .sizeof(context)
	clc
	rts

;-----------------------------------------------------------------------------
; fat32_read_byte
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_read_byte:
	stz fat32_errno

	; Bytes remaining?
	cmp32_ne cur_context + context::file_offset, cur_context + context::file_size, @1
@error:	clc
	rts
@1:
	; At end of buffer?
	cmp16_val_ne fat32_bufptr, sector_buffer_end, @2
	lda #0
	jsr next_sector
	bcc @error
@2:
	; Decrement bytes remaining
	inc32 cur_context + context::file_offset

	; Get byte from buffer
	lda (fat32_bufptr)
	inc16 fat32_bufptr

	sec	; Indicate success
	rts

;-----------------------------------------------------------------------------
; fat32_read
;
; fat32_ptr          : pointer to store read data
; fat32_size (16-bit): size of data to read
;
; On return fat32_size reflects the number of bytes actually read
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_read:
	stz fat32_errno

	set16 fat32_ptr2, fat32_size

@again:	; Calculate number of bytes remaining in file
	sub32 tmp_buf, cur_context + context::file_size, cur_context + context::file_offset
	lda tmp_buf + 0
	ora tmp_buf + 1
	ora tmp_buf + 2
	ora tmp_buf + 3
	bne @1
	clc		; End of file
	jmp @done
@1:
	; Calculate number of bytes remaining in buffer
	sec
	lda #<sector_buffer_end
	sbc fat32_bufptr + 0
	sta bytecnt + 0
	lda #>sector_buffer_end
	sbc fat32_bufptr + 1
	sta bytecnt + 1
	ora bytecnt + 0	; Check if 0
	bne @nonzero

	; At end of buffer, read next sector
	lda #0
	jsr next_sector
	bcs @2
	; No sectors left (this shouldn't happen with a correct file size)
	lda #ERRNO_FS_INCONSISTENT
	jsr set_errno
	sec
	jmp @done
@2:	lda #2
	sta bytecnt + 1

@nonzero:
	; if (fat32_size - bytecnt < 0) bytecnt = fat32_size
	sec
	lda fat32_size + 0
	sbc bytecnt + 0
	lda fat32_size + 1
	sbc bytecnt + 1
	bcs @3
	set16 bytecnt, fat32_size
@3:
	; if (bytecnt > 256) bytecnt = 256
	lda bytecnt + 1
	beq @4		; <256?
	stz bytecnt + 0	; 256 bytes
	lda #1
	sta bytecnt + 1
@4:
	; if (tmp_buf - bytecnt < 0) bytecnt = tmp_buf
	sec	
	lda tmp_buf + 0
	sbc bytecnt + 0
	lda tmp_buf + 1
	sbc bytecnt + 1
	lda tmp_buf + 2
	sbc #0
	lda tmp_buf + 3
	sbc #0
	bpl @5
	set16 bytecnt, tmp_buf
@5:
	; Copy bytecnt bytes from buffer
	ldy #0
@6:	lda (fat32_bufptr), y
	sta (fat32_ptr), y
	iny
	cpy bytecnt
	bne @6

	; fat32_ptr += bytecnt, fat32_bufptr += bytecnt, fat32_size -= bytecnt, file_offset += bytecnt
	add16 fat32_ptr, fat32_ptr, bytecnt
	add16 fat32_bufptr, fat32_bufptr, bytecnt
	sub16 fat32_size, fat32_size, bytecnt
	add32_16 cur_context + context::file_offset, cur_context + context::file_offset, bytecnt

	; Check if done
	lda fat32_size + 0
	ora fat32_size + 1
	beq @7
	jmp @again		; Not done yet
@7:
	sec	; Indicate success

@done:	; Calculate number of bytes read
	php
	sub16 fat32_size, fat32_ptr2, fat32_size
	plp

	rts

;-----------------------------------------------------------------------------
; allocate_first_cluster
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
allocate_first_cluster:
	jsr allocate_cluster
	bcs @1
@error:	rts
@1:
	; Load sector of directory entry
	set32 cur_context + context::lba, cur_context + context::dirent_lba
	jsr load_sector_buffer
	bcc @error
	set16 fat32_bufptr, cur_context + context::dirent_bufptr

	; Write cluster number to directory entry
	ldy #26
	lda free_cluster + 0
	sta (fat32_bufptr), y
	iny
	lda free_cluster + 1
	sta (fat32_bufptr), y
	ldy #20
	lda free_cluster + 2
	sta (fat32_bufptr), y
	iny
	lda free_cluster + 3
	sta (fat32_bufptr), y

	; Write directory sector
	jsr save_sector_buffer
	bcc @error

	; Set allocated cluster as current
	set32 cur_context + context::cluster, free_cluster
	sec
	rts

;-----------------------------------------------------------------------------
; write__end_of_buffer
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
write__end_of_buffer:
	; Is this the first cluster?
	lda cur_context + context::file_size + 0
	ora cur_context + context::file_size + 1
	ora cur_context + context::file_size + 2
	ora cur_context + context::file_size + 3
	beq @first_cluster

	; Go to next sector (allocate cluster if needed)
	lda #1
	jmp next_sector

@first_cluster:
	jsr allocate_first_cluster
	bcs @1
	rts
@1:
	; Load in cluster
	jmp open_cluster

;-----------------------------------------------------------------------------
; fat32_write_byte
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_write_byte:
	stz fat32_errno

	; At end of buffer? (preserve A)
	ldx fat32_bufptr + 0
	cpx #<sector_buffer_end
	bne @write_byte
	ldx fat32_bufptr + 1
	cpx #>sector_buffer_end
	bne @write_byte

	; Handle end of buffer condition
	pha
	jsr write__end_of_buffer
	pla
	bcs @write_byte
	rts

@write_byte:
	; Write byte
	sta (fat32_bufptr)
	inc16 fat32_bufptr

	; Set sector as dirty, dirent needs update
	lda cur_context + context::flags
	ora #(FLAG_DIRTY | FLAG_DIRENT)
	sta cur_context + context::flags

	inc32 cur_context + context::file_offset

	; if (file_size - file_offset < 0) file_size = file_offset
	sec
	lda cur_context + context::file_size + 0
	sbc cur_context + context::file_offset + 0
	lda cur_context + context::file_size + 1
	sbc cur_context + context::file_offset + 1
	lda cur_context + context::file_size + 2
	sbc cur_context + context::file_offset + 2
	lda cur_context + context::file_size + 3
	sbc cur_context + context::file_offset + 3
	bpl @1
	set32 cur_context + context::file_size, cur_context + context::file_offset
@1:
	sec	; Indicate success
	rts

;-----------------------------------------------------------------------------
; fat32_write
;
; fat32_ptr          : pointer to data to write
; fat32_size (16-bit): size of data to write
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_write:
	stz fat32_errno

	; Calculate number of bytes remaining in buffer
	sec
	lda #<sector_buffer_end
	sbc fat32_bufptr + 0
	sta bytecnt + 0
	lda #>sector_buffer_end
	sbc fat32_bufptr + 1
	sta bytecnt + 1
	ora bytecnt + 0	; Check if 0
	bne @nonzero

	; Handle end of buffer condition
	jsr write__end_of_buffer
	bcs @1
	rts
@1:	lda #2
	sta bytecnt + 1

@nonzero:
	; if (fat32_size - bytecnt < 0) bytecnt = fat32_size
	sec
	lda fat32_size + 0
	sbc bytecnt + 0
	lda fat32_size + 1
	sbc bytecnt + 1
	bcs @2
	set16 bytecnt, fat32_size
@2:
	; if (bytecnt > 256) bytecnt = 256
	lda bytecnt + 1
	beq @3		; <256?
	stz bytecnt + 0	; 256 bytes
	lda #1
	sta bytecnt + 1
@3:
	; Copy bytecnt bytes into buffer
	ldy #0
@4:	lda (fat32_ptr), y
	sta (fat32_bufptr), y
	iny
	cpy bytecnt
	bne @4

	; fat32_ptr += bytecnt, fat32_bufptr += bytecnt, fat32_size -= bytecnt, file_offset += bytecnt
	add16 fat32_ptr, fat32_ptr, bytecnt
	add16 fat32_bufptr, fat32_bufptr, bytecnt
	sub16 fat32_size, fat32_size, bytecnt
	add32_16 cur_context + context::file_offset, cur_context + context::file_offset, bytecnt

	; if (file_size - file_offset < 0) file_size = file_offset
	sec
	lda cur_context + context::file_size + 0
	sbc cur_context + context::file_offset + 0
	lda cur_context + context::file_size + 1
	sbc cur_context + context::file_offset + 1
	lda cur_context + context::file_size + 2
	sbc cur_context + context::file_offset + 2
	lda cur_context + context::file_size + 3
	sbc cur_context + context::file_offset + 3
	bpl @5
	set32 cur_context + context::file_size, cur_context + context::file_offset
@5:
	; Set sector as dirty, dirent needs update
	lda cur_context + context::flags
	ora #(FLAG_DIRTY | FLAG_DIRENT)
	sta cur_context + context::flags

	; Check if done
	lda fat32_size + 0
	ora fat32_size + 1
	beq @6
	jmp fat32_write		; Not done yet
@6:
	sec	; Indicate success
	rts

;-----------------------------------------------------------------------------
; fat32_get_free_space
;-----------------------------------------------------------------------------
fat32_get_free_space:
	set32 fat32_size, free_clusters

	lda cluster_shift
	cmp #0	; 512B cluster
	beq @512b

	sec
	sbc #1
	tax
	cpx #0
	beq @done
@1:	shl32 fat32_size
	dex
	bne @1

@done:	sec
	rts

@512b:	shr32 fat32_size
	bra @done

;-----------------------------------------------------------------------------
; fat32_next_sector
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_next_sector:
	stz fat32_errno

	lda #0
	jsr next_sector
	bcs @1
	rts
@1:
	add32 cur_context + context::file_offset, cur_context + context::file_offset, 512
	sec
	rts

;-----------------------------------------------------------------------------
; fat32_get_offset
;-----------------------------------------------------------------------------
fat32_get_offset:
	set32 fat32_size, cur_context + context::file_offset
	sec
	rts
