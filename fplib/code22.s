;----------------------------------------------------------------------
; Floating Point Library for 6502
;----------------------------------------------------------------------
; (C)1978 Microsoft

n0999	.byt $9b,$3e,$bc,$1f,$fd
n9999	.byt $9e,$6e,$6b,$27,$fd
nmil	.byt $9e,$6e,$6b,$28,$00

fout
	ldy #1
foutc
	lda #' '	;if positive, print space
	bit facsgn
	bpl fout1
	lda #'-'	;if neg
fout1
	sta fbuffr-1,y	;store the character.
	sta facsgn	;make fac pos for qint.
	sty fbufpt	;save for later
	iny
	lda #'0'	;get zero to type if fac = 0
	ldx facexp
	bne *+5
	jmp fout19

	lda #0
	cpx #$80	;is number < 1?
	beq fout37	;no
	bcs fout7
fout37
	lda #<nmil	;mult by 10~6
	ldy #>nmil
	jsr fmult
	lda #$f7
fout7
	sta deccnt	;save count or zero it.
fout4
	lda #<n9999
	ldy #>n9999
	jsr fcomp	;is number .gt. 999999.499?
			;or 999999999.5?
	beq bigges
	bpl fout9	;yes, make it smaller.
fout3
	lda #<n0999
	ldy #>n0999
	jsr fcomp	;is number .gt.99999,9499?
			;or 99999999.90625?
	beq fout38
	bpl fout5	;yes. done multiplying.
fout38
	jsr mul10	;make it bigger.
	dec deccnt
	bne fout3	;see if taht does it.
fout9			;this always goes.
	jsr div10	;make it smaller.
	inc deccnt
	bne fout4	;see if that does it.
fout5			;this always goes.
	jsr faddh	;add a half to round up.
bigges
	jsr qint
	ldx #1		;decimal point count.
	lda deccnt
	clc
	adc #$0a	;should number be printed in E notation?
			;(ie, is number .lt. .01?)
	bmi foutpi	;yes.
	cmp #$0b	;is it .gt. 999999 (9999999999)?
	bcs fout6	;yes, use E notation.
	adc #$ff	;number of palces before decimal point.
	tax		;put into accx.
	lda #2		;no E notation.
foutpi
	sec
fout6
	sbc #2		;effectively add 5 to orig exp.
	sta tenexp	;that is the exponent to print.
	stx deccnt	;number of decimal places.
	txa
	beq fout39
	bpl fout8	;some places before dec pnt.
fout39
	ldy fbufpt	;get pointer to output.
	lda #'.'	;put in "."
	iny
	sta fbuffr-1,y
	txa
	beq fout16
	lda #'0'	;get the ensuing zero.
	iny
	sta fbuffr-1,y
fout16
	sty fbufpt	;save it for later.
fout8
	ldy #0
foutim
	ldx #$80	;first pass through ,accb has msb set.
fout2
	lda faclo
	clc
	adc foutbl+3,y
	sta faclo
	lda facmo
	adc foutbl+2,y
	sta facmo
	lda facmoh
	adc foutbl+1,y
	sta facmoh
	lda facho
	adc foutbl,y
	sta facho
	inx		;it was done yet another time.
	bcs fout41
	bpl fout2
	bmi fout40

fout41
	bmi fout2
fout40
	txa
	bcc foutyp	;can use acca as is.
	eor #$ff	;find 11.(a).
	adc #$0a	;c is still on to complete negation.
			;and will always be on after.
foutyp
	adc #$2f	;get a character to print.
	iny
	iny
	iny
	iny
	sty fdecpt
	ldy fbufpt
	iny		;point to place to store output.
	tax
	and #$7f	;get rid of msb.
	sta fbuffr-1,y
	dec deccnt
	bne stxbuf	;not time for dp yet.
	lda #'.'
	iny
	sta fbuffr-1,y	;store dp.
stxbuf
	sty fbufpt	;store pointer for later.
	ldy fdecpt
	txa		;complement accb.
	eor #$ff	;complement acca.
	and #$80	;save only msb.
	tax
	cpy #fdcend-foutbl
	bne fout2	;continue with output.
fouldy
	ldy fbufpt      ;get back output pointer.
fout11
	lda fbuffr-1,y	;remove trailing blanks.
	dey
	cmp #'0'
	beq fout11
	cmp #'.'
	beq fout12	;run into dp. stop.
	iny		;something else, save it.
fout12
	lda #'+'
	ldx tenexp
	beq fout17	;no exponent to output.
	bpl fout14
	lda #0
	sec
	sbc tenexp
	tax

