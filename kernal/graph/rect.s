; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: rectangles

.include "../../regs.inc"
.include "../../io.inc"
.include "../../mac.inc"

.import k_col1

.import HorizontalLine
.import k_InvertLine
.import RecoverLine
.import VerticalLine
.import k_ImprintLine

.global k_Rectangle
.global k_InvertRectangle
.global k_RecoverRectangle
.global k_ImprintRectangle
.global k_FrameRectangle

.segment "GRAPH"

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
k_Rectangle:
	MoveB r2L, r11L
@1:	jsr HorizontalLine
	lda r11L
	inc r11L
	cmp r2H
	bne @1
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
k_InvertRectangle:
	MoveB r2L, r11L
@1:	jsr k_InvertLine
	lda r11L
	inc r11L
	cmp r2H
	bne @1
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
k_RecoverRectangle:
	MoveB r2L, r11L
@1:	jsr RecoverLine
	lda r11L
	inc r11L
	cmp r2H
	bne @1
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
k_ImprintRectangle:
	MoveB r2L, r11L
@1:	jsr k_ImprintLine
	lda r11L
	inc r11L
	cmp r2H
	bne @1
	rts

;---------------------------------------------------------------
; FrameRectangle                                          $C127
;
; Pass:      r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    r2L, r3H unchanged
; Destroyed: a, x, y, r5 - r9, r11
;---------------------------------------------------------------
k_FrameRectangle:
	ldy r2L
	sty r11L
	jsr HorizontalLine
	MoveB r2H, r11L
	jsr HorizontalLine
	PushW r3
	PushW r4
	MoveW r3, r4
	MoveW r2, r3
	jsr VerticalLine
	PopW r4
	jsr VerticalLine
	PopW r3
	rts
