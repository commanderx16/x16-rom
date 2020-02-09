; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; Print one of the standard Kernal messages, index in .X
;

l1:
	jsr JCHROUT
	inx

print_kernal_message:

	lda __msg_kernal_first, x
	bpl l1 ; 0 marks end of string
	and #$7F
	jmp JCHROUT
