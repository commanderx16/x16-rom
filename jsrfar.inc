; LONG CALL  utility
;
; jsr jsrfar
; .word address
; .byte bank

	pha             ;reserve 1 byte on the stack
	php             ;save registers & status
	pha
	phx
	phy

        tsx
	lda $106,x      ;return address lo
	sta imparm
	clc
	adc #3
	sta $106,x      ;and write back with 3 added
	lda $107,x      ;return address hi
	sta imparm+1
	adc #0
	sta $107,x

	ldy #1
	lda (imparm),y  ;target address lo
	sta jmpfr+1
	iny
	lda (imparm),y  ;target address hi
	sta jmpfr+2
	cmp #$c0
	bcc jsrfar1     ;target is in RAM
; target is in ROM
	lda d1prb
	sta $0105,x     ;save original bank into reserved byte
	iny
	lda (imparm),y  ;target address bank
	and #$07
	ply             ;restore registers
	plx
	jmp jsrfar3

; target is in RAM
jsrfar1:
	lda d1pra
	sta $0105,x     ;save original bank into reserved byte
	iny
	lda (imparm),y  ;target address bank
	sta d1pra       ;set RAM bank
	ply             ;restore registers
	plx
	pla
	plp
	jsr jmpfr
	php
	pha
	phx
	tsx
	lda $0104,x
	sta d1pra       ;restore RAM bank
jsrfar2:
	plx
	pla
	plp
	plp
	rts
