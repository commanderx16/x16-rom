; Commander X16 KERNAL
;
; Graphics library: line drawing fastpaths

.setcpu "65c02"

.segment "GRAPH"

;---------------------------------------------------------------
; HorizontalLine
;
; Pass:      r0   x position of first pixel
;            r1   y position
;            r2   x position of last pixel
;---------------------------------------------------------------
HorizontalLine:
	; make sure x2 > x1
	lda r2L
	sec
	sbc r0L
	lda r2H
	sbc r0H
	bcs @2
	lda r0L
	ldx r2L
	stx r0L
	sta r2L
	lda r0H
	ldx r2H
	stx r0H
	sta r2H

@2:	jsr GRAPH_LL_set_ptr

	MoveW r2, r15
	SubW r0, r15
	IncW r15

	PushW r0
	PushW r1
	MoveW r15, r0
	LoadW r1, 0
	lda col1
	jsr GRAPH_LL_fill_pixels
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; VerticalLine
;
; Pass:      r0   x
;            r1   y1
;            r2   (unused)
;            r3   y2
;            a    color
;---------------------------------------------------------------
VerticalLine:
	; make sure y2 >= y1
	lda r3L
	cmp r1L
	bcs @0
	ldx r1L
	stx r3L
	sta r1L

@0:	lda r3L
	sec
	sbc r1L
	tax
	inx
	beq @2 ; .x = number of pixels to draw

	jsr GRAPH_LL_set_ptr

	PushW r0
	PushW r1
	LoadW r1, 320
	stx r0L
	stz r0H
	lda col1
	jsr GRAPH_LL_fill_pixels
	PopW r1
	PopW r0
@2:	rts
