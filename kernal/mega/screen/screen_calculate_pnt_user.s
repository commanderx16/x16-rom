; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; Set pointers PNT and USER to current screen line
;


screen_calculate_PNT_USER:

	ldx TBLX
	jmp screen_set_position
