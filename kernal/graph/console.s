;----------------------------------------------------------------------
; Console Library
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "regs.inc"
.include "mac.inc"
.include "io.inc"
.include "banks.inc"

.import GRAPH_set_window
.import GRAPH_put_char
.import GRAPH_move_rect
.import GRAPH_draw_rect
.import GRAPH_get_char_size
.import GRAPH_draw_image
.import col1, col2, col_bg
.import leftMargin, windowTop, rightMargin, windowBottom
.import currentMode

.import kbdbuf_get

.import sprite_set_image, sprite_set_position

bsout = $ffd2

LF=10
CR=13

.export console_init, console_put_char, console_get_char, console_put_image, console_set_paging_message

.segment "KVARSB0"

bufsize  = 80

; XXX outbuf may run into inbuf, but there is no check yet
; XXX whether it overruns that one
outbuf:	.res 80
inbuf:	.res bufsize+1 ; (+ trailing CR)

outbufidx:
	.res 1
inbufidx:
	.res 1
baseline:
	.res 1
override_height:
	.res 2

px:	.res 2
py:	.res 2

height_counter:
	.res 2

pause_text_ptr:
	.res 2

.segment "CONSOLE"

;---------------------------------------------------------------
; console_init
;
; Function:  Initializes the console.
;---------------------------------------------------------------
console_init:
	KVARS_START_TRASH_A_NZ

	jsr GRAPH_set_window

	lda #$0f ; ISO mode
	jsr bsout

	stz outbufidx
	stz inbuf
	stz inbufidx
	stz override_height
	stz override_height+1

	LoadW r0, 0
	jsr console_set_paging_message

	lda #147 ; clear screen
	clc
	jsr console_put_char
	lda #$92 ; attribute reset
	clc
	jsr console_put_char

	KVARS_END_TRASH_A_NZ
	rts

;---------------------------------------------------------------
; console_set_paging_message
;
; Function:  Sets the paging message or disables paging.
;
; Pass:      r0  pointer to pause text
;
; Note:      If r0 is NULL, paging will be disabled.
;---------------------------------------------------------------
console_set_paging_message:
	KVARS_START_TRASH_A_NZ

	MoveW r0, pause_text_ptr

	stz height_counter
	stz height_counter+1

	KVARS_END_TRASH_A_NZ
	rts

; The paging message API isn't as flexible as I wanted it
; originally, but a more flexible API would have had
; problems that I couldn't find a solution for.
;
; The original idea was to return C=1 as soon as we're at
; the beginning of the new line that overflowed the page,
; so that the user can print a message, wait for a key etc.
;
; But if a word wraps and causes a newline that overflows
; the page, we can't print it yet, otherwise we would have a
; new line (overflowing the page) with a single word. We
; have to keep the word in the buffer and return to the user.
; But then the user can't print anything, because there are
; still characters in the buffer that would be flushed. So
; we would have to special case printing while the user
; is printing the "press any key" message - and we wouldn't
; know when this is finished, and new characters are actual
; text again.
;
; We would know that if we didn't return a flag, but instead
; called the user back on a page overflow, but the problem
; with the non-empty buffer and lots of special casing would
; persist.
;
; It becomes even more complicated if it's a line feed that
; is triggering the flush, and the flushed word causes another
; line break. That's two line breaks in one put_character
; call...
;
; So I think the existing solution is okay. :)

;---------------------------------------------------------------
; console_put_char
;
; Function:  Prints a character to the console.
;
; Pass:      a   ASCII character
;            c   0: character wrapping, 1: word wrapping
;
; Note:      If C is 1, the text will be word-wrapped. For this,
;            characters will be buffered until a SPACE, CR or LF
;            character is printed. So to flush the buffer at the
;            end, make sure to print SPACE, CR or LF.
;            If C is 0, character wrapping and therefore no
;            buffering is performed.
;---------------------------------------------------------------
; XXX * update override_height at least once every time the font
; XXX   is changed
console_put_char:
	KVARS_START_TRASH_X_NZ

	php
	cmp #CR
	bne :+
; We convert CR into an "clear attributes" + LF here, so we
; don't have to distinguish between CR and LF later.
	lda #$92 ; clear attributes
	jsr console_put_char
	lda #LF
:
	; store into buffer
	ldy outbufidx
	sta outbuf,y
	inc outbufidx

	plp
	bcc @flush ; .C=1 always flushes
	cmp #' '   ; and so do SPACE/LF/CR
	beq @flush
	cmp #LF
	beq @flush
	cmp #CR
	beq @flush

	clc        ; did not reach page end

	KVARS_END_TRASH_X_NZ
	rts

