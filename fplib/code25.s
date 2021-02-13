;----------------------------------------------------------------------
; Floating Point Library for 6502, polynomial evaluator; RNG
;----------------------------------------------------------------------
; (C)1978 Microsoft

			;
			;polynomial evaluator and the random number generator.
			;
			; evaluate p(x^2)*x
			; pointer to degree is in xreg.
			; the constants follow the degree.
			; for x=fac, compute:
			;  c0*x+c1*x^3+c2*x^5+c3*x^7+... +c(n)*x^(2*n+1)
			;
polyx
	sta polypt	;retain polynomial pointer for later.
	sty polypt+1
	jsr mov1f	;save fac in factmp.
	lda #tempf1
	jsr fmult	;compute x^2.
	jsr poly1	;compute p(x^2).
	lda #<tempf1
	ldy #>tempf1
	jmp fmult	;multiply by fac again.

			;
			;polynomial evaluator
			;
			; pointer to degree is in xreg.
			; compute:
			; c0+c1*x+c2*x^2+c3*x^3+c4*x^4...+c(n-1)*x^(n-1)+c(n)*x^n

poly
	sta polypt
	sty polypt+1
poly1
	jsr mov2f	;save fac.
	lda (polypt),y
	sta degree
	ldy polypt
	iny
	tya
	bne poly3
	inc polypt+1
poly3
	sta polypt
	ldy polypt+1
poly2
	jsr fmult
	lda polypt	;get current pointer.
	ldy polypt+1
	clc
	adc #4+addprc
	bcc poly4
	iny
poly4
	sta polypt
	sty polypt+1
	jsr fadd	;add in constant.
	lda #<tempf2	;multiply the original fac.
	ldy #>tempf2
	dec degree	;done?
	bne poly2
	rts		;yes.

rmulc	.byt $98,$35,$44,$7a,$00
raddc	.byt $68,$28,$b1,$46,$00

;    random number function.  rnd(x) where:
;      x=0 ==> generate a random number based on hardware clock
;      x<0 ==> seed a reproducable, pseudo-random number generator
;      x>0 ==> generate a reproducable pseudo-random # based on
;		seed value above.

rnd	pha
	jsr sign        ;preserves .X and .Y
rnd_0	bpl :+
	pla
	bra rnd1        ;<0: take argument as input for next random number
:	beq :+
	pla
	bra qsetnr      ;>0: take last random number as input
:                       ;=0: take entropy as input
	pla
	sta facho
	stx facmoh
	sty facmo
	sta faclo       ;least important bits: reuse
	jmp strnex

qsetnr	lda #<rndx		;get last one into fac.
	ldy #>rndx
	jsr movfm
	lda #<rmulc
	ldy #>rmulc		;fac was zero. restore last one
	jsr fmult		;multiply by random constant.
	lda #<raddc
	ldy #>raddc
	jsr fadd		;add random constant.

rnd1	ldx faclo
	lda facho
	sta faclo
	stx facho		;reverse hi and lo.
	ldx facmoh
	lda facmo
	sta facmoh
	stx facmo

strnex	lda #0			;make number positive.
	sta facsgn
	lda facexp		;put exp where it wil
	sta facov		;be shifted in by normal.
	lda #$80
	sta facexp		;make result between 0 and 1.
	jsr normal		;normalize.
	ldx #<rndx
	ldy #>rndx
gmovmf	jmp movmf		;put new one into memory.

;**************************
; routines moved from BASIC
;**************************

ayint	lda facexp
	cmp #144        ;fac .gt. 32767?
	bcc qintgo
	lda #<n32768    ;get address of -32768.
	ldy #>n32768
	jsr fcomp       ;see if fac=((x)).

	beq qintgo
gofuc	jmp fcerr	;no, fac is too big.

qintgo	jmp qint	;go to wint and shove it.

n32768	.byt 144,128,0,0,0

givayf2	sta facho
	sty facho+1
	ldx #144
	jmp floats

getadr2	lda facsgn
	bmi gofuc
;get signed 2 byte value in (y,a)
	lda facexp      ;examine exponent.
	cmp #145
	bcs gofuc       ;function call error.
	jsr qint        ;integerize it.
	lda facmo
	ldy facmo+1
	rts             ;it's all done.

;**************************
; generalized versions of
; what BASIC calls
;**************************

fmultt2 jsr prepare
	jmp fmultt      ;go multiply

fdivt2	jsr prepare
	jmp fdivt       ;go divide

fpwrt2	jsr prepare
	jmp fpwrt       ;go power

prepare	lda argsgn
	eor facsgn
	sta arisgn      ;resultant sign
	ldx facexp      ;set signs
	rts

