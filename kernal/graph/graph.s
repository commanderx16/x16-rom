;----------------------------------------------------------------------
; Commander X16 KERNAL: Graphics library
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD
; (Bresenham code based on GEOS by Berkeley Softworks)

.include "mac.inc"
.include "regs.inc"
.include "fb.inc"

.import leftMargin, windowTop, rightMargin, windowBottom
.import FB_VERA

.import font_init

.export GRAPH_init
.export GRAPH_clear
.export GRAPH_set_window
.export GRAPH_set_colors
.export GRAPH_draw_line
.export GRAPH_draw_rect
.export GRAPH_draw_image
.export GRAPH_move_rect
.export GRAPH_draw_oval

.segment "GDRVVEC"

.export I_FB_init, I_FB_get_info, I_FB_set_palette, I_FB_cursor_position, I_FB_cursor_next_line, I_FB_get_pixel, I_FB_get_pixels, I_FB_set_pixel, I_FB_set_pixels, I_FB_set_8_pixels, I_FB_set_8_pixels_opaque, I_FB_fill_pixels, I_FB_filter_pixels, I_FB_move_pixels; [vectors]

I_FB_BASE:
I_FB_init:
	.res 2
I_FB_get_info:
	.res 2
I_FB_set_palette:
	.res 2
I_FB_cursor_position:
	.res 2
I_FB_cursor_next_line:
	.res 2
I_FB_get_pixel:
	.res 2
I_FB_get_pixels:
	.res 2
I_FB_set_pixel:
	.res 2
I_FB_set_pixels:
	.res 2
I_FB_set_8_pixels:
	.res 2
I_FB_set_8_pixels_opaque:
	.res 2
I_FB_fill_pixels:
	.res 2
I_FB_filter_pixels:
	.res 2
I_FB_move_pixels:
	.res 2
I_FB_END:


.segment "KVAR"

.export col1, col2, col_bg
col1:	.res 1
col2:	.res 1
col_bg:	.res 1

.segment "GRAPH"

;---------------------------------------------------------------
; GRAPH_init
;
; Function:  Enable a given low-level graphics mode driver,
;            and switch to this mode.
;
; Pass:      r0     pointer to FB_* driver vectors
;                   If 0, this enables the default driver
;                   (320x240@256c).
;---------------------------------------------------------------
GRAPH_init:
	lda r0L
	ora r0H
	bne :+
	LoadW r0, FB_VERA
:
	; copy VERA driver vectors
	ldy #<(I_FB_END - I_FB_BASE - 1)
:	lda (r0),y
	sta I_FB_BASE,y
	dey
	bpl :-

	jsr FB_init

	jsr set_window_fullscreen

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
	PushB col2
	lda col_bg
	sta col1
	sta col2
	MoveW leftMargin, r0
	MoveB windowTop, r1L
	stz r1H
	MoveW rightMargin, r2
	SubW r0, r2
	IncW r2
	MoveB windowBottom, r3L
	stz r3H
	SubW r1, r3
	IncW r3
	sec
	jsr GRAPH_draw_rect
	PopB col2
	PopB col1
	rts

set_window_fullscreen:
	jsr FB_get_info
	MoveW r0, r2
	MoveW r1, r3
	lda #0
	sta r0L
	sta r0H
	sta r1L
	sta r1H
; fallthrough

;---------------------------------------------------------------
; GRAPH_set_window
;
; Pass:      r0     x
;            r1     y
;            r2     width
;            r3     height
;
; Note: 0/0/0/0 will set the window to full screen.
;---------------------------------------------------------------
GRAPH_set_window:
	lda r0L
	ora r0H
	ora r1L
	ora r1H
	ora r2L
	ora r2H
	ora r3L
	ora r3H
	beq set_window_fullscreen

	MoveW r0, leftMargin
	MoveW r1, windowTop

	lda r0L
	clc
	adc r2L
	sta rightMargin
	lda r0H
	adc r2H
	sta rightMargin+1
	lda rightMargin
	bne :+
	dec rightMargin+1