@flush:
	PushW r0
	PushW r1
; measure buffer
	MoveW px, r0 ; start with x pos
	ldy #0
:	lda outbuf,y
	cmp #' '
	beq @2       ; don't count space
	phy
	ldx currentMode
	jsr GRAPH_get_char_size
	ply
	bcc @1    ; control character?
	bra @2    ;      and don't add any width
@1:	stx r1L
	stz r1H
	AddW r1, r0 ; add width to x pos
@2:	iny
	cpy outbufidx
	bne :-

	MoveW rightMargin, r1
	IncW r1
	CmpW r0, r1
	bcc @no_x_overflow

	MoveW px, r0
	MoveW py, r1

	jsr new_line_scroll
	bra @3

@no_x_overflow:

; print buffer
	MoveW px, r0
	MoveW py, r1

@3:	lda outbufidx
	beq @l1

	ldy #0
:	lda outbuf,y
	phy
	jsr put_char
	ply
	iny
	cpy outbufidx
	bne :-

	stz outbufidx

@l1:
	MoveW r0, px
	MoveW r1, py

	PopW r1
	PopW r0

	KVARS_END_TRASH_X_NZ
	rts

put_char:
	cmp #LF
	beq new_line_scroll
	cmp #CR
	beq new_line_scroll
	pha
	jsr GRAPH_put_char
	bcs @wrap          ; did not fit, new line!
	pla
	rts
@wrap:
; character wrapping
	jsr new_line_scroll
	pla
	jmp GRAPH_put_char ; try again

; new line and scroll if necessary
new_line_scroll:
	; override_height = MAX(override_height, font_height+1)
	jsr get_font_size
	iny
	tya
	pha
	sec
	sbc override_height
	lda #0
	sbc override_height+1
	bcc @0 ; font is higher -> regular newline
	sty override_height
	stz override_height+1
@0:
	PushW r1
	lda #LF
	jsr GRAPH_put_char
	PopW r1
	AddW override_height, r1
	AddW override_height, height_counter

	stz override_height
	stz override_height+1

	; height_counter > windowBottom - windowTop - 4 * (font_height+1)
	MoveW windowBottom, r13
	SubW windowTop, r13
	pla ; font_height+1
	stz r12H
	asl
	rol r12H
	asl
	rol r12H
	sta r12L ; *4
	SubW r12, r13

	CmpW height_counter, r13
	bcc :+
	stz height_counter
	stz height_counter+1

	jsr paging_pause

:
	MoveW r0, px
	MoveW r1, py
	jsr @1
	MoveW px, r0
	MoveW py, r1
	rts
@1:
	jsr get_font_size
	iny
	sty r14L
	stz r14H ; font height + 1
	; fallthrough

scroll_if_necessary: ; required height in r14
	MoveW windowBottom, r15
	SubW r14, r15
	CmpW py, r15
	bcs :+
	rts

:	PushW r2

	MoveW r14, r6
	AddVW 2, r6 ; scrollAmount = font height + 2

; scroll
	; source x = leftMargin
	MoveW leftMargin, r0
	; source y = windowTop + scrollAmount
	AddW3 windowTop, r6, r1
	; target x = leftMargin
	MoveW leftMargin, r2
	; target y = windowTop
	MoveW windowTop, r3
	; width = rightMargin - leftMargin + 1
	MoveW rightMargin, r4
	SubW leftMargin, r4
	IncW r4
	PushW r4 ; we need it again later
	; height = windowBottom - windowTop - scrollAmount + 1
	MoveW windowBottom, r5
	SubW windowTop, r5
	SubW r6, r5
	IncW r5
	jsr GRAPH_move_rect

; fill
	; x = leftMargin
	MoveW leftMargin, r0
	; y = windowBottom - scrollAmount + 1
	MoveW windowBottom, r1
	SubW r6, r1
	IncW r1
	; width = rightMargin - leftMargin + 1
	PopW r2 ; take result from before
	; height = scrollAmount
	MoveW r6, r3
	; corner radius
	LoadW r4, 0

	PushB col1
	PushB col2
	lda col_bg  ; draw with bg color
	sta col1
	sta col2
	sec
	jsr GRAPH_draw_rect
	PopB col2
	PopB col1

	SubW r6, py

	PopW r2
	rts

paging_pause:
	lda pause_text_ptr
	ora pause_text_ptr+1
	bne :+
	rts
:
	PushB col1
	PushB col2

	PushW r0
	PushW r1
	PushW r2
	PushW r3
	PushW r4

	MoveW pause_text_ptr, r15

	PushB currentMode
	LoadB currentMode, 0
	ldy #0
