;----------------------------------------------------------------------
; CMDR-DOS GEOS Support
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD
;
; TODO: The SD card driver is using zero page and other memory
;       locations that are also used by GEOS! We need too find
;       memory that is unused by KERNAL, BASIC and GEOS!

.include "../geos/inc/geossym.inc"
.include "../geos/inc/geosmac.inc"
.include "fat32/sdcard.inc"

.import sector_buffer, sector_lba

.export dos_GetNxtDirEntry, dos_Get1stDirEntry, dos_CalcBlksFree, dos_GetDirHead, dos_ReadBlock, dos_ReadBuff, dos_OpenDisk

.code

dos_OpenDisk:
	jsr sdcard_init

	jsr get_dir_head
	LoadB $848b, $ff ; isGEOS
	ldx #17
:	lda $8290,x
	sta $841e,x
	dex
	bpl :-
	LoadW r5, $841e
	ldx #0
	rts

dos_ReadBuff:
	LoadW r4, $8000
dos_ReadBlock:
GetBlock:
	ldx #1
	lda #0
	tay
@l1:	cpx r1L
	beq @l2
	clc
	adc secpertrack - 1,x
	bcc @l3
	iny
@l3:	inx
	jmp @l1
@l2:	clc
	adc r1H
	bcc @l4
	iny
@l4:	sta sector_lba+0
	sty sector_lba+1
	stz sector_lba+2
	stz sector_lba+3
	lsr sector_lba+1 ; / 2
	ror sector_lba+0

	php
	jsr sdcard_read_sector
	plp
	bcs @l5

	ldy #0
:	lda sector_buffer,y
	sta (r4),y
	iny
	bne :-
	bra @l6

@l5:	ldy #0
:	lda sector_buffer + 256,y
	sta (r4),y
	iny
	bne :-

@l6:	ldx #0 ; no error
	rts



dos_GetDirHead:
	jsr get_dir_head
	LoadW r4, $8200
	rts


dos_CalcBlksFree:
	LoadW r4, 999*4
	LoadW r3, 999*4
	ldx #0
	rts


dos_Get1stDirEntry:
	LoadW r4, $8000
	LoadB r1L, 18
	LoadB r1H, 1
	jsr dos_ReadBlock
	lda #$02
	sta r4L
	sta r5L
	lda #$80
	sta r4H
	sta r5H
	ldx #0
	sec
	rts

dos_GetNxtDirEntry:
	ldy #1
	clc
	rts

get_dir_head:
	LoadB r1L, 18
	LoadB r1H, 0
	LoadW r4, $8200
	jmp dos_ReadBlock

secpertrack:
	.byte 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 19, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17
