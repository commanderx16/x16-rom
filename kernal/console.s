
.include "../regs.inc"
.include "../mac.inc"

.import screen_set_mode
.import GRAPH_put_char
.import GRAPH_move_rect
.import GRAPH_draw_rect
.import GRAPH_get_char_size
.import col1, col2

.import kbd_get

.import sprite_set_image, sprite_set_position

bsout = $ffd2

.export console_init, console_put_char, console_get_char

.segment "KVAR"

px:	.res 2
py:	.res 2
style:	.res 1
inbufptr:
	.res 1

outbuf   = $0500
baseline = $0600
inbuf    = $0700
bufsize  = 255

.segment "CONSOLE"

;---------------------------------------------------------------
; console_init
;
;---------------------------------------------------------------
console_init:
	lda #$0f ; ISO mode
	jsr bsout

	lda #<outbuf
	sta r6L
	lda #>outbuf
	sta r6H
	stz r7L
	
	stz style
	stz inbuf
	stz inbuf
	stz inbufptr

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
	jsr GRAPH_get_char_size
	ply
	bcc @1    ; control character?
	stx style ; yes: update style
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
	lda inbuf
	beq @input_line
	jmp @return_char

@input_line:

; create sprite
	; get height + baseline
	ldx #0
	lda #' '
	jsr GRAPH_get_char_size
	inc ; XXX
;	inc ; XXX
	sta baseline
	stz baseline+1
	tya     ; height
	asl
	inc ; XXX
	inc ; XXX
	sta r0L ; height * 2

	ldx #32
:	stz inbuf,x     ; 0: black, 1: white
	dex
	bpl :-
	ldx #0
	lda #%10000000; 0: transparent, 1: opaque
:	sta inbuf+32,x
	inx
	stz inbuf+32,x
	inx
	cpx r0L
	bne :-
@l:	cpx #32
	bcs :+
	stz inbuf+32,x
	inx
	bra @l
	
:

	LoadW r0, inbuf
	LoadW r1, inbuf+32
	LoadB r2L, 1 ; 1 bpp
	ldx #16      ; width
	ldy #16      ; height
	lda #1       ; sprite 0
	sec          ; apply mask
	jsr sprite_set_image


	lda #$92 ; attribute reset
	jsr console_put_char

@input_loop:
	MoveW px, r0
	MoveW py, r1

	PushW r0
	PushW r1
	IncW r0
	SubW baseline, r1 ; XXX baseline
	lda #1
	jsr sprite_set_position
	PopW r1
	PopW r0

:	jsr kbd_get
	beq :-
	ldx inbufptr
	cpx #bufsize
	beq :+
	sta inbuf,x
	inc inbufptr
	pha
	sec
	jsr console_put_char
	pla
:	cmp #13
	bne @input_loop

	stz inbufptr

@return_char:
	ldx inbufptr
	lda inbuf,x
	bne :+
	stz inbufptr
	stz inbuf
	jmp @input_line
:	inc inbufptr
	rts
