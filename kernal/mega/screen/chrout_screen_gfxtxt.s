; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; GFX/TXT mode switch handling within CHROUT
;


chrout_screen_GFX:

.if 0
	lda VIC_YMCSB
	and #$02 ; to upper case
!:
	sta VIC_YMCSB
.else
	; MIST
.endif
	jmp chrout_screen_done

chrout_screen_TXT:

	lda VIC_YMCSB
	ora #$02    ; to lower case
	bne !-      ; branch always