:	lda (r15),y
	beq :+
	phy
	jsr put_char
	ply
	iny
	bne :-
:	PopB currentMode

:	jsr kbdbuf_get
	beq :-

	; clear text


	; width = px - leftMargin
	MoveW r0, r2
	SubW leftMargin, r2

	; x = leftMargin
	MoveW leftMargin, r0
	IncW r0;XXX

	; y = py - baseline
	jsr get_font_size
	sta baseline
	lda r1L
	sec
	sbc baseline
	sta r1L
	bcs :+
	dec baseline+1
:
	; height = font_height
	iny
	tya
	sta r3L
	stz r3H

	; cornerRadius = 0
	stz r4L
	stz r4H

	lda col_bg
	sta col1
	sta col2

	sec
	jsr GRAPH_draw_rect

	PopW r4
	PopW r3
	PopW r2
	PopW r1
	PopW r0
	MoveW leftMargin, r0

	PopB col2
	PopB col1

	rts

;---------------------------------------------------------------
; console_put_image
;
; Function:  Draw an image in GRAPH_draw_image format at the
;            current cursor position and advance the cursor.
;
; Pass:      r0   image pointer
;            r1   width
;            r2   height
;---------------------------------------------------------------
console_put_image:
	KVARS_START_TRASH_A_NZ

	AddW3 px, r1, r15
	DecW_ r15
	CmpW r15, rightMargin
	bcc @l1
	beq @l1

	lda #LF
	jsr console_put_char

@l1:
	lda #0
	clc
	jsr console_put_char ; force flush

	MoveW r2, r14
	PushW r0
	PushW r1
	jsr scroll_if_necessary
	PopW r1
	PopW r0

	MoveW r2, override_height

	MoveW r2, r4
	MoveW r1, r3
	MoveW r0, r2
	MoveW px, r0
	MoveW py, r1

	; get baseline
	jsr get_font_size
	sta r5L

	; subtract baseline
	lda r1L
	sec
	sbc r5L
	sta r1L
	bcs :+
	dec r1H
:
	jsr GRAPH_draw_image

	AddW r3, px ; advance cursor by image width

	KVARS_END_TRASH_A_NZ
	rts

get_font_size:
	ldx #0
	lda #' '
	jsr GRAPH_get_char_size
	rts

;---------------------------------------------------------------
; console_get_char
;
; Return:    a   ASCII character
;
; Note: This function returns a character from the keyboard.
;       It will buffer characters until a CR or LF is received
;       and then return the buffer character by character.
;       The last character to be sent is a CR code.
;       Editing the buffer allows deleting the last character
;       using BS/DEL, but no cursor movement or other control
;       characters.
;---------------------------------------------------------------
console_get_char:
	KVARS_START_TRASH_X_NZ

	lda inbuf
	beq @input_line
	jmp @return_char

@input_line:
	lda #$92 ; attribute reset
	clc
	jsr console_put_char

; get height + baseline
	jsr get_font_size
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
@again:	jsr kbdbuf_get
	beq @again
	cmp #8   ; ASCII BACKSPACE
	beq @b2
	cmp #$14 ; PETSCII DELETE
	bne :+
@b2:	jmp @backspace
:	cmp #LF
	beq @input_end
	cmp #CR
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
	lda #CR
	sta inbuf,x ; store CR
	stz inbufidx

	clc
	jsr console_put_char ; print CR

	; disable cursor
	LoadB r0H, $ff
	lda #1
	jsr sprite_set_position

@return_char:
	ldx inbufidx
	lda inbuf,x
	cmp #CR
	bne :+
	stz inbufidx
	stz inbuf
	bra @end
:	inc inbufidx

@end:	KVARS_END_TRASH_X_NZ
	and #$ff
	rts

; Tipp-Ex
@backspace:
	ldx inbufidx
	bne :+
	jmp @again ; empty buffer
:
	; kill character
	dex
	stx inbufidx

	; character to delete
	lda inbuf,x
	pha

	; r2L = width
	ldx #0
	jsr GRAPH_get_char_size
	stx r2L

	; r0 = r0 - width
	lda r0L
	sec
	sbc r2L
	sta r0L
	lda r0H
	sbc #0
	sta r0H

	plx ; character
	PushW r0
	PushB col1
	lda col_bg
	sta col1
	txa
	jsr GRAPH_put_char
	PopB col1
	PopW r0

	MoveW r0, px
	MoveW r1, py

	jmp @input_loop
