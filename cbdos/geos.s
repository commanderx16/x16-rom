;
; GEOS
;
; TODO: The SD card driver is using zero page and other memory
;       locations that are also used by GEOS! We need too find
;       memory that is unused by KERNAL, BASIC and GEOS!

.include "../geos/inc/geossym.inc"
.include "../geos/inc/geosmac.inc"

.import sd_read_block_lower, sd_read_block_upper
.import read_blkptr, sdcard_init

.export cbmdos_GetNxtDirEntry, cbmdos_Get1stDirEntry, cbmdos_CalcBlksFree, cbmdos_GetDirHead, cbmdos_ReadBlock, cbmdos_ReadBuff, cbmdos_OpenDisk

.segment "cbdos_data"

lba_addr:
	.byte 0,0,0,0

.segment "cbdos"

cbmdos_OpenDisk:
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

cbmdos_ReadBuff:
	LoadW r4, $8000
cbmdos_ReadBlock:
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
@l4:	sta lba_addr+0
	sty lba_addr+1
	stz lba_addr+2
	stz lba_addr+3
	lsr lba_addr+1 ; / 2
	ror lba_addr+0
	lda r4L
	sta read_blkptr
	lda r4H
	sta read_blkptr + 1
	bcs @l5
;XXX	jsr sd_read_block_lower
	jmp @l6
@l5:
;XXX	jsr sd_read_block_upper
@l6:	ldx #0 ; no error
	rts



cbmdos_GetDirHead:
	jsr get_dir_head
	LoadW r4, $8200
	rts


cbmdos_CalcBlksFree:
	LoadW r4, 999*4
	LoadW r3, 999*4
	ldx #0
	rts


cbmdos_Get1stDirEntry:
	LoadW r4, $8000
	LoadB r1L, 18
	LoadB r1H, 1
	jsr cbmdos_ReadBlock
	lda #$02
	sta r4L
	sta r5L
	lda #$80
	sta r4H
	sta r5H
	ldx #0
	sec
	rts

cbmdos_GetNxtDirEntry:
	ldy #1
	clc
	rts

get_dir_head:
	LoadB r1L, 18
	LoadB r1H, 0
	LoadW r4, $8200
	jmp cbmdos_ReadBlock

secpertrack:
	.byte 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 19, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17

