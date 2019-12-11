; Commander X16 KERNAL
;
; Graphics library
; (Bresenham code from GEOS by Berkeley Softworks)

.include "../../mac.inc"
.include "../../regs.inc"
.include "graph.inc"

.import leftMargin, windowTop, rightMargin, windowBottom
.import GRAPH_LL_VERA
.import I_GRAPH_LL_BASE

.import font_init
.import graph_init

.import GRAPH_LL_init
.import GRAPH_LL_get_info
.import GRAPH_LL_cursor_position
.import GRAPH_LL_get_pixel
.import GRAPH_LL_get_pixels
.import GRAPH_LL_set_pixel
.import GRAPH_LL_set_pixels
.import GRAPH_LL_set_8_pixels
.import GRAPH_LL_set_8_pixels_opaque
.import GRAPH_LL_fill_pixels
.import GRAPH_LL_filter_pixels
.import GRAPH_LL_move_pixels

.export GRAPH_init
.export GRAPH_clear
.export GRAPH_set_window
.export GRAPH_set_colors
.export GRAPH_draw_line
.export GRAPH_draw_rect
.export GRAPH_draw_frame
.export GRAPH_move_rect

.setcpu "65c02"

.segment "KVAR"

.export col1, col2, col_bg
col1:	.res 1
col2:	.res 1
col_bg:	.res 1

.segment "GRAPH"

;---------------------------------------------------------------
; GRAPH_init
;
;---------------------------------------------------------------
GRAPH_init:
	; copy VERA driver vectors
	ldx #13*2-1
:	lda GRAPH_LL_VERA,x
	sta I_GRAPH_LL_BASE,x
	dex
	bpl :-
	
	jsr GRAPH_LL_init

	LoadW r0, 0
	LoadW r1, 0
	LoadW r2, SC_PIX_WIDTH-1
	LoadW r3, SC_PIX_HEIGHT-1
	jsr GRAPH_set_window

	lda #0  ; primary:    black
	ldx #10 ; secondary:  gray
	ldy #1  ; background: white
	jsr GRAPH_set_colors

	jsr GRAPH_clear

	jmp font_init

;---------------------------------------------------------------
; GRAPH_clear
;
;---------------------------------------------------------------
GRAPH_clear:
	PushB col1
	MoveB col_bg, col1
	MoveW r0, leftMargin
	MoveW r1L, windowTop
	MoveW r2, rightMargin
	MoveW r3L, windowBottom
	jsr GRAPH_draw_rect
	PopB col1
	rts

;---------------------------------------------------------------
; GRAPH_set_window
;
; Pass:      r0     x1
;            r1     y1
;            r2     x2
;            r3     y2
;---------------------------------------------------------------
GRAPH_set_window:
	MoveW r0, leftMargin
	MoveB r1L, windowTop
	MoveW r2, rightMargin
	MoveB r3L, windowBottom
	rts

;---------------------------------------------------------------
; GRAPH_set_colors
;
; Pass:      a primary color
;            x secondary color
;            y background color
;---------------------------------------------------------------
GRAPH_set_colors:
	sta col1   ; primary color
	stx col2   ; secondary color
	sty col_bg ; background color
	rts

;---------------------------------------------------------------
; GRAPH_draw_line
;
; Pass:      r0       x1
;            r1       y2
;            r2       x1
;            r3       y2
;---------------------------------------------------------------
GRAPH_draw_line:
	CmpB r1L, r3L      ; horizontal?
	bne @0a            ; no
	jmp HorizontalLine

@0a:	CmpW r0, r2        ; vertical?
	bne @0             ; no
	jmp VerticalLine

; Bresenham
@0:	php
	LoadB r7H, 0
	lda r3L
	sub r1L
	sta r7L
	bcs @1
	lda #0
	sub r7L
	sta r7L
@1:	lda r2L
	sub r0L
	sta r12L
	lda r2H
	sbc r0H
	sta r12H
	ldx #r12
	jsr abs
	CmpW r12, r7
	bcs @2
	jmp @9
@2:
	lda r7L
	asl
	sta r9L
	lda r7H
	rol
	sta r9H
	lda r9L
	sub r12L
	sta r8L
	lda r9H
	sbc r12H
	sta r8H
	lda r7L
	sub r12L
	sta r10L
	lda r7H
	sbc r12H
	sta r10H
	asl r10L
	rol r10H
	LoadB r13L, $ff
	CmpW r0, r2
	bcc @4
	CmpB r1L, r3L
	bcc @3
	LoadB r13L, 1
@3:	ldy r0H
	ldx r0L
	MoveW r2, r0
	sty r2H
	stx r2L
	MoveB r3L, r1L
	bra @5
@4:	ldy r3L
	cpy r1L
	bcc @5
	LoadB r13L, 1
@5:	lda col1
	plp
	php
	jsr GRAPH_LL_cursor_position
	lda col1
	jsr GRAPH_LL_set_pixel
	CmpW r0, r2
	bcs @8
	inc r0L
	bne @6
	inc r0H
@6:	bbrf 7, r8H, @7
	AddW r9, r8
	bra @5
@7:	AddB_ r13L, r1L
	AddW r10, r8
	bra @5
@8:	plp
	rts
@9:	lda r12L
	asl
	sta r9L
	lda r12H
	rol
	sta r9H
	lda r9L
	sub r7L
	sta r8L
	lda r9H
	sbc r7H
	sta r8H
	lda r12L
	sub r7L
	sta r10L
	lda r12H
	sbc r7H
	sta r10H
	asl r10L
	rol r10H
	LoadW r13, $ffff
	CmpB r1L, r3L
	bcc @B
	CmpW r0, r2
	bcc @A
	LoadW r13, 1
@A:	MoveW r2, r0
	ldx r1L
	lda r3L
	sta r1L
	stx r3L
	bra @C
@B:	CmpW r0, r2
	bcs @C
	LoadW r13, 1
@C:	lda col1
	plp
	php
	jsr GRAPH_LL_cursor_position
	lda col1
	jsr GRAPH_LL_set_pixel
	CmpB r1L, r3L
	bcs @E
	inc r1L
	bbrf 7, r8H, @D
	AddW r9, r8
	bra @C
@D:	AddW r13, r0
	AddW r10, r8
	bra @C
@E:	plp
	rts

; calc abs of word in zp at location .x
abs:
	lda 1,x
	bmi @0
	rts
@0:	lda 1,x
	eor #$FF
	sta 1,x
	lda 0,x
	eor #$FF
	sta 0,x
	inc 0,x
	bne @1
	inc 1,x
@1:	rts

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

@2:	jsr GRAPH_LL_cursor_position

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

	jsr GRAPH_LL_cursor_position

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

;---------------------------------------------------------------
; GRAPH_draw_rect
;
; Pass:      r0   x1
;            r1   y1
;            r2   x2
;            r3   y2
; Return:    draws the rectangle
;---------------------------------------------------------------
GRAPH_draw_rect:
	; make sure y2 >= y1
	lda r3L
	cmp r1L
	bcs @a
	ldx r1L
	stx r3L
	sta r1L
@a:
	PushW r1
@1:	jsr HorizontalLine
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
	; GRAPH_LL_move_pixels
	brk
