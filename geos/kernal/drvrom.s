; GEOS for Commander X16
;
; ROM disk driver

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "jumptab.inc"

.segment "drvrom"

; CALL ffffff33 GetNxtDirEntry

_InitForIO:
	.word __InitForIO
_DoneWithIO:
	.word __DoneWithIO
_ExitTurbo:
	.word __ExitTurbo
_PurgeTurbo:
	.word __PurgeTurbo
_EnterTurbo:
	.word __EnterTurbo
_ChangeDiskDevice:
	.word __ChangeDiskDevice
_NewDisk:
	.word __NewDisk
_ReadBlock:
	.word __ReadBlock
_WriteBlock:
	.word __WriteBlock
_VerWriteBlock:
	.word __VerWriteBlock
_OpenDisk:
	.word __OpenDisk
_GetBlock:
	.word __GetBlock
_PutBlock:
	.word __PutBlock
_GetDirHead:
	.word __GetDirHead
_PutDirHead:
	.word __PutDirHead
_GetFreeDirBlk:
	.word __GetFreeDirBlk
_CalcBlksFree:
	.word __CalcBlksFree
_FreeBlock:
	.word __FreeBlock
_SetNextFree:
	.word __SetNextFree
_FindBAMBit:
	.word __FindBAMBit
_NxtBlkAlloc:
	.word __NxtBlkAlloc
_BlkAlloc:
	.word __BlkAlloc
_ChkDkGEOS:
	.word __ChkDkGEOS
_SetGEOSDisk:
	.word __SetGEOSDisk

Get1stDirEntry:
	jmp _Get1stDirEntry
GetNxtDirEntry:
	jmp _GetNxtDirEntry
GetBorder:
	jmp _GetBorder
AddDirBlock:
	jmp _AddDirBlock
ReadBuff:
	jmp _ReadBuff

.if 0
WriteBuff:
	jmp _WriteBuff

	jmp DUNK4_2

	jmp GetDOSError
AllocateBlock:
	jmp _AllocateBlock
ReadLink:
	jmp _ReadLink
.endif

__EnterTurbo:
__ExitTurbo:
	; do nothing
	ldx #0
__InitForIO:
__DoneWithIO:
	rts

__PurgeTurbo:
__ChangeDiskDevice:
__NewDisk:
__WriteBlock:
__VerWriteBlock:
__PutBlock:
__PutDirHead:
__GetFreeDirBlk:
__FreeBlock:
__SetNextFree:
__FindBAMBit:
__NxtBlkAlloc:
__BlkAlloc:
__ChkDkGEOS:
__SetGEOSDisk:
_GetBorder:
_AddDirBlock:
_WriteBuff:
DUNK4_2:
GetDOSError:
_AllocateBlock:
_ReadLink:
	; TODO
	rts


__OpenDisk:
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

_ReadBuff:
	LoadW r4, $8000
__ReadBlock:
__GetBlock:
	lda r1L
	cmp #18
	bne not_18
	lda r1H
	beq get_block_1
	cmp #1
	beq get_block_1
	bne empty_block ; always

not_18:	bcc empty_block

	lda r1H
	clc
	adc #2
get_block_1:
	jsr get_block
	ldx #0
	sec
	rts

empty_block:
	lda #$ff
	bne get_block_1 ; always


__GetDirHead:
	jsr get_dir_head
	LoadB r1L, 18
	LoadB r1H, 0
	LoadW r4, $8200
	rts


__CalcBlksFree:
	LoadW r4, 999*4
	LoadW r3, 999*4
	ldx #0
	rts


_Get1stDirEntry:
	LoadW r4, $8000
	lda #1
	jsr get_block
	lda #$02
	sta r4L
	sta r5L
	lda #$80
	sta r4H
	sta r5H
	ldx #0
	sec
	rts

_GetNxtDirEntry:
	ldy #1
	clc
	rts

get_dir_head:
	lda #0
	; fallthrough
get_block:
	cmp #$ff
;	bne not_empty_block
	ldy #0
	tya
:	sta (r4),y ; clear block
	iny
	bne :-
	lda #$ff
	iny
	sta (r4),y ; link $00/$FF
	rts

.if 0
not_empty_block:
	php
	sei
	pha
	lsr
	lsr
	lsr
	lsr
	lsr ; bank
	clc
	adc #1 ; skip code ROM bank
	ldx $9f60
	bit $9f60 ; ROM bank
	pla
	tay
	PushW r5
	tya
	and #$1f
	clc
	adc #$c0
	sta r5H
	lda #0
	sta r5L
	ldy #0
:	lda (r5),y
	sta (r4),y
	iny
	bne :-

	PopW r5
	stx $9f60
	plp
	rts
.endif
