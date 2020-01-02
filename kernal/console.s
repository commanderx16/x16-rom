
.include "../regs.inc"
.include "../mac.inc"
.include "../io.inc"
.include "../banks.inc"

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

.segment "KVARSB0"

bufsize  = 80

outbuf:	.res 80
inbuf:	.res bufsize+1 ; (+ trailing CR)

inbufidx:
	.res 1
style:
	.res 1
baseline:
	.res 1

px:	.res 2
py:	.res 2

.segment "CONSOLE"

;---------------------------------------------------------------
; console_init
;
;---------------------------------------------------------------
console_init:
	KVARS_START

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
	stz inbufidx

	lda #$80
	jsr screen_set_mode
	lda #147
	sec
	jsr console_put_char

	KVARS_END
	rts

; fallthrough

;---------------------------------------------------------------
; console_put_char
;
; Pass:      a   ASCII character
;            c   1: force flush
;---------------------------------------------------------------
console_put_char:
	KVARS_START

	bcs flush
	cmp #' '
	beq flush
	cmp #10
	beq flush
	cmp #13
	beq flush

	ldy r7L
	sta (r6),y
	inc r7L

	KVARS_END
	rts
	
flush:
	pha

; measure word
	lda r7L
	beq @no_x_overflow
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
	bcc @no_x_overflow

	MoveW px, r0
	MoveW py, r1
	lda #13
	jsr GRAPH_put_char
	MoveW r0, px
	MoveW r1, py

@no_x_overflow:
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
	LoadW r0, 0
	LoadW r1, 200-SCROLL_AMOUNT
	LoadW r2, 320
	LoadW r3, SCROLL_AMOUNT
	LoadW r4, 0
	jsr white_rect

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

	KVARS_END
	rts

;---------------------------------------------------------------
; console_get_char
;
; Return:    a   ASCII character
;---------------------------------------------------------------
console_get_char:
	KVARS_START

	lda inbuf
	beq @input_line
	jmp @return_char

@input_line:

; get height + baseline
	ldx #0
	lda #' '
	jsr GRAPH_get_char_size
	sta baseline

; create sprite
	tya     ; character height
	inc     ; cursor is 1 pixel higher
	asl
	sta r0L ; cursor height * 2

	; color map
	ldx #32
:	stz inbuf,x     ; 0: black, 1: white
	dex
	bpl :-
	; transparency map
	ldx #0
	lda #%10000000; 0: transparent, 1: opaque
:	sta inbuf+32,x
	inx
	stz inbuf+32,x
	inx
	cpx r0L
	bne :-
@l1:	cpx #32
	bcs @s2
	stz inbuf+32,x
	inx
	bra @l1
@s2:	LoadW r0, inbuf
	LoadW r1, inbuf+32
	LoadB r2L, 1 ; 1 bpp
	ldx #16      ; width
	ldy #16      ; height
	lda #1       ; sprite 1
	sec          ; apply mask
	jsr sprite_set_image

@input_loop:
	MoveW px, r0
	MoveW py, r1

; position cursor
	PushW r0
	PushW r1
	IncW r0
	lda r1L
	sec
	sbc baseline
	sta r1L
	lda r1H
	sbc #0
	sta r1H
	lda #1
	jsr sprite_set_position
	PopW r1
	PopW r0

; N.B.: We're accepting both PETSCII control codes (CR, DEL)
;       and ASCII control codes (LF, BS), so this would work
;       with both kinds of input drivers.
@again:	jsr kbd_get
	beq @again
	cmp #8   ; ASCII BACKSPACE
	beq @b2
	cmp #$14 ; PETSCII DELETE
	bne :+
@b2:	jmp @backspace
:	cmp #13
	beq @input_end
	cmp #$20
	bcc @again
	cmp #$80
	bcc @ok
	cmp #$a0
	bcc @again
@ok:	ldx inbufidx
	cpx #bufsize
	beq @again
	pha
	jsr GRAPH_put_char
	MoveW r0, px
	MoveW r1, py
	pla
	bcs @again ; out of bounds, didn't print
	ldx inbufidx
	sta inbuf,x
	inc inbufidx
	jmp @input_loop

@input_end:
	ldx inbufidx
	sta inbuf,x ; store CR
	stz inbufidx

	sec
	jsr console_put_char ; print CR

@return_char:
	ldx inbufidx
	lda inbuf,x
	cmp #13
	bne :+
	stz inbufidx
	stz inbuf
	bra @end
:	inc inbufidx

@end:	KVARS_END
	rts

; Tipp-Ex
@backspace:
	ldx inbufidx
	bne :+
	jmp @again ; empty buffer
:
	PushW r0
	PushW r1

	; kill character
	dex
	stx inbufidx
	
	; character to delete
	lda inbuf,x

	; r2 = width
	ldx #0
	jsr GRAPH_get_char_size
	stx r2L
	stz r2H

	; r3 = height
	sty r3L
	stz r3H

	; r0 = r0 - width
	lda r0L
	sec
	sbc r2L
	sta r0L
	lda r0H
	sbc #0
	sta r0H
	
	; r1 = r1 - baseline
	lda r1L
	sec
	sbc baseline
	sta r1L
	lda r1H
	sbc #0
	sta r1H

	jsr white_rect

	PopW r1
	PopW r0
	
	; r0 = r0 - width
	SubW r2, r0
	
	MoveW r0, px
	MoveW r1, py

	jmp @input_loop

white_rect:
	PushB col1
	PushB col2
	lda #1
	sta col1
	sta col2
	sec
	jsr GRAPH_draw_rect
	PopB col2
	PopB col1
	rts
