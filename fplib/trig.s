;----------------------------------------------------------------------
; Floating Point Library for 6502: Trigonometric functions
;----------------------------------------------------------------------
; (C)1978 Microsoft

			;
			;sine, cosine, and tangent functions.
			;
			;cosine function
			;use cos(x)=sin(x+pi/2)
cos
	lda #<pi2	;pointer to pi/2
	ldy #>pi2
	jsr fadd	;add it in. fall into sine.
			;
			;sine function.
			;
			;use identities to get fac in quadrants I or IV.
			;the fac is divided by 2*pi and the integer part
			;is ignored because sin(x+2*pi)=sin(x). then the
			;argument can be compared with pi/2 by comparing
			;the result of the division with pi/2(2*pi)=1/4.
			;identities are then used to get the result in
			;quadrants I or IV. an approximation polynomial
			;is then used  to compute sin(x).
			;
sin
	jsr movaf
	lda #<twopi	;get pointer to divisor.
	ldy #>twopi
	ldx argsgn	;geet sign of result.
	jsr fdivf
	jsr movaf	;get result into arg.
	jsr int		;integerize fac.
	lda #0
	sta arisgn	;always have the same sign.
	jsr fsubt	;keep only the fractional part.
	lda #<fr4	;get pointer to 1/4.
	ldy #>fr4
	jsr fsub
	lda facsgn	;save sign for later.
	pha
	bpl sin1	;first quadrant.
	jsr faddh	;add 1/2 to fac.
	lda facsgn	;sign is negative?
	bmi sin2
	lda tansgn	;quads II and III come here.
	eor #$ff
	sta tansgn
sin1
	jsr negop	;if positive, negate it.
sin2
	lda #<fr4	;pointer to 1/4.
	ldy #>fr4
	jsr fadd	;add it in.
	pla		;get original quadrant.
	bpl sin3
	jsr negop	;if negative, negate result.
sin3
	lda #<sincon
	ldy #>sincon
	jmp polyx	;do approximation polyomial


			; tangent function.
tan
	jsr mov1f	;move fac into temporary.
	lda #0
	sta tansgn	;remember whether to negate.
	jsr sin		;compute the sin.
	ldx #<tempf3
	ldy #>tempf3
	jsr movmf	;put sign into other temp.
	lda #<tempf1
	ldy #>tempf1
	jsr movfm	;put this memory location into fac.
	lda #0
	sta facsgn	;start off positive.
	lda tansgn
	jsr cosc	;compute cosine.
	lda #<tempf3
	ldy #>tempf3	;address of sine value.
	jmp fdiv	;divide sine by cosine and return.

cosc
	pha
	jmp sin1

pi2	.byt $81,$49,$0f,$da,$a2

twopi	.byt $83,$49,$0f,$da,$a2

fr4	.byt $7f,$00,$00,$00,$00

sincon	.byt 5	;degree-1.
	.byt $84,$e6,$1a,$2d,$1b
	.byt $86,$28,$07,$fb,$f8
	.byt $87,$99,$68,$89,$01
	.byt $87,$23,$35,$df,$e1
	.byt $86,$a5,$5d,$e7,$28
	.byt $83,$49,$0f,$da,$a2

			;
			;arctangent function
			;
			;use identities to get arg between 0 and 1 and then use
			;an approximation polynomial to compute arctan(x).
			;
atn
	lda facsgn	;what is sign?
	pha		;save for later.
	bpl atn1
	jsr negop	;if negative, negate fac.
atn1			;use arctan(x)=-arctan(-x).
	lda facexp
	pha		;save this too for later.
	cmp #$81	;see if fac .ge. 1.0.
	bcc atn2	;it is less than 1
	lda #<fone	;get pntr to 1.0.
	ldy #>fone
	jsr fdiv	;compute reciprocal.
atn2			;use aectan(x)=pi/2-arctan(1/x).
	lda #<atncon	;pointer to arctan constants.
	ldy #>atncon
	jsr polyx
	pla
	cmp #$81	;was original argument .lt.1?
	bcc atn3	;yes.
	lda #<pi2
	ldy #>pi2
	jsr fsub	;subtract arctan from pi/2.
atn3
	pla		;was original aurgument positive?
	bpl atn4	;yes.
	jmp negop	;if negative, negate result.

atn4	rts		;all done.

atncon	.byt $0b			;degree-1.
	.byt $76,$b3,$83,$bd,$d3
	.byt $79,$1e,$f4,$a6,$f5
	.byt $7b,$83,$fc,$b0,$10
	.byt $7c,$0c,$1f,$67,$ca
	.byt $7c,$de,$53,$cb,$c1
	.byt $7d,$14,$64,$70,$4c
	.byt $7d,$b7,$ea,$51,$7a
	.byt $7d,$63,$30,$88,$7e
	.byt $7e,$92,$44,$99,$3a
	.byt $7e,$4c,$cc,$91,$c7
	.byt $7f,$aa,$aa,$aa,$13
	.byt $81,0,0,0,0

