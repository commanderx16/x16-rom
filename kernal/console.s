
.include "../regs.inc"
.include "../mac.inc"

.import screen_set_mode
.import GRAPH_put_char
.import GRAPH_move_rect
.import GRAPH_draw_rect
.import GRAPH_set_colors

.export console_init
.export console_print_char

.segment "KVAR"

px:	.res 2
py:	.res 2

.segment "CONSOLE"

console_init:
	lda #$80
	jsr screen_set_mode
	lda #147
; fallthrough

console_print_char:
	pha

	CmpWI py, 200-9
	bcc :+

; scroll
SCROLL_AMOUNT=20
	LoadW r0, 0
	LoadW r1, SCROLL_AMOUNT
	LoadW r2, 0
	LoadW r3, 0
	LoadW r4, 320
	LoadW r5, 200-SCROLL_AMOUNT
	jsr GRAPH_move_rect
	SubVW SCROLL_AMOUNT, py
; fill
	lda #1
	tax
	tay
	jsr GRAPH_set_colors
	LoadW r0, 0
	LoadW r1, 200-SCROLL_AMOUNT
	LoadW r2, 320
	LoadW r3, SCROLL_AMOUNT
	LoadW r4, 0
	sec
	jsr GRAPH_draw_rect
	lda #0
	tax
	tay
	jsr GRAPH_set_colors
:

;	ldx #0
;	jsr GRAPH_get_char_size

	MoveW px, r0
	MoveW py, r1
	
	CmpWI r0, 300
	bcc :+
	
; line break
	lda #10
	jsr GRAPH_put_char
	
:	pla
	jsr GRAPH_put_char
	MoveW r0, px
	MoveW r1, py
	rts
