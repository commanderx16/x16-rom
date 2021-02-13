;-----------------------------------------------------------------------------
; mkfs.s
; Copyright (C) 2020 Michael Steil
;-----------------------------------------------------------------------------

.include "lib.inc"

; sdcard.s
.import sector_lba, sector_buffer

; fat32.s
.import load_mbr_sector, write_sector, clear_buffer, fat32_dirent, fat32_get_ptable_entry
.import set_errno, fat32_errno, unmount

.export fat32_mkfs

RESERVED_SECTORS_DEFAULT = 32
MAX_SECTORS_PER_CLUSTER_SHIFT = 7

.bss

; These are temporary and don't carry any state across calls to fat32_mkfs,
; so don't have to be cleared.

sectors_per_cluster_shift:
	.byte 0
sectors_per_cluster:
	.byte 0
sectors_per_cluster_minus_1:
	.byte 0
sectors_per_cluster_mask:
	.byte 0
lba_partition:
	.dword 0
fat_size:
	.dword 0
fat_size_count:
	.dword 0
reserved_sectors:
	.byte 0
tmp:
	.dword 0
oemname_ptr:
	.word 0

.code

;-----------------------------------------------------------------------------
; fat32_mkfs
;
; Create a FAT32 filesystem.
;
; In:  a             partition (0-3)
;      x             sectors per cluster (0 = default)
;      fat32_ptr     volume label (8 chars)
;      fat32_ptr2    volume ID (4 bytes)
;      fat32_bufptr  OEM name (8 chars)
;
; * c=0: failure; sets errno
;-----------------------------------------------------------------------------
fat32_mkfs:
	stz fat32_errno

	stx sectors_per_cluster

	; Save argument (overwritten by fat32_get_ptable_entry)
	ldx fat32_bufptr
	stx oemname_ptr
	ldx fat32_bufptr + 1
	stx oemname_ptr + 1

	pha
	jsr unmount
	pla
	bcc @error

	; Get start and size of partition
	jsr fat32_get_ptable_entry
	bcs @ok0
@error:
	clc
	rts
@ok0:

	; Make sure it's a FAT32 partition
	lda fat32_dirent + dirent::attributes
	cmp #$0b
	beq @ok1
	cmp #$0c
	bne @error_inconsistent
@ok1:

	; Extract number of sectors in partition
	set32 lba_partition, fat32_dirent + dirent::start

	; Create bootsector template
	jsr clear_buffer
	ldx #bootsector_template_size
@tpl:	lda bootsector_template, x
	sta sector_buffer, x
	dex
	bpl @tpl

	; Set signature
	lda #$55
	sta sector_buffer + $1fe
	asl
	sta sector_buffer + $1ff

	; Set sector count
	set32 sector_buffer + o_sector_count, fat32_dirent + dirent::size

	; Calculate heads/sectors
	; * <= 1M sectors: 64 heads and 32 sectors
	; * >  1M sectors: 255 heads and 63 sectors
	lda fat32_dirent + dirent::size + 2
	sec
	sbc #$10
	lda fat32_dirent + dirent::size + 3
	sbc #0
	bcs @hs1
	ldx #64
	ldy #32
	bra @hs2
@hs1:	ldx #255
	ldy #63
@hs2:	stx sector_buffer + o_heads
	sty sector_buffer + o_sectors_per_track

	; Check minimal FS size
	; clusters < 65525 is illegal (we cut off at 65536)
	lda fat32_dirent + dirent::size + 2
	ora fat32_dirent + dirent::size + 3
	bne @mfs1
@error_inconsistent:
	lda #ERRNO_FS_INCONSISTENT
	jmp set_errno
@mfs1:

	; Check maximum FS size
	; sector count can't be >= $FFFFFF00 (just below 2 TB),
	; since this would overflow some calculations below.
	lda #$ff
	cmp fat32_dirent + dirent::size + 3
	bne @mfs2
	cmp fat32_dirent + dirent::size + 2
	bne @mfs2
	cmp fat32_dirent + dirent::size + 1
	beq @error_inconsistent

@mfs2:

	; Verify user-passed sectors per cluster value
	lda sectors_per_cluster
	beq @usc3 ; user wants default
	ldx #0
@usc1:	lsr
	bcs @usc2
	inx
	bra @usc1
@usc2:	tay
	bne @error_inconsistent ; not a power of two
	; XXX User-passed value could either be too low (more than 2^24
	;     clusters), or too high (less than 65525 clusters).
	bra @spc3

@usc3:
	; Calculate sectors per cluster
	; Higher sectors per cluster values waste space, but speed up access
	; (fewer FAT lookups), and significantly speed up formatting.
	; We pick the highest legal value. There have to be at least 65525
	; clusters, so the algorithm is to keep ASLing the number of sectors
	; until it's $0001nnnn, i.e. between 65536 and 131071.
	set32 tmp, fat32_dirent + dirent::size
	ldx #0
