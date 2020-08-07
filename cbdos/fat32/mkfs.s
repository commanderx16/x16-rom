;-----------------------------------------------------------------------------
; mkfs.s
; Copyright (C) 2020 Michael Steil
;-----------------------------------------------------------------------------

.import load_mbr_sector, clear_buffer

fat32_mkfs:

	; Get start and size of partition
	lda #0  ; XXX MBR primary partition 1
	jsr fat32_get_ptable_entry
	bcs @error
	set32 cur_volume + fs::lba_partition, fat32_dirent + dirent::start

	; heads/sectors
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
@hs2:	stx heads
	sty sectors

	; Calculate sectors per cluster
	lda #1
	sta sectors_per_cluster

	; Calculate sectors per FAT

	; Create bootsector template
	jsr clear_buffer
	ldx #bootsector_template_size
@tpl:	lda bootsector_template, x
	sta buffer, x
	dex
	bpl @tpl

	rts

@error:
	clc
	rts

bootsector_template:
	.byte $eb, $58, $90 ; $0000   3  x86 jump
	.byte "CBDOS   "    ; $0003   8  OEM name
	.word 512           ; $000b   2  bytes per sector
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
