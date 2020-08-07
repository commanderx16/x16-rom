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

	; $0000   3  $eb, $58, $90
	; $0003   8  OEM name
	; $000b   2  bytes per sector ($00, $02)
	; $000d   1 *sectors per cluster
	; $000e   2  reserved sectors ($20, $00)
	; $0010   1  number of FATs ($02)
	; $0011   2  unused ($00, $00)
	; $0013   2  unused ($00, $00)
	; $0015   1  media descriptor ($f8)
	; $0016   2  unused ($00, $00)
	; $0018   2 *sectors per track
	; $001A   2 *heads
	; $001C   4  hidden sectors ($00, $00, $00, $00)
	; $0020   4 *total sectors
	; $0024   4 *sectors per FAT
	; $0028   2  drive description ($00, $00)
	; $002A   2  version ($00, $00)
	; $002C   4  root dir start cluster ($02, $00, $00, $00)
	; $0030   2  LBA FS Information Sector ($01, $00)
	; $0032   2  LBA boot sectors copy ($06, $00)
	; $0034  12  reserved ($00, ...)
	; $0040   1  physical drive number ($80)
	; $0041   1  unused ($00)
	; $0042   1  extended boot signature ($29)
	; $0043   4 *volume ID
	; $0047  11 *volume label
	; $0052   8  filesystem type ($46, $41, $54, $33, $32, $20, $20, $20)
	; $01FE   2  signature ($55, $AA)

	jsr clear_buffer

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



	rts

@error:
	clc
	rts
