;----------------------------------------------------------------------
; CMDR-DOS Command Implementations
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "functions.inc"
.include "fat32/fat32.inc"
.include "fat32/regs.inc"
.include "banks.inc"

; main.s
.import dos_init

; parser.s
.import medium, medium1, unix_path, unix_path2, create_unix_path, append_unix_path_b
.import r2s, r2e

; main.s
.export cur_medium
.import convert_errno_status, dos_unit, disk_changed

; cmdch.s
.import status_clear, status_put

; match.s
.import skip_mask

; file.s
.import file_set_position

.export alloc_context, alloc_context2, free_context

.export create_fat32_path_only_dir, create_fat32_path_only_name
.import create_unix_path_only_dir, create_unix_path_only_name, append_unix_path_only_name

.import buffer

.macro FAT32_CONTEXT_START
	jsr alloc_context
	bcs @alloc_ok

	jmp convert_errno_status

@alloc_ok:
	pha
	jsr fat32_set_context
.endmacro

.macro FAT32_CONTEXT_END
	pla
	jsr free_context
.endmacro

.bss

cur_medium:
	.byte 0
tmp0:
	.byte 0
context_dst:
	.byte 0

.code

;---------------------------------------------------------------
alloc_context:
	lda medium
	bne :+
	lda cur_medium
:	dec
alloc_context2:
	jsr fat32_alloc_context
	php
	pha
	jsr update_activity
	pla
	plp
	rts

free_context:
	jsr fat32_free_context
	php
	jsr update_activity
	plp
	rts

;---------------------------------------------------------------
; update_activity
;
; Set/clear active flag based on whether any contexts are open.
;---------------------------------------------------------------
update_activity:
	jsr fat32_get_num_contexts
	tax
	lda cbdos_flags
	and #$ff-$10 ; clear active flag
	cpx #0
	beq :+
	ora #$10 ; set active flag
:	sta cbdos_flags
	rts

;---------------------------------------------------------------
create_fat32_path:
	lda #<unix_path
	sta fat32_ptr + 0
	lda #>unix_path
	sta fat32_ptr + 1
	jmp create_unix_path

create_fat32_path_r0r1:
	lda #<unix_path
	sta fat32_ptr + 0
	lda #>unix_path
	sta fat32_ptr + 1
	jsr create_unix_path_only_dir
	tya
	clc
	adc #<unix_path
	sta fat32_ptr2 + 0
	lda #>unix_path
	adc #0
	sta fat32_ptr2 + 1
	jmp append_unix_path_only_name

create_fat32_path_x2:
	jsr create_fat32_path
	tya
	clc
	adc #<unix_path
	sta fat32_ptr2 + 0
	lda #>unix_path
	adc #0
	sta fat32_ptr2 + 1
	jmp append_unix_path_b

;---------------------------------------------------------------
create_fat32_path_only_dir:
	lda #<unix_path
	sta fat32_ptr + 0
	lda #>unix_path
	sta fat32_ptr + 1
	jsr create_unix_path_only_dir
	lda unix_path
	bne @1
	stz fat32_ptr + 0
	stz fat32_ptr + 1
@1:	rts

;---------------------------------------------------------------
create_fat32_path_only_name:
	lda #<unix_path
	sta fat32_ptr + 0
	lda #>unix_path
	sta fat32_ptr + 1
	jsr create_unix_path_only_name
	lda unix_path
	bne @1
	stz fat32_ptr + 0
	stz fat32_ptr + 1
@1:	rts

