;-----------------------------------------------------------------------------
; text_input.s
; Copyright (C) 2020 Frank van den Hoef
;-----------------------------------------------------------------------------

	.include "text_input.inc"
	.include "lib.inc"
	.include "text_display.inc"
	.include "usb.inc"
	.include "keycodes.inc"

	.code

;-----------------------------------------------------------------------------
; getchar
;-----------------------------------------------------------------------------
getchar:
	jsr usb_getkey
	bcc getchar
	rts

;-----------------------------------------------------------------------------
; getline
;-----------------------------------------------------------------------------
getline:
	stz line_len
	stz line_idx

@next_char:
	jsr getchar

	cmp #KEY_ENTER
	beq @enter
	cmp #KEY_BACKSPACE
	beq @backspace
	cmp #' '
	bcc @next_char	; Don't accept characters below ' '

	ldx line_len
	cpx #MAX_LINE_LEN
	beq @next_char

	sta line_buf, x
	inc line_len

	jsr putchar

	bra @next_char

@backspace:
	ldx line_len
	beq @next_char
	dec line_len
	jsr putchar
	bra @next_char

@enter:	jsr putchar

	; Zero terminate line_buf
	ldx line_len
	stz line_buf, x
	rts

;-----------------------------------------------------------------------------
; split_line
;
; Rewrite line_buf. Remove extra spaces.
; Replace whitespace by zero terminations.
;-----------------------------------------------------------------------------
split_line:
	ldx #0
	ldy #0

	; Skip spaces
@skip_spaces:
	lda line_buf, x
	cmp #' '
	bne @copy_chars
	inx
	bra @skip_spaces

	; Copy chars up to space or zero-termination
@copy_chars:
	lda line_buf, x
	cmp #' '
	beq @copy_chars_done
	sta line_buf, y
	inx
	iny
	cmp #0
	beq @done
	bne @copy_chars
@copy_chars_done:
	lda #0
	sta line_buf, y
	inx
	iny
	bra @skip_spaces

@done:	lda #0
	sta line_buf, y

	rts

;-----------------------------------------------------------------------------
; to_upper
;-----------------------------------------------------------------------------
to_upper:
	; Lower case character?
	cmp #'a'
	bcc @done
	cmp #'z'+1
	bcs @done

	; Make uppercase
	and #$DF
@done:	rts

;-----------------------------------------------------------------------------
; to_lower
;-----------------------------------------------------------------------------
to_lower:
	; Lower case character?
	cmp #'A'
	bcc @done
	cmp #'Z'+1
	bcs @done

	; Make lowercase
	ora #$20
@done:	rts

;-----------------------------------------------------------------------------
; next_line_part
;-----------------------------------------------------------------------------
next_line_part:
	; At end of line buffer?
	ldx line_idx
	lda line_buf, x
	bne @1
	clc
	rts
@1:
	; Find next zero-termination
@2:	lda line_buf, x
	inx
	cmp #0
	bne @2
	stx line_idx

	sec
	rts
