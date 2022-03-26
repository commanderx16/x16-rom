;----------------------------------------------------------------------
; Floating Point Library for 6502
;----------------------------------------------------------------------
; (C)1978 Microsoft

	lda #'-'	;exponent is negative.
fout14
	sta fbuffr+1,y	;store sign of exponent.
	lda #'E'
	sta fbuffr,y	;store the "e" character.
	txa
	ldx #$2f
	sec
fout15
	inx		;move closer to output value.
	sbc #$0a	;subtract 10.
	bcs fout15	;not negative yet.
	adc #$3a	;get second output character.
	sta fbuffr+3,y	;store high digit.
	txa
	sta fbuffr+2,y	;store low digit.
	lda #0		;put in terminator.
	sta fbuffr+4,y
	beq fout20	;return, (always branches).
fout19
	sta fbuffr-1,y	;store the character.
fout17
	lda #0		;a terminator.
	sta fbuffr,y
fout20
	lda #<fbuffr
	ldy #>fbuffr
	rts		;all done.

				;1/2
fhalf	.byt $80,$00
zero	.byt $00,$00,$00

foutbl				;powers of 10
	.byt $fa,$0a,$1f,$00	;-100,000,000
	.byt $00,$98,$96,$80	;  10,000,000
	.byt $ff,$f0,$bd,$c0	;  -1,000,000
	.byt $00,$01,$86,$a0	;     100,000
	.byt $ff,$ff,$d8,$f0	;     -10,000
	.byt $00,$00,$03,$e8	;       1,000
	.byt $ff,$ff,$ff,$9c	;        -100
	.byt $00,$00,$00,$0a	;          10
	.byt $ff,$ff,$ff,$ff	;          -1
fdcend

			;exponentiation --- x^y.
			;n.b. 0^0=1
			;first check if y=0. if so, the result is one.
			;next check if x=0. if so the result is zero.
			;then check if x>0. if not check that y is an integer.
			;if so, negate x, so that lg doesn't give fcerr.
			;if x is negative and y is odd, negate the result
			;returned by exp.
			;to compute the result use x^y=exp((y*log(x)).

fpwrt
	beq exp		;if fac=0, just exponentiate taht.
	lda argexp	;is x=0?
	bne fpwrt1
	jmp zerof1	;zero fac.

fpwrt1
	ldx #<tempf3	;save it for later in a temp.
	ldy #>tempf3
	jsr movmf
			;y=0 already. good; in case no one calls int.
	lda argsgn
	bpl fpwr1	;no problems if x>0.
	jsr int		;integerize the fac.
	lda #<tempf3	;get addr of comperand.
	ldy #>tempf3
	jsr fcomp	;equal?
	bne fpwr1	;leave x neg. log will blow him out.
			;a=-1 and y is irrelavant.
	tya		;negative x. make positive.
	ldy integr	;get evenness.
fpwr1
	jsr movfa1	;alternate entry point
	tya
	pha		;save evenness for later.
	jsr log	        ;find log
	lda #<tempf3	;multiply fac times log(x).
	ldy #>tempf3
	jsr fmult
	jsr exp		;exponentiate the fac.
	pla
	lsr a		;is it even?
	bcc negrts	;yes. or x>0.
			;negate the number in fac.
negop
	lda facexp
	beq negrts
	lda facsgn
	eor #$ff
	sta facsgn
negrts
	rts

