;-----------------------------------------------------------------------------
; mkfs.s
; Copyright (C) 2020 Michael Steil
;-----------------------------------------------------------------------------

.include "lib.inc"

; sdcard.s
.import sector_lba, sector_buffer

; fat32.s
.import load_mbr_sector, write_sector, clear_buffer, fat32_dirent, fat32_get_ptable_entry

.export fat32_mkfs

.bss

sectors_per_cluster_shift:
	.byte 0
lba_partition:
	.dword 0

.code

fat32_mkfs:
	; Get start and size of partition
	lda #0  ; XXX MBR primary partition 1
	jsr fat32_get_ptable_entry
	bcs @ok
@error:
	clc
	rts

@ok:	set32 lba_partition, fat32_dirent + dirent::start

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
	sty o_heads + o_sectors_per_track

	; Calculate sectors per cluster
	ldx #0 ; XXX fixed: 1
	stx sectors_per_cluster_shift
	lda #1
@spc1:	cpx #0
	beq @spc2
	asl
	dex
	bra @spc1
@spc2:	sta sector_buffer + o_sectors_per_cluster

	; Calculate sectors per FAT
	; naive formula:
	; * cluster_count = ceil(sector_count / sectors_per_cluster)
	; * fat_size = ceil(cluster_count / 128)

	; add sectors_per_cluster - 1
	lda sector_buffer + o_sector_count + 0
	dec sector_buffer + o_sectors_per_cluster
	clc
	adc sector_buffer + o_sectors_per_cluster
	inc sector_buffer + o_sectors_per_cluster
	sta sector_buffer + o_fat_size + 0
	lda sector_buffer + o_sector_count + 1
	adc #0
	sta sector_buffer + o_fat_size + 1
	lda sector_buffer + o_sector_count + 2
	adc #0
	sta sector_buffer + o_fat_size + 2
	lda sector_buffer + o_sector_count + 3
	adc #0
	sta sector_buffer + o_fat_size + 3

	; divide by sectors_per_cluster
	ldx sectors_per_cluster_shift
@spf1:	cpx #0
	beq @spf2
	lsr sector_buffer + o_fat_size + 3
	ror sector_buffer + o_fat_size + 2
	ror sector_buffer + o_fat_size + 1
	ror sector_buffer + o_fat_size + 0
	dex
	bra @spf1
@spf2:

	; add 127, divide by 128
	lda sector_buffer + o_fat_size
	clc
	adc #127
	tax
	lda sector_buffer + o_fat_size + 1
	adc #0
	sta sector_buffer + o_fat_size
	lda sector_buffer + o_fat_size + 2
	adc #0
	sta sector_buffer + o_fat_size + 1
	lda sector_buffer + o_fat_size + 3
	adc #0
	sta sector_buffer + o_fat_size + 2
	stz sector_buffer + o_fat_size + 2
	txa
	asl
	rol sector_buffer + o_fat_size
	rol sector_buffer + o_fat_size + 1
	rol sector_buffer + o_fat_size + 2
	rol sector_buffer + o_fat_size + 3

	; write boot sector
	set32 sector_lba, lba_partition
	jsr write_sector
;	bcc @error

	rts


bootsector_template:
	.byte $eb, $58, $90 ; $0000   3  x86 jump
	.byte "CBDOS   "    ; $0003   8  OEM name
	.word 512           ; $000b   2  bytes per sector
o_sectors_per_cluster = * - bootsector_template
	.byte 0             ; $000d   1 *sectors per cluster
	.word 32            ; $000e   2  reserved sectors
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
	.res 11, 0          ; $0047  11 *volume label
	.byte "FAT32   "    ; $0052   8  filesystem type
bootsector_template_size = * - bootsector_template