;---------------------------------------------------------------
; for all these implementations:
;
; Out:  a  status ($ff = don't set status)
;       c  (unused)
;---------------------------------------------------------------

;---------------------------------------------------------------
; initialize
;
; This is the "I" command, which is a hint that the physical
; media was changed, and the new media should be mounted.
;
; In:   medium  medium
;---------------------------------------------------------------
initialize:
	FAT32_CONTEXT_START
	; just allocating the context with the medium
	; will trigger a mount
	FAT32_CONTEXT_END
	lda #0
	rts

;---------------------------------------------------------------
; validate
;
; This is the "V" command, which should do a filesystem check
; and repair.
;
; In:   medium  medium
;---------------------------------------------------------------
validate:
	; TODO: fsck
	lda #$31
	rts

;---------------------------------------------------------------
; new
;
; This is the "N" command, which initializes a filesystem.
; FAT32 filesystems are large, so formatting is a rarely used
; and very dangerous function. Therefore, the standard syntax
; ("NAME" or "NAME,ID") should not initialize the filesystem
; just yet. CMD devices add an optional ",FORMAT" argument,
; which is madatory in this implementation and has to say
; "FAT32", with an optional CHR$(sectors_per_cluster) appended.
;
; In:   medium  medium
;       r0      name
;       r1      id
;       r2      format
;---------------------------------------------------------------
new:
@sectors_per_cluster  = tmp0
	jsr create_fat32_path_r0r1

	; for safety, formatting current partition is not allowed
	ldx medium
	bne @1
	lda #$77 ; selected partition illegal
	rts
@1:

	; Check for "FAT32" format
	ldx r2s
	ldy #0
@2:	cpy #txt_fat32_len
	beq @ok
	cpx r2e
	beq @error_format
	lda buffer,x
	cmp txt_fat32,y
	bne @error_format
	inx
	iny
	bra @2
@ok:

	lda #0 ; default number of sectors per cluster
	cpx r2e
	beq @3
	lda buffer,x
@3:	sta @sectors_per_cluster

	lda #$ff
	jsr alloc_context2
	bcc @error1
	pha

	lda #<txt_oemname
	sta fat32_bufptr
	lda #>txt_oemname
	sta fat32_bufptr + 1

	lda medium
	dec
	ldx @sectors_per_cluster
	jsr fat32_mkfs
	pla
	bcc @error2
	jsr free_context
	lda #0
	rts

@error2:
	jsr free_context
@error1:
	lda fat32_errno
	cmp #ERRNO_FS_INCONSISTENT
	beq @error_format
	jmp convert_errno_status

@error_format:
	lda #$75 ; format error
	rts

txt_fat32:
	.byte "FAT32"
txt_fat32_len = * - txt_fat32
txt_oemname:
	.byte "CMDR-DOS", 0

;---------------------------------------------------------------
; scratch
;
; In:   medium/r0/r1  medium/path/name
; Out:  x             number of files scratched
;---------------------------------------------------------------
scratch:
@scratch_counter  = tmp0
	stz @scratch_counter

	FAT32_CONTEXT_START
	jsr create_fat32_path
@loop:
	lda #$11
	sta skip_mask
	jsr fat32_delete
	stz skip_mask
	bcc :+
	inc @scratch_counter
	bra @loop

:	lda fat32_errno
	cmp #ERRNO_FILE_NOT_FOUND ; no more files
	beq @end

	FAT32_CONTEXT_END
	jsr convert_errno_status
	ldx @scratch_counter
	rts

@end:
	FAT32_CONTEXT_END
	ldx @scratch_counter
	lda #0
	rts

;---------------------------------------------------------------
; make_directory
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
make_directory:
	FAT32_CONTEXT_START
	jsr create_fat32_path
	jsr fat32_mkdir
	bcc convert_status_end_context
	FAT32_CONTEXT_END
	lda #0
	rts

convert_status_end_context:
	FAT32_CONTEXT_END
	jmp convert_errno_status

;---------------------------------------------------------------
;
; remove_directory
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
remove_directory:
	FAT32_CONTEXT_START
	jsr create_fat32_path
	jsr fat32_rmdir
	bcc @error
	FAT32_CONTEXT_END
	lda #1 ; files scratched
	tax
	rts
@error:
	FAT32_CONTEXT_END
	lda fat32_errno
	cmp #ERRNO_FILE_NOT_FOUND
	beq @not_found
	cmp #ERRNO_DIR_NOT_EMPTY
	beq @not_found
	jmp convert_errno_status

@not_found:
	lda #1
	ldx #0
	rts

;---------------------------------------------------------------
; change_directory
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
change_directory:
	FAT32_CONTEXT_START
	jsr create_fat32_path

	lda unix_path
	cmp #'_'
	bne @regular_cd
	lda unix_path + 1
	bne @regular_cd

	; "cd .."
	lda #'.'
	sta unix_path
	sta unix_path + 1
	stz unix_path + 2

@regular_cd:
	jsr fat32_chdir
	bcc convert_status_end_context
	FAT32_CONTEXT_END
	lda #0
	rts

;---------------------------------------------------------------
; change_partition
;
; In:   a  partition
;---------------------------------------------------------------
change_partition:
	sta medium
	cmp #0
	beq @ill_part
	dec
	jsr alloc_context2
	bcc @ill_part
	ldx medium
	stx cur_medium
	jsr free_context
	ldx cur_medium
	lda #$02
	rts

@ill_part:
	ldx medium
	lda #$77 ; XXX distinguish between nonexistant and unformatted
	rts

;---------------------------------------------------------------
; user
;
; In:   a  vector number
;---------------------------------------------------------------
user:
	cmp #0
	beq @user_0
	cmp #1
	beq @user_1
	cmp #2
	beq @user_2
	cmp #9
	beq @user_9
	cmp #10
	beq @user_10

	; U3-U8; execute code
	lda #$31
	rts

; U0 - init user vectors
@user_0:
	lda #0
	rts

; U1/UA - read block
@user_1:
	; TODO: read block
	lda #$31
	rts

; U2/UB - write block
@user_2:
	; TODO: write block
	lda #$31
	rts

; U9/UI - warm RESET
@user_9:
	lda #$73
	rts

; U:/UJ - cold RESET
@user_10:
	jsr dos_init
	lda #$73
	rts

;---------------------------------------------------------------
; In:   medium/r0/r1   old medium/path/name
;       medium1/r2/r3  new medium/path/name
;---------------------------------------------------------------
rename:
	lda medium
	cmp medium1
	bne @error
	FAT32_CONTEXT_START
	jsr create_fat32_path_x2
	jsr fat32_rename
	bcs :+
	jmp convert_status_end_context
:	FAT32_CONTEXT_END
	lda #0
	rts
@error:
	lda #$31 ; SYNTAX ERROR
	rts

;---------------------------------------------------------------
; rename_header
;
; This is the "R-H" command, which should set the name of
;   * the filesystem (i.e. FAT volume label), if no path
;     is given.
;   * the "header" of a subdirectory, if a path is given.
;     FAT doesn't have any such concept, so this part must
;     remain unsupported.
;
; In:   medium  medium
;       r0      path
;               empty:     rename filesystem
;               not empty: rename subdirectory "header"
;       r1      new name
;---------------------------------------------------------------
rename_header:
	jsr create_unix_path_only_dir
	lda unix_path
	bne @rename_subdir_header

	FAT32_CONTEXT_START

	jsr create_fat32_path
	jsr fat32_set_vollabel
	bcs :+
	jmp convert_status_end_context
:	FAT32_CONTEXT_END
	lda #0
	rts

@rename_subdir_header:
	; unsupported; FAT can't do this
	lda #$39 ; illegal path
	rts

;---------------------------------------------------------------
; rename_partition
;
; This is the "R-P" command, which should change the name of
; a partition as stored in the partition table.
; MBR partition tables don't support names, so this is
; unsupported.
;
; In:   r0  new name
;       r1  old name
;---------------------------------------------------------------
rename_partition:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; change_unit
;
; In:   a  unit number (already checked for validity)
;---------------------------------------------------------------
change_unit:
	sta dos_unit
	lda #0
	rts

;---------------------------------------------------------------
; copy_start
;
; Open destination file for writing.
;
; In:   medium/r0/r1   destination
;---------------------------------------------------------------
copy_start:
	jsr alloc_context
	bcc @error_70
	sta context_dst
	jsr fat32_set_context

	jsr create_fat32_path

	clc ; don't overwrite
	jsr fat32_create
	bcc @error_errno

	lda #0
	rts

@error_70:
	lda #$70
	rts

@error_errno:
	lda context_dst
	jsr free_context
	jmp convert_errno_status

@copy_err2:
	jsr convert_errno_status
@copy_err:
	pha
	lda context_dst
	jsr free_context
	pla
	rts

;---------------------------------------------------------------
; copy_do
;
; Append one file to destination file.
;---------------------------------------------------------------
copy_do:
@context_src = tmp0
	jsr alloc_context
	bcc @error_70
	sta @context_src
	jsr fat32_set_context
	bcc @error_errno

	jsr create_fat32_path
	jsr fat32_open
	bcc @error_errno

@cloop:
	; read
	lda @context_src
	jsr fat32_set_context
	bcc @error_errno
	lda #<unix_path
	sta fat32_ptr
	lda #>unix_path
	sta fat32_ptr + 1
	stz fat32_size
	lda #1
	sta fat32_size + 1
	jsr fat32_read
	bcs :+
	lda fat32_errno
	bne @error_errno

:	lda fat32_size
	ora fat32_size + 1
	beq @done

	; write
	lda context_dst
	jsr fat32_set_context
	bcc @error_errno
	lda #<unix_path
	sta fat32_ptr
	lda #>unix_path
	sta fat32_ptr + 1
	jsr fat32_write
	bcc @error_errno

	bra @cloop

@done:
	; close source
	lda @context_src
	jsr fat32_set_context
	bcc @error_errno
	jsr fat32_close
	bcc @error_errno
	lda @context_src
	jsr free_context

	lda #0
	rts

@error_70:
	lda #$70
	rts

@error_errno:
	jsr convert_errno_status
	pha
	lda @context_src
	jsr fat32_set_context
	jsr fat32_close
	lda @context_src
	jsr free_context
	pla
	rts

;---------------------------------------------------------------
; copy_end
;
; Close destination file.
;---------------------------------------------------------------
copy_end:
	lda context_dst
	jsr fat32_set_context
	bcs @1

	jsr convert_errno_status
	pha
	jsr fat32_close
	lda context_dst
	jsr free_context
	pla
	rts

@1:	jsr fat32_close
	php
	lda context_dst
	jsr free_context
	plp
	bcs @2

	jmp convert_errno_status

@2:	lda #0
	rts

;---------------------------------------------------------------
; copy_all
;
; This is the variant of the "C" command with two media numbers
; as arguments, which should perform a file copy of all files
; between from one media to another. It is only supported on
; Commodore multi-drive units, not by CMD devices, so this
; implementation doesn't support it either.
;
; In:   x   destination medium
;       y   source medium
;---------------------------------------------------------------
copy_all:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; duplicate
;
; This is the "D" command, which should perform a block-by-block
; copy from one drive to another.It is only supported on
; Commodore multi-drive units, not by CMD devices, since it
; makes little sense on devices with differently sized
; partitions, so this implementation doesn't support it either.
;
; In:   x   destination medium
;       y   source medium
;---------------------------------------------------------------
duplicate:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; file_lock
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_lock:
	lda #1
file_lock_unlock:
	sta tmp0
	FAT32_CONTEXT_START
	jsr create_fat32_path
	lda tmp0
	jsr fat32_set_attribute
	bcs :+
	jmp convert_status_end_context
:	FAT32_CONTEXT_END
	lda #0
	rts

;---------------------------------------------------------------
; file_unlock
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_unlock:
	lda #0
	bra file_lock_unlock

;---------------------------------------------------------------
; file_lock_toggle
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_lock_toggle:
	FAT32_CONTEXT_START
	jsr create_fat32_path_only_dir
	jsr fat32_open_dir
	bcc @error_errno

	jsr create_fat32_path_only_name
	jsr fat32_read_dirent_filtered
	php
	jsr fat32_close ; can't fail
	plp
	bcs :+
	lda fat32_errno
	bne @error_errno
	bra @error_file_not_found
:
	jsr create_fat32_path
	lda fat32_dirent + dirent::attributes
	eor #1
	jsr fat32_set_attribute
	bcs :+
	jmp convert_status_end_context

:	FAT32_CONTEXT_END
	lda #0
	rts

@error_file_not_found:
	FAT32_CONTEXT_END
	lda #$62 ; file not found
	rts

@error_errno:
	jmp convert_status_end_context

;---------------------------------------------------------------
; file_restore
;
; This is the "F-R" command, which should perform an undelete.
; It is only supported by the C65 drive.
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_restore:
	; TODO: undelete
	; FAT32 keeps the directory entry and the FAT links,
	; but overwrites the first character. The user provides
	; the full filename to this function though.
	lda #$31
	rts

;---------------------------------------------------------------
; write_protect
;
; In:   a    =0: write protect off
;            =1: write protect on
;---------------------------------------------------------------
write_protect:
	sta fat32_readonly
	lda #0
	rts

;---------------------------------------------------------------
; get_partition
;
; In:   a    partition number (0 = "system"; 255 = current)
;---------------------------------------------------------------
get_partition:
	sta medium

	jsr status_clear

	lda medium
	cmp #255
	bne @1
	lda cur_medium
@1:	sta medium
	lda #$ff
	jsr alloc_context2
	bcs @ok
	lda #$ff
	pha
	bra @error

@ok: 	pha
	lda medium
	dec
	jsr fat32_get_ptable_entry
	bcs @2
@error:
	; In the error case (read error or illegal partition),
	; we are supposed to return an empty structure, with
	; just the medium populated. Otherwise, the user would
	; have a hard time distingushing a valid result from
	; a status channel string.
	lda #0
	jsr status_put
	jsr status_put
	lda medium
	jsr status_put
	ldy #27
	lda #0
@6:	jsr status_put
	dey
	bne @6
	jmp @done

@2:
	lda fat32_dirent + dirent::attributes
	beq @error

	; The CMD specification uses 3 bytes for the
	; start LBA and the size, allowing for disks
	; up to 8 GB. We are extending this to 4 bytes,
	; for disks up to 2 TB.
	;
	; For this, the extra 8 bits are stored at offsets:
	; * 18 - start LBA: this used to be last (16th)
	;        character of the partition name
	; * 25 - size: this used to be reserved

	ldx #0
	lda fat32_dirent + dirent::attributes
	jsr status_put;           0 -     partition type (same as MBR type)
	lda #$00 ;                1 -     reserved (0)
	jsr status_put
	lda medium ;              2 -     partition number
	jsr status_put

	;                         3 - 17  partition name
	ldy #0
@3:	lda fat32_dirent + dirent::name, y
	beq @4
	jsr status_put
	iny
	cpy #15
	bne @3

@4:	cpy #15
	beq @5
	lda #$a0 ; terminator/padding
	jsr status_put
	iny
	bra @4

@5:	lda fat32_dirent + dirent::start+3
	jsr status_put;          18 - 21  partition start LBA (big endian)
	lda fat32_dirent + dirent::start+2
	jsr status_put
	lda fat32_dirent + dirent::start+1
	jsr status_put
	lda fat32_dirent + dirent::start+0
	jsr status_put
	lda #$00 ;               22 - 25  reserved (0)
	jsr status_put
	jsr status_put
	jsr status_put
	jsr status_put
	lda fat32_dirent + dirent::size+3
	jsr status_put;          26 - 29  partition size (in 512 byte blocks)
	lda fat32_dirent + dirent::size+2
	jsr status_put
	lda fat32_dirent + dirent::size+1
	jsr status_put
	lda fat32_dirent + dirent::size+0
	jsr status_put

@done:
	pla
	bmi @7 ; no context allocated
	jsr free_context
@7:	lda #$ff ; don't set status
	rts

;---------------------------------------------------------------
; get_diskchange
;
; Return a single byte indicating whether a disk change has
; happened (=0: no, 1-255: yes), followed by a CR. [CMD FD docs]
; * The CMD FD has a bug where the first byte is followed by
;   lots of garbage.
; * The CMD HD does not support this command.
; * We implement the spec here.
;---------------------------------------------------------------
get_diskchange:
	jsr status_clear
	lda disk_changed
	stz disk_changed
	jsr status_put
	lda #$ff ; don't set status
	rts

;---------------------------------------------------------------
; memory_read
;
; In:   x/y  address
;       a    number of bytes
;---------------------------------------------------------------
memory_read:
	stx fat32_ptr
	sty fat32_ptr + 1
	sta fat32_ptr2

	jsr status_clear

	ldy #0
@1:	lda (fat32_ptr),y
	jsr status_put
	iny
	cpy fat32_ptr2
	bne @1

	lda #$ff ; don't set status
	rts

;---------------------------------------------------------------
; memory_write
;
; In:   x/y  structure that contains
;              offset 0   address low
;              offset 1   address hi
;              offset 2   number of bytes
;              offset 3+  data
;---------------------------------------------------------------
memory_write:
	stx fat32_ptr
	sty fat32_ptr + 1

	ldy #0
	lda (fat32_ptr),y
	sta fat32_ptr2
	iny
	lda (fat32_ptr),y
	sta fat32_ptr2 + 1
	iny
	lda (fat32_ptr),y
	sta tmp0

	lda fat32_ptr
	clc
	adc #3
	sta fat32_ptr
	lda fat32_ptr + 1
	adc #0
	sta fat32_ptr + 1

	ldy #0
@1:	lda (fat32_ptr),y
	sta (fat32_ptr2),y
	iny
	cpy tmp0
	bne @1

	lda #0
	rts

;---------------------------------------------------------------
; memory_execute
;
; In:   x/y  address
;---------------------------------------------------------------
memory_execute:
	lda #$4c
	sta fat32_size
	stx fat32_size + 1
	sty fat32_size + 2
	jmp fat32_size

;---------------------------------------------------------------
; set_sector_interleave
;
; In:   a  sector interleave
;---------------------------------------------------------------
set_sector_interleave:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; set_retries
;
; In:   a  retries
;---------------------------------------------------------------
set_retries:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; test_rom_checksum
;
; In:   -
;---------------------------------------------------------------
test_rom_checksum:
	jsr fat32_get_num_contexts
	cmp #0
	bne @bad
	lda #0
	rts
@bad:	nop
	jmp *

;---------------------------------------------------------------
; set_fast_serial
;
; In:   a  fast serial (0/1)
;---------------------------------------------------------------
set_fast_serial:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; set_verify
;
; In:   a  verify (0/1)
;---------------------------------------------------------------
set_verify:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; set_directory_interleave
;
; In:   a  directory interleave
;---------------------------------------------------------------
set_directory_interleave:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; set_large_rel_support
;
; This is the "U0>L" command, which enables/disables support for
; "large" REL files. It is only supported by the C65 drive, and
; unsupported in this implementation.
;
; In:   a  large REL support (0/1)
;---------------------------------------------------------------
set_large_rel_support:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; set_buffer_pointer
;
; In:   a  channel
;       x  pointer
;---------------------------------------------------------------
set_buffer_pointer:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; block_allocate
;
; In:   x  track
;       y  sector
;       medium  medium
;---------------------------------------------------------------
block_allocate:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; block_free
;
; In:   x  track
;       y  sector
;       medium  medium
;---------------------------------------------------------------
block_free:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; block_status
;
; In:   x  track
;       y  sector
;       medium  medium
;---------------------------------------------------------------
block_status:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; block_read
;
; In:   a       channel
;       x       track
;       y       sector
;       medium  medium
;---------------------------------------------------------------
block_read:
	lda #$31 ; unsupported
	rts

block_read_u1:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; block_write
;
; In:   a       channel
;       x       track
;       y       sector
;       medium  medium
;---------------------------------------------------------------
block_write:
	lda #$31 ; unsupported
	rts

block_write_u2:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; block_execute
;
; In:   a       channel
;       x       track
;       y       sector
;       medium  medium
;---------------------------------------------------------------
block_execute:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; set_position
;
; In:   x/y  structure that contains
;              offset 0  channel
;              offset 1  offset[0:7]
;              offset 2  offset[8:15]
;              offset 3  offset[16:23]
;              offset 4  offset[24:31]
;---------------------------------------------------------------
set_position:
	.import context_for_channel
	stx fat32_ptr
	sty fat32_ptr + 1
	lda (fat32_ptr) ; channel
	phx
	tax
	lda context_for_channel,x
	plx
	inx
	bne @1
	iny
@1:	jsr file_set_position
	bcs @error
	lda #0
	rts

@error:	lda #$70 ; no channel
	rts
