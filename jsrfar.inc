; LONG CALL  utility
;
; jsr jsrfar
; .word address
; .byte bank

	php             ;save registers & status
	pha
	phx
	phy

        tsx
	lda $105,x      ;return address lo
	sta imparm
	clc
	adc #3
	sta $105,x      ;and write back with 3 added
	lda $106,x      ;return address hi
	sta imparm+1
	adc #0
	sta $106,x

	ldy #1
	lda (imparm),y  ;target address lo
	sta jmpfr+1
	iny
	lda (imparm),y  ;target address hi
	sta jmpfr+2
	cmp #$c0
	bcc jsrfar1     ;target is in RAM
; target is in ROM
	lda #<jsrfar4
	sta jmpbk+1
	lda #>jsrfar4
	sta jmpbk+2
	lda d1prb
	sta jsrbnk+1
	iny
	lda (imparm),y  ;target address bank
	and #$07
	ply             ;restore registers
	plx
	jmp jsrfar3

jsrfar4:
	pla
	plp
	rts


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
	lda $0103,x
	sta d1pra       ;restore RAM bank
jsrfar2:
	plx
	pla
	plp
	plp
	rts
