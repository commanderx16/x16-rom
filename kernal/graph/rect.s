; Commander X16 KERNAL
;
; Graphics library: rectangles

.export GRAPH_draw_rect
.export GRAPH_draw_frame
.export GRAPH_move_rect

.segment "GRAPH"

;---------------------------------------------------------------
; GRAPH_draw_rect
;
; Pass:      r0   x1
;            r1   y1
;            r2   x2
;            r3   y2
;            N/C  0/x: draw (dispBufferOn)
;                 1/0: copy FG to BG (imprint)
;                 1/1: copy BG to FG (recover)
; Return:    draws the rectangle
;---------------------------------------------------------------
GRAPH_draw_rect:
	php
	; make sure y2 >= y1
	lda r3L
	cmp r1L
	bcs @a
	ldx r1L
	stx r3L
	sta r1L
@a:	plp

	bpl @0
	bcc ImprintRectangle
	bra RecoverRectangle

@0:	PushW r1
@1:	jsr HorizontalLine
	lda r1L
	inc r1L
	cmp r3L
	bne @1
	PopW r1
	rts

;---------------------------------------------------------------
; RecoverRectangle
;
; Pass:      r0   x1
;            r1   y1
;            r2   x2
;            r3   y2
;---------------------------------------------------------------
RecoverRectangle:
	PushW r1
@1:	jsr RecoverLine
	lda r1L
	inc r1L
	cmp r3L
	bne @1
	PopW r1
	rts

;---------------------------------------------------------------
; ImprintRectangle
;
; Pass:      r0   x1
;            r1   y1
;            r2   x2
;            r3   y2
;---------------------------------------------------------------
ImprintRectangle:
	PushW r1
@1:	jsr ImprintLine
	lda r1L
	inc r1L
	cmp r3L
	bne @1
	PopW r1
	rts

;---------------------------------------------------------------
; GRAPH_draw_frame
;
; Pass:      r0   x1
;            r1   y1
;            r2   x2
;            r3   y2
;---------------------------------------------------------------
GRAPH_draw_frame:
	jsr HorizontalLine
	PushB r1L
	MoveB r3L, r1L
	jsr HorizontalLine
	PopB r1L
	PushW r0
	jsr VerticalLine
	MoveW r2, r0
	jsr VerticalLine
	PopW r0
	rts

;---------------------------------------------------------------
; GRAPH_move_rect
;
; Pass:      r0   source x1
;            r1   source y1
;            r2   source x2
;            r3   source y2
;            r4   target x
;            r5   target y
;---------------------------------------------------------------
GRAPH_move_rect:
	; NYI
	brk