:	dec rightMargin

	lda r1L
	clc
	adc r3L
	sta windowBottom
	lda r1H
	adc r3H
	sta windowBottom+1
	lda windowBottom
	bne :+
	dec windowBottom+1
:	dec windowBottom
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
	CmpW r1, r3        ; horizontal?
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
	jsr FB_cursor_position
	lda col1
	jsr FB_set_pixel
	CmpW r0, r2
	bcs @8
	inc r0L
	bne @6
	inc r0H
@6:	bbrf 7, r8H, @7
	AddW r9, r8
	bra @5
@7:	AddB r13L, r1L
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
	jsr FB_cursor_position
	lda col1
	jsr FB_set_pixel
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
; HorizontalLine (internal)
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

@2:	jsr FB_cursor_position

	MoveW r2, r15
	SubW r0, r15
	IncW r15

	PushW r0
	PushW r1
	MoveW r15, r0
	LoadW r1, 0
	lda col1
	jsr FB_fill_pixels
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; VerticalLine (internal)
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

	jsr FB_cursor_position

	PushW r0
	PushW r1
	LoadW r1, 320
	stx r0L
	stz r0H
	lda col1
	jsr FB_fill_pixels
	PopW r1
	PopW r0
@2:	rts

;---------------------------------------------------------------
; GRAPH_draw_rect
;
; Pass:      r0   x
;            r1   y
;            r2   width
;            r3   height
;            r4   corner radius [TODO]
;            c    1: fill
;---------------------------------------------------------------
GRAPH_draw_rect:
; check for empty
	php
	lda r2L
	ora r2H
	bne @0
@4:	plp
	rts
@0:	lda r3L
	ora r3H
	beq @4
	plp

	bcc @3

; fill
	PushW r1
	PushW r3
	jsr FB_cursor_position

@1:	PushW r0
	PushW r1
	MoveW r2, r0
	LoadW r1, 0
	lda col2
	jsr FB_fill_pixels
	PopW r1
	PopW r0

	jsr FB_cursor_next_line

	lda r3L
	bne @2
	dec r3H
@2:	dec r3L
	lda r3L
	ora r3H
	bne @1

	PopW r3
	PopW r1

; frame
@3:
	PushW r2
	PushW r3
	AddW r0, r2
	lda r2L
	bne :+
	dec r2H
:	dec r2L
	AddW r1, r3
	lda r3L
	bne :+
	dec r3H
:	dec r3L

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

	PopW r3
	PopW r2
	rts

;---------------------------------------------------------------
; GRAPH_draw_image
;
; Pass:      r0   x
;            r1   y
;            r2   image pointer
;            r3   width
;            r4   height
;---------------------------------------------------------------
GRAPH_draw_image:
	PushW r0
	PushW r1
	PushW r4
	jsr FB_cursor_position

	MoveW r2, r0
	MoveW r3, r1
@1:	jsr FB_set_pixels

	lda r4L
	bne :+
	dec r4H
:	dec r4L

	AddW r3, r0 ; update pointer
	jsr FB_cursor_next_line

	lda r4L
	ora r4H
	bne @1

	PopW r4
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; GRAPH_move_rect
;
; Pass:      r0   source x
;            r1   source y
;            r2   target x
;            r3   target y
;            r4   width
;            r5   height
;---------------------------------------------------------------
GRAPH_move_rect:
	CmpW r3, r1
	bcc @2

	AddW r5, r1
	AddW r5, r3
	IncW r5
@1:	jsr FB_move_pixels
	DecW_ r1
	DecW_ r3
	DecW_ r5
	lda r5L
	ora r5H
	bne @1
	rts

@2:	jsr FB_move_pixels
	IncW r1 ; sy
	IncW r3 ; ty
	DecW_ r5
	lda r5L
	ora r5H
	bne @2
	rts

;---------------------------------------------------------------
; GRAPH_draw_oval
;
;---------------------------------------------------------------
GRAPH_draw_oval:
	brk; NYI
