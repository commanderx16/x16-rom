; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; GFX/TXT mode switch handling within CHROUT
;


chrout_screen_GFX:
	lda #2
	bne chrout_screen_set_charset

chrout_screen_TXT:
	lda #3
chrout_screen_set_charset:
	jsr screen_set_charset
	jmp chrout_screen_done
