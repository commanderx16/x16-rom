; GEOS for Commander X16
;
; CBDOS disk driver

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "jumptab.inc"

.include "banks.inc"

.segment "drvcbdos"

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

.import gjsrfar

__OpenDisk:
	php
	sei
	jsr gjsrfar
	.word $c000 + 3 * 8
	.byte BANK_CBDOS
	plp
	rts

_ReadBuff:
	php
	sei
	jsr gjsrfar
	.word $c000 + 3 * 9
	.byte BANK_CBDOS
	plp
	rts

__ReadBlock:
__GetBlock:
	php
	sei
	jsr gjsrfar
	.word $c000 + 3 * 10
	.byte BANK_CBDOS
	plp
	rts

__GetDirHead:
	php
	sei
	jsr gjsrfar
	.word $c000 + 3 * 11
	.byte BANK_CBDOS
	plp
	rts

__CalcBlksFree:
	php
	sei
	jsr gjsrfar
	.word $c000 + 3 * 12
	.byte BANK_CBDOS
	plp
	rts

_Get1stDirEntry:
	php
	sei
	jsr gjsrfar
	.word $c000 + 3 * 13
	.byte BANK_CBDOS
	plp
	rts

_GetNxtDirEntry:
	php
	sei
	jsr gjsrfar
	.word $c000 + 3 * 14
	.byte BANK_CBDOS
	plp
	rts

