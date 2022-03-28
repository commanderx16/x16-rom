;----------------------------------------------------------------------
; Floating Point Library for 6502: Log, Division
;----------------------------------------------------------------------
; (C)1978 Microsoft

; Natural log function
;
; Calculation is by:
;	ln(f*2^n)=(n+log2(f))*ln(2)
; An approximation polynomial is used to calculate log2(f).

; Constants used by log :

fone	.byt $81,$00,$00,$00,$00	;1.0

logcn2	.byt 3				;degree-1
	.byt $7f,$5e,$56,$cb,$79	;0.43425594188
	.byt $80,$13,$9b,$0b,$64	;0.57658454134
	.byt $80,$76,$38,$93,$16	;0.96180075921
	.byt $82,$38,$aa,$3b,$20	;2.8853900728

sqr05	.byt $80,$35,$04,$f3,$34	;0.707106781	sqr(0.5)
sqr20	.byt $81,$35,$04,$f3,$34	;1.41421356	sqr(2.0)
neghlf	.byt $80,$80,$00,$00,$00	;-0.50
log2	.byt $80,$31,$72,$17,$f8	;0.693147181	ln(2)

log	jsr sign	;is it positive?
	beq logerr
	bpl log1
logerr	jmp fcerr	;can't tolerate neg or zero.

log1	lda facexp	;get exponent into acca.
	sbc #$7f	;remove bias. (carry is off).
	pha		;save a while.
	lda #$80
	sta facexp	;result is fac in range (0.5,1).
	lda #<sqr05	;get pointer to sqr(0.5).
	ldy #>sqr05
	jsr fadd
	lda #<sqr20
	ldy #>sqr20
	jsr fdiv
	lda #<fone
	ldy #>fone
	jsr fsub
	lda #<logcn2
	ldy #>logcn2
	jsr polyx	;evaluate approximation polynomial.
	lda #<neghlf	;add in last constant.
	ldy #>neghlf
	jsr fadd
	pla		;get exponent back.
	jsr finlog
	lda #<log2	;multiply result by ln(2)
	ldy #>log2

	jmp fmult

conupk	sta index1
	sty index1+1
	ldy #3+addprc
	lda (index1),y
	sta arglo
	dey
	lda (index1),y
	sta argmo
	dey
	lda (index1),y
	sta argmoh
	dey
	lda (index1),y
	sta argsgn
	eor facsgn
	sta arisgn
	lda argsgn
	ora #$80
	sta argho
	dey
	lda (index1),y
	sta argexp
	lda facexp	;set codes of facexp.
	rts

			;check special cases and add exponents for fmult,fdiv.
muldiv
	lda argexp	;exp of arg=0?

mldexp	beq zeremv	;so we get zero exponent.
	clc
	adc facexp	;result is in acca.
	bcc tryoff	;find (c) xor (n).
	bmi goover	;overflow if bits match.
	clc
	bra :+
tryoff
	bpl zeremv	;underflow.
:	adc #$80	;add bias.
	sta facexp
	bne :+
	jmp zeroml	;zero the rest of it.

:	lda arisgn
	sta facsgn	;arisgn is result's sign.
	rts		;done

mldvex
	lda facsgn	;get sign
	eor #$ff	;complement it.
	bmi goover
zeremv
	pla		;get addr off stack.
	pla
	jmp zerofc	;underflow.


goover
	jmp overr	;overflow.

tenc	.byt $84,$20,0,0,0	;10.

div10
	jsr movaf	;move fac to arg.
	lda #<tenc
	ldy #>tenc	;point to constant of 10.0.
	ldx #0		;signs are both positive.
fdivf
	stx arisgn
	jsr movfm	;put it into fac.
	jmp fdivt	;skip over next two bytes.



fdiv
	jsr conupk	;unpack constant.
fdivt
	beq doverr	;can't divide by zero.
			;not enough room to store result.
	jsr round	;take facov into account in fac.
	lda #0		;negate facexp.
	sec
	sbc facexp
	sta facexp
	jsr muldiv	;fix up exponents.
	inc facexp	;scale it right.
	beq goover	;overflow.
	ldx #253-addprc	;set up procedure.
	lda #1
divide			;this is the best code in the whole pile.
	ldy argho	;see what relation holds.
	cpy facho
	bne savquo	;(c)=0,1. n(c=0)=0.
	ldy argmoh
	cpy facmoh
	bne savquo
	ldy argmo
	cpy facmo
	bne savquo
	ldy arglo
	cpy faclo
savquo
	php
	rol a		;save result.
	bcc qshft	;if not done, continue.
	inx
	sta reslo,x
	beq ld100
	bpl divnrm	;note this req 1 no ram then access.
	lda #1
qshft
	plp		;return condition codes.
	bcs divsub	;fac .le. arg.
shfarg
	asl arglo	;shift arg one place left.
	rol argmo
	rol argmoh
	rol argho
	bcs savquo	;save a result of one for this position.
			;and divide.
	bmi divide	;if msb on, go decide whether to sub.
	bpl savquo

divsub
	tay		;notice c must be on here.
	lda arglo
	sbc faclo
	sta arglo
	lda argmo
	sbc facmo
	sta argmo
	lda argmoh
	sbc facmoh
	sta argmoh
	lda argho
	sbc facho
	sta argho
	tya
	jmp shfarg


ld100
	lda #$40	;only want two more bits.
	bne qshft	;always branches.
divnrm
	asl a		;get last two bits into msb and b6.
	asl a
	asl a
	asl a
	asl a
	asl a
	sta facov
	plp
	jmp movfr

doverr
	ldx #errdvo
	jmp error

