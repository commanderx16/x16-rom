
.include "../regs.inc"
.include "../mac.inc"

.import screen_set_mode
.import GRAPH_put_char
.import GRAPH_move_rect
.import GRAPH_draw_rect
.import GRAPH_get_char_size
.import col1, col2

.import kbd_get, buf

.export console_init, console_put_char, console_get_char

.segment "KVAR"

px:	.res 2
py:	.res 2
style:	.res 1
bufptr:	.res 1

.segment "CONSOLE"

;---------------------------------------------------------------
; console_init
;
;---------------------------------------------------------------
console_init:
	lda #$00
	sta r6L
	lda #$05
	sta r6H
	stz r7L
	
	stz style
	stz buf
	stz bufptr

	lda #$80
	jsr screen_set_mode
	lda #147
; fallthrough

;---------------------------------------------------------------
; console_put_char
;
; Pass:      a   ASCII character
;            c   1: force flush
;---------------------------------------------------------------
console_put_char:
	bcs flush
	cmp #' '
	beq flush
	cmp #10
	beq flush
	
	ldy r7L
	sta (r6),y
	inc r7L
	rts
	
	
flush:
	pha

; measure word
	MoveW px, r3 ; start with x pos
	ldy #0
:	lda (r6),y
	phy
	ldx style
@aaaa1:	jsr GRAPH_get_char_size
	ply
	bcc @1    ; control character?
@aaaa2:	stx style ; yes: update style
	bra @2    ;      and don't add any width
@1:	stx r2L
	stz r2H
	AddW r2, r3 ; add width to x pos
@2:	iny
	cpy r7L
	bne :-
	
	CmpWI r3, 320
	bcc :+

	MoveW px, r0
	MoveW py, r1
	lda #10
	jsr GRAPH_put_char
	MoveW r0, px
	MoveW r1, py

:	CmpWI py, 200-9
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
	PushB col1
	PushB col2
	lda #1
	sta col1
	sta col2
	LoadW r0, 0
	LoadW r1, 200-SCROLL_AMOUNT
	LoadW r2, 320
	LoadW r3, SCROLL_AMOUNT
	LoadW r4, 0
	sec
	jsr GRAPH_draw_rect
	PopB col2
	PopB col1
:

	lda r7L
	beq @l1

	MoveW px, r0
	MoveW py, r1

	ldy #0
:	lda (r6),y
	phy
	jsr GRAPH_put_char
	ply
	iny
	cpy r7L
	bne :-

	stz r7L

@l1:	pla
	jsr GRAPH_put_char
	MoveW r0, px
	MoveW r1, py
	rts

;---------------------------------------------------------------
; console_get_char
;
; Return:    a   ASCII character
;---------------------------------------------------------------
console_get_char:
	lda buf
	bne @return_char

@input_line:
	MoveW px, r0
	MoveW py, r1

:	jsr kbd_get
	ldx bufptr
	sta buf,x
	inc bufptr
	pha
	sec
	jsr console_put_char
	pla
	cmp #13
	bne :-

	stz bufptr
	MoveW r0, px
	MoveW r1, py
	
@return_char:
	ldx bufptr
	lda buf,x
	bne :+
	stz bufptr
	stz buf
	bra @input_line
:	rts
