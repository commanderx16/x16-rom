; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; Sets PNTR in a proper range (0-39 or 40-79)
; Sets LNMX to 39 or 79
;


screen_calculate_PNTR_LNMX:

	ldy TBLX
	lda LDTBL, y
	php
	jsr screen_get_clipped_PNTR
	plp
	bmi screen_calculate_PNTR_0_39

	; FALLTROUGH

screen_calculate_PNTR_40_79:

	tya
	clc
	adc llen
	tay

	; FALLTROUGH

screen_calculate_PNTR_0_39:

	sty PNTR

	; FALLTROUGH

screen_calculate_LNMX:

	ldy TBLX
	lda LDTBL, y
	bpl screen_calculate_lnmx_79       ; this line is a continuation

	cpy nlinesm1
	beq screen_calculate_lnmx_39       ; this is the last line, which is not a continuation

	iny
	lda LDTBL, y
	bpl screen_calculate_lnmx_79       ; line is continued

	; FALLTROUGH

screen_calculate_lnmx_39:

	lda llen
	bne l9

	; FALLTROUGH

screen_calculate_lnmx_79:

	asl
l9:
	sta LNMX
	dec LNMX
	rts