@spc1:	lda tmp + 3
	bne @spc2
	lda tmp + 2
	dec
	beq @spc3
@spc2:	shr32 tmp
	inx
	cpx #MAX_SECTORS_PER_CLUSTER_SHIFT
	bne @spc1
@spc3:	stx sectors_per_cluster_shift
	; Calculate derived values
	lda #1
@sps1:	cpx #0
	beq @sps2
	asl
	dex
	bra @sps1
@sps2:	sta sectors_per_cluster
	sta sector_buffer + o_sectors_per_cluster
	dec
	sta sectors_per_cluster_minus_1
	eor #$ff
	sta sectors_per_cluster_mask

	; Calculate reserved sectors
	; must be at least sectors_per_cluster
	lda sectors_per_cluster
	cmp #RESERVED_SECTORS_DEFAULT
	bcs @rs1
	lda #RESERVED_SECTORS_DEFAULT
@rs1:	sta reserved_sectors
	sta sector_buffer + o_reserved_sectors

	; Calculate sectors per FAT
	;
	; This is the formula:
	; * cluster_count = ceil(sector_count / sectors_per_cluster)
	; * fat_size = ceil(cluster_count / 130)
	; * Then round up to make divisible by sectors_per_cluster.
	; Dividing by 130 is hard, but dividing by 128 is easy.
	; We divide by 128 here, which makes the FAT about 1.5% larger
	; than it should be.

	; add sectors_per_cluster - 1
	add32_8 fat_size, sector_buffer + o_sector_count, sectors_per_cluster_minus_1

	; Divide by sectors_per_cluster
	ldx sectors_per_cluster_shift
@spf1:	cpx #0
	beq @spf2
	lsr fat_size + 3
	ror fat_size + 2
	ror fat_size + 1
	ror fat_size + 0
	dex
	bra @spf1
@spf2:

	; Add 127, divide by 128
	lda fat_size
	clc
	adc #127
	tax
	lda fat_size + 1
	adc #0
	sta fat_size
	lda fat_size + 2
	adc #0
	sta fat_size + 1
	lda fat_size + 3
	adc #0
	sta fat_size + 2
	stz fat_size + 3
	txa
	asl
	rol fat_size
	rol fat_size + 1
	rol fat_size + 2
	rol fat_size + 3

	; Round up to make divisible by sectors_per_cluster
	add2_32_8 fat_size, sectors_per_cluster_minus_1
	lda fat_size
	and sectors_per_cluster_mask
	sta fat_size

	set32 sector_buffer + o_fat_size, fat_size

	; Set volume ID
	lda fat32_ptr2
	ora fat32_ptr2 + 1
	beq @vi2
	ldy #0
@vi1:	lda (fat32_ptr2), y
	beq @vi2
	sta sector_buffer + o_vol_id, y
	iny
	cpy #4
	bne @vi1
@vi2:

	; Set volume label
	lda fat32_ptr
	ora fat32_ptr + 1
	beq @vl2
	ldy #0
@vl1:	lda (fat32_ptr), y
	beq @vl2
	sta sector_buffer + o_vol_label, y
	iny
	cpy #11
	bne @vl1
@vl2:

	; Set OEM name
	lda oemname_ptr
	sta fat32_bufptr
	ora oemname_ptr + 1
	beq @on2
	lda oemname_ptr + 1
	sta fat32_bufptr + 1
	ldy #0
@on1:	lda (fat32_bufptr), y
	beq @on2
	sta sector_buffer + o_oem_name, y
	iny
	cpy #8
	bne @on1
@on2:

	; Write boot sector
	set32 sector_lba, lba_partition
	jsr write_sector
	bcs @ok2
@error3:
	rts
@ok2:
	add32_val sector_lba, sector_lba, 6
	jsr write_sector
	bcc @error3

	; FS Information Sector
	jsr clear_buffer
	lda #$52
	sta sector_buffer + 0
	sta sector_buffer + 1
	lda #$61
	sta sector_buffer + 2
	lda #$41
	sta sector_buffer + 3
	lda #$72
	sta sector_buffer + $1e4
	sta sector_buffer + $1e5
	lda #$41
	sta sector_buffer + $1e6
	lda #$61
	sta sector_buffer + $1e7
	lda #$55
	sta sector_buffer + $1fe
	asl
	sta sector_buffer + $1ff

	; Calculate free clusters
	; floor((sector_count - reserved_sectors - 2 * fat_size) / sectors_per_cluster) - 1
	;                                                        directory cluster ^^^

	; sector_count - 2 * fat_size - reserved_sectors
	sub32 sector_buffer + $1e8, fat32_dirent + dirent::size, fat_size
	sub32 sector_buffer + $1e8, sector_buffer + $1e8, fat_size
	sub2_32_8 sector_buffer + $1e8, reserved_sectors

	; divide by sectors_per_cluster
	ldx sectors_per_cluster_shift
