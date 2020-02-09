; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; Get PNTR value clipped to 0-39 range in .Y, sets flags to compare with 0, can trash .A
;

screen_get_clipped_PNTR:

	ldy PNTR
	cpy llen
	bcc :+
	tya
	sbc llen
	tay
:
	cpy #$00
	rts
