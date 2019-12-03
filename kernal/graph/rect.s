; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: rectangles

.global k_Rectangle
.global k_FrameRectangle

.segment "GRAPH"

;---------------------------------------------------------------
; Rectangle
;
; Pass:      N/C      0x: draw (dispBufferOn)
;                     10: copy FG to BG (imprint)
;                     11: copy BG to FG (recover)
;            r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    draws the rectangle
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
k_Rectangle:
	bpl @0
	bcc ImprintRectangle
	bra RecoverRectangle

@0:	MoveB r2L, r11L
@1:	jsr HorizontalLine
	lda r11L
	inc r11L
	cmp r2H
	bne @1
	rts

;---------------------------------------------------------------
; RecoverRectangle
;
; Pass:      r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    rectangle recovered from backscreen
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
RecoverRectangle:
	MoveB r2L, r11L
@1:	jsr RecoverLine
	lda r11L
	inc r11L
	cmp r2H
	bne @1
	rts

;---------------------------------------------------------------
; ImprintRectangle
;
; Pass:      r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    r2L, r3H unchanged
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
ImprintRectangle:
	MoveB r2L, r11L
@1:	jsr ImprintLine
	lda r11L
	inc r11L
	cmp r2H
	bne @1
	rts

;---------------------------------------------------------------
; FrameRectangle
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
