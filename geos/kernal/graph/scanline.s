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

_GetScanLine:
	brk


.include "../../banks.inc"
.import gjsrfar
.import k_DrawLine, k_DrawPoint, k_FrameRectangle, k_ImprintRectangle, k_InvertRectangle, k_RecoverRectangle, k_Rectangle, k_TestPoint, k_SetColor, k_ImprintLine, k_HorizontalLine, k_InvertLine, k_RecoverLine, k_VerticalLine

.export _DrawLine, _DrawPoint, _FrameRectangle, _ImprintRectangle, _InvertRectangle, _RecoverRectangle, _Rectangle, _TestPoint, _SetColor, ImprintLine, _HorizontalLine, _InvertLine, _RecoverLine, _VerticalLine

_DrawLine:
	jsr gjsrfar
	.word k_DrawLine
	.byte BANK_KERNAL
	rts

_DrawPoint:
	jsr gjsrfar
	.word k_DrawPoint
	.byte BANK_KERNAL
	rts

_FrameRectangle:
	jsr gjsrfar
	.word k_FrameRectangle
	.byte BANK_KERNAL
	rts

_ImprintRectangle:
	jsr gjsrfar
	.word k_FrameRectangle
	.byte BANK_KERNAL
	rts

_InvertRectangle:
	jsr gjsrfar
	.word k_InvertRectangle
	.byte BANK_KERNAL
	rts

_RecoverRectangle:
	jsr gjsrfar
	.word k_RecoverRectangle
	.byte BANK_KERNAL
	rts

_Rectangle:
	jsr gjsrfar
	.word k_Rectangle
	.byte BANK_KERNAL
	rts

_TestPoint:
	jsr gjsrfar
	.word k_TestPoint
	.byte BANK_KERNAL
	rts

_SetColor:
	jsr gjsrfar
	.word k_SetColor
	.byte BANK_KERNAL
	rts

ImprintLine:
	jsr gjsrfar
	.word k_ImprintLine
	.byte BANK_KERNAL
	rts

_HorizontalLine:
	jsr gjsrfar
	.word k_HorizontalLine
	.byte BANK_KERNAL
	rts

_InvertLine:
	jsr gjsrfar
	.word k_InvertLine
	.byte BANK_KERNAL
	rts

_RecoverLine:
	jsr gjsrfar
	.word k_RecoverLine
	.byte BANK_KERNAL
	rts

_VerticalLine:
	jsr gjsrfar
	.word k_VerticalLine
	.byte BANK_KERNAL
	rts