@fc1:	cpx #0
	beq @fc2
	lsr sector_buffer + $1e8 + 3
	ror sector_buffer + $1e8 + 2
	ror sector_buffer + $1e8 + 1
	ror sector_buffer + $1e8 + 0
	dex
	bra @fc1
@fc2:
	; - 1 (directory cluster)
	dec32 sector_buffer + $1e8

	; Set last allocated data cluster
	lda #2
	sta sector_buffer + $1ec

	; write FS information sector
	add32_val sector_lba, lba_partition, 1
	jsr write_sector
	bcs :+
	jmp @error2
:
	; FAT
	jsr clear_buffer
	; FAT ID: F8 FF FF 0F
	lda #$f8
	sta sector_buffer + 0
	lda #$ff
	sta sector_buffer + 1
	sta sector_buffer + 2
	lda #$0f
	sta sector_buffer + 3
	; End of chain indicator: FF FF FF 0F
	lda #$ff
	sta sector_buffer + 4
	sta sector_buffer + 5
	sta sector_buffer + 6
	lda #$0f
	sta sector_buffer + 7
	; F8 FF FF 0F
	lda #$f8
	sta sector_buffer + 8
	lda #$ff
	sta sector_buffer + 9
	sta sector_buffer + 10
	lda #$0f
	sta sector_buffer + 11

	; Write first sector of FAT
	add32_8 sector_lba, lba_partition, reserved_sectors
	jsr write_sector
	bcc @error2

	; Write first sector of second FAT
	add32 sector_lba, sector_lba, fat_size
	jsr write_sector
	bcc @error2

	; Clear remainder of FAT
	jsr clear_buffer
	add32_8 sector_lba, lba_partition, reserved_sectors
	jsr write_empty_fat_sectors
	bcc @error2
	jsr write_empty_fat_sectors
	bcc @error2

	; Clear root directory
	lda sectors_per_cluster + 0
	sta fat_size_count + 0
	stz fat_size_count + 1
	stz fat_size_count + 2
	stz fat_size_count + 3
	jsr write_empty_sectors

	rts

@error2:
	clc
	rts

write_empty_fat_sectors:
	set32 fat_size_count, fat_size
ef1:
	inc32 sector_lba
	dec32 fat_size_count
	cmp32_z fat_size_count, ef2
write_empty_sectors:
	jsr write_sector
	bcc error
	bra ef1
ef2:	sec
error:	rts


bootsector_template:
	.byte $eb, $58, $90 ; $0000   3  x86 jump
o_oem_name = * - bootsector_template
	.byte "        "    ; $0003   8  OEM name
	.word 512           ; $000b   2  bytes per sector
o_sectors_per_cluster = * - bootsector_template
	.byte 0             ; $000d   1 *sectors per cluster
o_reserved_sectors = * - bootsector_template
	.word 0             ; $000e   2  reserved sectors
	.byte 2             ; $0010   1  number of FATs
	.word 0             ; $0011   2  unused
	.word 0             ; $0013   2  unused
	.byte $f8           ; $0015   1  media descriptor
	.word 0             ; $0016   2  unused
o_sectors_per_track = * - bootsector_template
	.word 0             ; $0018   2 *sectors per track
o_heads = * - bootsector_template
	.word 0             ; $001A   2 *heads
	.dword 0            ; $001C   4  hidden sectors
o_sector_count = * - bootsector_template
	.dword 0            ; $0020   4 *total sectors
o_fat_size = * - bootsector_template
	.dword 0            ; $0024   4 *sectors per FAT
	.word 0             ; $0028   2  drive description
	.word 0             ; $002A   2  version
	.dword 2            ; $002C   4  root dir start cluster
	.word 1             ; $0030   2  LBA FS Information Sector
	.word 6             ; $0032   2  LBA boot sectors copy
	.res 12, 0          ; $0034  12  reserved
	.byte $80           ; $0040   1  physical drive number
	.byte 0             ; $0041   1  unused
	.byte $29           ; $0042   1  extended boot signature
o_vol_id = * - bootsector_template
	.dword 0            ; $0043   4 *volume ID
o_vol_label = * - bootsector_template
	.byte "           " ; $0047  11 *volume label
	.byte "FAT32   "    ; $0052   8  filesystem type
bootsector_template_size = * - bootsector_template
