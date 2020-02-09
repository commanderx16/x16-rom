; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; Print the hex value in .A as two digits
;

print_hex_byte:

	; Idea by Haubitze

	sed
	pha
	lsr
	lsr
	lsr
	lsr
	cmp #$0A
	adc #$30
	cld
	jsr JCHROUT
	sed
	pla
	and #$0F
	cmp #$0A
	adc #$30
	cld
	jmp JCHROUT
