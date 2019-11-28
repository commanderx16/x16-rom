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
.import k_GetScanLine, k_DrawLine, k_DrawPoint, k_FrameRectangle, k_ImprintRectangle, k_InvertRectangle, k_RecoverRectangle, k_Rectangle, k_TestPoint, k_SetColor, k_HorizontalLine, k_InvertLine, k_RecoverLine, k_VerticalLine, k_SetVRAMPtrFG, k_StoreVRAM

.export _GetScanLine, _DrawLine, _DrawPoint, _FrameRectangle, _ImprintRectangle, _InvertRectangle, _RecoverRectangle, _Rectangle, _TestPoint, _SetColor, _HorizontalLine, _InvertLine, _RecoverLine, _VerticalLine, _SetVRAMPtrFG, _StoreVRAM

.import k_dispBufferOn, k_col1, k_col2

.macro far_pre
	php
	pha
	lda dispBufferOn
	sta k_dispBufferOn
	lda col1
	sta k_col1
	lda col2
	sta k_col2
	pla
	plp
	php
	sei
.endmacro

.macro jmpf addr
	far_pre
	jsr gjsrfar
	.word addr
	.byte BANK_KERNAL
	plp
	rts
.endmacro

.macro jsrf addr
	far_pre
	jsr gjsrfar
	.word addr
	.byte BANK_KERNAL
	plp
.endmacro

_GetScanLine:
	jmpf k_GetScanLine

;---------------------------------------------------------------
; DrawLine                                                $C130
;
; Pass:      signFlg  set to recover from back screen
;                     reset for drawing
;            carryFlg set for drawing in forground color
;                     reset for background color
;            r3       x pos of 1st point (0-319)
;            r11L     y pos of 1st point (0-199)
;            r4       x pos of 2nd point (0-319)
;            r11H     y pos of 2nd point (0-199)
; Return:    -
; Destroyed: a, x, y, r4 - r8, r11
;---------------------------------------------------------------
_DrawLine:
	bmi @3 ; recover
; draw
	lda #0
	rol
	eor #1
	sta col1
@3:	jmpf k_DrawLine

;---------------------------------------------------------------
; DrawPoint                                               $C133
;
; Pass:      r3       x pos of point (0-319)
;            r11L     y pos of point (0-199)
;            carryFlg color: 0: black; 1: white
;            signFlg  0: draw color; 1: recover
; Return:    -
; Destroyed: a, x, y, r5 - r6
;---------------------------------------------------------------
_DrawPoint:
	bmi @3 ; recover
; draw
	lda #0
	rol
	eor #1
	sta col1
@3:	jmpf k_DrawPoint

;---------------------------------------------------------------
; FrameRectangle                                          $C127
;
; Pass:      a   pattern byte
;            r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    r2L, r3H unchanged
; Destroyed: a, x, y, r5 - r9, r11
;---------------------------------------------------------------
_FrameRectangle:
	jsr Convert8BitPattern
	sta col1
	jmpf k_FrameRectangle

_ImprintRectangle:
	jmpf k_ImprintRectangle

_InvertRectangle:
	jmpf k_InvertRectangle

_RecoverRectangle:
	jmpf k_RecoverRectangle

_Rectangle:
	jmpf k_Rectangle

;---------------------------------------------------------------
; TestPoint                                               $C13F
;
; Pass:      r3   x position of pixel (0-319)
;            r11L y position of pixel (0-199)
; Return:    carry set if bit is set
; Destroyed: a, x, y, r5, r6
;---------------------------------------------------------------
_TestPoint:
	php
	sei
	jsr gjsrfar
	.word k_TestPoint
	.byte BANK_KERNAL
	plp
	cmp #0  ; black
	beq @1
	cmp #16 ; also black
	beq @1
	clc
	rts
@1:	sec
	rts

_SetColor:
	jmpf k_SetColor

;---------------------------------------------------------------
; HorizontalLine                                          $C118
;
; Pass:      a    pattern byte
;            r3   x in pixel of left end (0-319)
;            r4   x in pixel of right end (0-319)
;            r11L y position in scanlines (0-199)
; Return:    r11L unchanged
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_HorizontalLine:
	jsr Convert8BitPattern
	sta col1
	PushW r3
	PushW r4
	PushW r11
	MoveB r11L, r11H
	lda #0
	jsrf k_DrawLine
	PopW r11
	PopW r4
	PopW r3
	rts

_InvertLine:
	jmpf k_InvertLine

;---------------------------------------------------------------
; RecoverLine                                             $C11E
;
; Pass:      r3   x pos of left endpoint (0-319)
;            r4   x pos of right endpoint (0-319)
;            r11L y pos of line (0-199)
; Return:    copies bits of line from background to
;            foreground sceen
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
_RecoverLine:
	PushW r3
	PushW r4
	PushW r11
	MoveB r11L, r11H
	lda #$ff
	jsrf k_DrawLine
	PopW r11
	PopW r4
	PopW r3
	rts

;---------------------------------------------------------------
; VerticalLine                                            $C121
;
; Pass:      a pattern byte
;            r3L top of line (0-199)
;            r3H bottom of line (0-199)
;            r4  x position of line (0-319)
; Return:    draw the line
; Destroyed: a, x, y, r4 - r8, r11
;---------------------------------------------------------------
_VerticalLine:
	jsr Convert8BitPattern
	sta col1
	PushW r3
	MoveW r3, r11
	MoveW r4, r3
	lda #0
	jsrf k_DrawLine
	PopW r3
	rts

_SetVRAMPtrFG:
	jmpf k_SetVRAMPtrFG

_StoreVRAM:
	jmpf k_StoreVRAM

;---------------------------------------------------------------
; Color compatibility logic
;---------------------------------------------------------------

; in compat mode, this converts 8 bit patterns into shades of gray
Convert8BitPattern:
	ldx #8
	ldy #8
@1:	lsr
	bcc @2
	dey
@2:	dex
	bne @1
	cpy #8
	beq @3
	tya
	asl
	ora #16
	rts
@3:	lda #16+15
	rts
