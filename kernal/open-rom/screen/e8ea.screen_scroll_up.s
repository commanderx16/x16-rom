; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; Scroll the whole screen up by 1 logical line, described in:
;
; - [CM64] Computes Mapping the Commodore 64 - page 218
;


screen_scroll_up:

	; Check if CTRL key pressed - if so, perform a delay

	lda SHFLAG
	and #KEY_FLAG_CTRL
	beq screen_scroll_up_delay_done

	ldy #$09
:
	ldx #$FF
	jsr wait_x_bars
	dey
	bne :-

	; FALLTROUGH

screen_scroll_up_delay_done: ; entry point for cursor move control codes

	; Scroll the LDTBL (line link table)

	ldy #$00
:
	lda LDTBL+1, y
	sta LDTBL+0, y
	iny
	cpy nlinesm1
	bne :-

	lda #$80
	sta LDTBL+24

	ldx #0
:	jsr screen_set_position
	inx
	jsr screen_copy_line
	cpx nlinesm1
	bne :-

	; Clear the newly introduced line

	ldx nlinesm1
	jsr screen_clear_line

	; Decrement the current physical line number

	dec TBLX

	; If the first line is linked, scroll once more

	bit LDTBL+0
	bpl screen_scroll_up

 	; Recalculate PNT and USER

	jmp screen_calculate_PNT_USER
