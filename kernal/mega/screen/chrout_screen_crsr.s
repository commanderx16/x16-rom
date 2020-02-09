; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; Cursor keys handling within CHROUT
;


chrout_screen_CRSR_UP:

	lda TBLX
	beq chrout_screen_CRSR_done
	dec TBLX

	; FALLTROUGH

chrout_screen_CRSR_done:

	jmp chrout_screen_calc_lptr_done


chrout_screen_CRSR_DOWN:

	lda TBLX
	cmp nlinesm1
	bne :+
	jsr screen_scroll_up
:
	inc TBLX
	jmp chrout_screen_calc_lptr_done


chrout_screen_CRSR_RIGHT:

	jsr screen_get_clipped_PNTR
	iny
	cpy llen
	beq_16 screen_advance_to_next_line
	
l8:
	sty PNTR
	bpl chrout_screen_CRSR_done        ; branch always


chrout_screen_CRSR_LEFT:

	jsr screen_get_clipped_PNTR
	dey
	bpl l8

	lda TBLX
	beq chrout_screen_CRSR_done

	dec TBLX
	lda llen
	sta PNTR
	dec PNTR
	bne chrout_screen_CRSR_done        ; branch always
