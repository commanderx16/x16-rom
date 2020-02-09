; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE


screen_grow_logical_line_done_scroll:

	inc TBLX

	; FALLTROUGH

screen_grow_logical_line_done:

	jmp screen_calculate_PNT_USER


screen_grow_logical_line_screen_up:

	jsr screen_scroll_up

	; FALLTROUGH


screen_grow_logical_line:

	; Do not grow line if previus one is grown
	ldy TBLX
	lda LDTBL+0, y
	bpl screen_grow_logical_line_done_scroll

	; If last line, scroll the screen up
	cpy nlinesm1
	beq screen_grow_logical_line_screen_up

	; Do not grow line if already grown
	lda LDTBL+1, y
	bpl screen_grow_logical_line_done
	
	; Scroll LDTBL down (start from the end)
	ldy nlinesm1
	dey
:
	cpy TBLX
	beq :+
	bcc :+

	lda LDTBL+0, y
	sta LDTBL+1, y

	dey
	bne :-
:
	; Mark current line as grown
	ldy TBLX
	lda #$00
	sta LDTBL+1, y

	; Now we have to scroll lines downwards to make space. We start from the end,
	; and work backwards. We cannot be as simple and efficient here as we are
	; for scrolling up, because we do not know how much must be scrolled.

	; Work out how many physical lines to scroll down

	lda nlinesm1
	clc ; subtract one more
	sbc TBLX
	beq screen_grow_logical_line_copy_done       ; branch if no need to copyy

	ldx nlinesm1
:	jsr screen_set_position
	dex
	jsr screen_copy_line
	cpx TBLX
	bne :-

screen_grow_logical_line_copy_done:

	; Erase newly inserted line and quit

	ldx TBLX
	inx
	jsr screen_clear_line
	jmp screen_calculate_PNTR_LNMX
