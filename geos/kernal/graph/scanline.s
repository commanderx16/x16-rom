; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: GetScanLine syscall

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.global _GetScanLine, _GetScanLineCompat

.segment "graph2n"

.import _DMult

.setcpu "65c02"

; This is a fake version of the KERNAL call GetScanLine
; referenced by the jump table. On C64 GEOS, callers of
; the function could safely assume the VIC-II bitmap
; layout and that the bitmap is actually stored in CPU
; memory on the current bank. Neither of this is the
; case on a system with a VERA. deskTop 2.0 for example
; would trash CPU memory if this returned real offsets
; into video RAM. Therefore, to all users in compatMode,
; we return a fake address that cannot cause any harm.
_GetScanLineCompat:
	bit compatMode
	bpl _GetScanLine
	LoadW r5, $ff00
	LoadW r6, $ff00
	rts

.include "../../banks.inc"
.import gjsrfar
.import k_GetScanLine, k_DrawLine, k_DrawPoint, k_FrameRectangle, k_ImprintRectangle, k_InvertRectangle, k_RecoverRectangle, k_Rectangle, k_TestPoint, k_SetColor, k_ImprintLine, k_HorizontalLine, k_InvertLine, k_RecoverLine, k_VerticalLine

.export _GetScanLine, _DrawLine, _DrawPoint, _FrameRectangle, _ImprintRectangle, _InvertRectangle, _RecoverRectangle, _Rectangle, _TestPoint, _SetColor, ImprintLine, _HorizontalLine, _InvertLine, _RecoverLine, _VerticalLine

.import k_dispBufferOn, k_compatMode, k_col1, k_col2

.macro jmpf addr
	php
	pha
	lda dispBufferOn
	sta k_dispBufferOn
	lda compatMode
	sta k_compatMode
	lda col1
	sta k_col1
	lda col2
	sta k_col2
	pla
	plp
	php
	sei
	jsr gjsrfar
	.word addr
	.byte BANK_KERNAL
	plp
	rts
.endmacro

_GetScanLine:
	jmpf k_GetScanLine

_DrawLine:
	jmpf k_DrawLine

_DrawPoint:
	jmpf k_DrawPoint

_FrameRectangle:
	jmpf k_FrameRectangle

_ImprintRectangle:
	jmpf k_FrameRectangle

_InvertRectangle:
	jmpf k_InvertRectangle

_RecoverRectangle:
	jmpf k_RecoverRectangle

_Rectangle:
	jmpf k_Rectangle

_TestPoint:
	jmpf k_TestPoint

_SetColor:
	jmpf k_SetColor

ImprintLine:
	jmpf k_ImprintLine

_HorizontalLine:
	jmpf k_HorizontalLine

_InvertLine:
	jmpf k_InvertLine

_RecoverLine:
	jmpf k_RecoverLine

_VerticalLine:
	jmpf k_VerticalLine
