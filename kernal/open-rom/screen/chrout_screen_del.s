; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; CHROUT routine - screen support, DEL key handling
;


chrout_screen_DEL:

	; In insert mode it embeds control character
	ldx INSRT
	beq :+
	jmp chrout_screen_quote
:
	ldy PNTR
	beq chrout_screen_del_column_0
	cpy llen
	bne chrout_screen_del_column_normal

	; FALLTROUGH

chrout_screen_del_column_40:

	; First column of the extended line - decrement USER/PNT for copying

.if 0; XXX TODO
	lda USER+0
	bne :+
	dec USER+1
	dec PNT+1
:
	dec USER+0
	dec PNT+0
.endif

	; Copy characters
	ldx llen
	dex
	ldy #0

	jsr chrout_screen_del_copy_loop

	; Finish by moving the cursor left
	jmp chrout_screen_CRSR_LEFT

chrout_screen_del_column_normal:

	; We need to scroll back the rest of the logical line

	; First reduce PNTR to 0-39 range
	jsr screen_get_clipped_PNTR
	sty PNTR

	; Now get the offset to the last logical line character
	jsr screen_get_logical_line_end_ptr
	tya

	; Substract the PNTR value, this will tell us how many characters we need to move
	sec
	sbc PNTR
	tax

	; Perform the character copy (scroll back) in a loop
	ldy PNTR
	dey
	jsr chrout_screen_del_copy_loop

	dec PNTR

	; FALLTROUGH

chrout_screen_del_done:

	jmp chrout_screen_calc_lptr_done

chrout_screen_del_copy_loop:

	iny
	jsr screen_get_color
	dey
	jsr screen_set_color
	iny
	jsr screen_get_char
	dey
	jsr screen_set_char
	iny

	dex
	bpl chrout_screen_del_copy_loop

	; Clear char at end of line (just the character - not color!)
	lda #$20
	jsr screen_set_char

	rts

chrout_screen_del_column_0:

	ldy TBLX
	beq chrout_screen_del_done         ; delete from row 0, col 0 does nothing

	; Move cursor to end of previous line
	dec TBLX
	lda llen
	sta PNTR
	dec PNTR
	
	; Update PNT and USER pointers
	jsr screen_calculate_PNT_USER

	; Put space character at the current cursor position (do not clear the color!)
	ldy llen
	dey
	lda #$20
	jsr screen_set_char

	; Finish with recalculating all the variables
	bne chrout_screen_del_done
