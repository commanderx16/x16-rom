; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; RVS ON/OFF handling within CHROUT
;


chrout_screen_RVS_ON:

	lda #$80
	bne l7 ; branch always

chrout_screen_RVS_OFF:

	lda #$00
l7:
	sta RVS
	jmp chrout_screen_done
