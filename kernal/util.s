
	.segment "UTIL"

; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;     *** print immediate ***
;  a jsr to this routine is followed by an immediate ascii string,
;  terminated by a $00. the immediate string must not be longer
;  than 255 characters including the terminator.

primm
	pha             ;save registers
	txa
	pha
	tya
	pha
	ldy #0

@1	tsx             ;increment return address on stack
	inc $104,x      ;and make imparm = return address
	bne @2
	inc $105,x
@2	lda $104,x
	sta imparm
	lda $105,x
	sta imparm+1

	lda (imparm),y  ;fetch character to print (*** always system bank ***)
	beq @3          ;null= eol
	jsr bsout       ;print the character
	bcc @1

@3	pla             ;restore registers
	tay
	pla
	tax
	pla
	rts             ;return

;---------------------------------------------------------------
; ieee_read_status
;
; Function:  Retrieve IEEE device status string.
;
; Pass:      x/y  string address
;
; Return:    a    string length
;
; Notes:     The string is zero-terminated and does not contain
;            the terminating CR sent by the device.
;---------------------------------------------------------------
ieee_read_status:
	stx tmp2
	sty tmp2+1
	lda #8;fa
	jsr talk
	lda #$6f
	jsr tksa
	ldy #0
@loop:	jsr acptr
	cmp #13
	bne :+
	lda #0
:	sta (tmp2),y
	beq :+
	iny
	bne @loop
:	jsr untlk
	tya
	rts
