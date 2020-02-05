; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; SHIFT ON/OFF handling within CHROUT
;


chrout_screen_SHIFT_ON:

	lda #$00 ; enable SHIFT+VENDOR combination
l4:
	sta MODE
	jmp chrout_screen_done

chrout_screen_SHIFT_OFF:

	lda #$80 ; disable SHIFT+VENDOR combination
	bne l4   ; branch always
