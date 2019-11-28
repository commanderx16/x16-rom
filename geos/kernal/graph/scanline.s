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
.import k_GetScanLine
.import k_DrawLine
.import k_FrameRectangle
.import k_InvertRectangle
.import k_Rectangle
.import k_TestPoint
.import k_InvertLine
.import k_SetVRAMPtrFG
.import k_SetVRAMPtrBG
.import k_SetPointFG
.import k_SetPointBG

.export _GetScanLine, _DrawLine, _DrawPoint, _FrameRectangle, _ImprintRectangle, _InvertRectangle, _RecoverRectangle, _Rectangle, _TestPoint, _HorizontalLine, _InvertLine, _RecoverLine, _VerticalLine, _SetVRAMPtrFG, _SetVRAMPtrBG, _SetPointFG, _SetPointBG

.import k_dispBufferOn, k_col1, k_col2

.macro jsrfar addr
	jsr gjsrfar
	.word addr
	.byte BANK_KERNAL
.endmacro

_GetScanLine:
	php
	sei
	jsrfar k_GetScanLine
	plp
	rts

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
	php
	MoveB dispBufferOn, k_dispBufferOn
	plp
	bmi @3 ; recover
; draw
	lda #0
	rol
	eor #1
	sta k_col1
	bra @2 ; N=0 -> draw
@3:	sec ; N=1, C=1 -> recover
@2:	php
	sei
	jsrfar k_DrawLine
	plp
	rts


;---------------------------------------------------------------
; DrawPoint                                               $C133
;
; Pass:      r3       x pos of point (0-319)
;            r11L     y pos of point (0-199)
;            carryFlg color: 1: black; 0: white
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
	pha

	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
; set point
	ldx r11L
	jsr _SetVRAMPtrFG
	pla
	jsr _SetPointFG
	pha

@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK

	ldx r11L
	jsr _SetVRAMPtrBG
	pla
	jmp _SetPointBG

@2:	pla
	rts

; recover a point: use DrawLine
@3:	PushW r4
	PushB r11H
	MoveW r3, r4
	MoveB r11L, r11H
	jsr _DrawLine
	PopB r11H
	PopW r4
	rts

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
	MoveB dispBufferOn, k_dispBufferOn
	php
	sei
	jsrfar k_FrameRectangle
	plp
	rts

;---------------------------------------------------------------
; ImprintRectangle                                        $C250
;
; Pass:      r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    r2L, r3H unchanged
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_ImprintRectangle:
	php
	sei
	lda #$ff
	clc
	jsrfar k_Rectangle
	plp
	rts

;---------------------------------------------------------------
; InvertRectangle                                         $C12A
;
; Pass:      r2L top in scanlines (0-199)
;            r2H bottom in scanlines (0-199)
;            r3  left in pixels (0-319)
;            r4  right in pixels (0-319)
; Return:    r2L, r3H unchanged
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
_InvertRectangle:
	MoveB dispBufferOn, k_dispBufferOn
	php
	sei
	jsrfar k_InvertRectangle
	plp
	rts

;---------------------------------------------------------------
; RecoverRectangle                                        $C12D
;
; Pass:      r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    rectangle recovered from backscreen
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_RecoverRectangle:
	php
	sei
	lda #$ff
	sec
	jsrfar k_Rectangle
	plp
	rts

;---------------------------------------------------------------
; Rectangle                                               $C124
;
; Pass:      r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    draws the rectangle
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_Rectangle:
	MoveB dispBufferOn, k_dispBufferOn
	MoveB col1, k_col1
	php
	sei
	lda #0 ; N=0 -> draw
	jsrfar k_Rectangle
	plp
	rts

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
	PushW r3
	PushW r4
	PushW r11
	MoveB r11L, r11H
	MoveB dispBufferOn, k_dispBufferOn
	php
	sei
	lda #0 ; N=0 -> draw
	jsrfar k_DrawLine
	plp
	PopW r11
	PopW r4
	PopW r3
	rts

;---------------------------------------------------------------
; InvertLine                                              $C11B
;
; Pass:      r3   x pos of left endpoint (0-319)
;            r4   x pos of right endpoint (0-319)
;            r11L y pos (0-199)
; Return:    r3-r4 unchanged
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
_InvertLine:
	MoveB dispBufferOn, k_dispBufferOn
	php
	sei
	jsrfar k_InvertLine
	plp
	rts

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

	php
	sei
	lda #$ff
	sec      ; N=1, C=1 -> recover
	jsrfar k_DrawLine
	plp

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
	PushW r3
	MoveW r3, r11
	MoveW r4, r3

	MoveB dispBufferOn, k_dispBufferOn
	php
	sei
	lda #0 ; N=0 -> draw
	jsrfar k_DrawLine
	plp

	PopW r3
	rts

_SetVRAMPtrFG:
	php
	sei
	jsrfar k_SetVRAMPtrFG
	plp
	rts

_SetVRAMPtrBG:
	php
	sei
	jsrfar k_SetVRAMPtrBG
	plp
	rts

_SetPointFG:
	php
	sei
	jsrfar k_SetPointFG
	plp
	rts

_SetPointBG:
	php
	sei
	jsrfar k_SetPointBG
	plp
	rts

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
	sta k_col1
	rts
@3:	lda #16+15
	sta k_col1
	rts
