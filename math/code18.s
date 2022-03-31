;----------------------------------------------------------------------
; Floating Point Library for 6502
;----------------------------------------------------------------------
; (C)1978 Microsoft

;
; floating point math package configuration.
;
; Throughout the math package the floating point format is as follows:
;
;	the sign of the first bit of the mantissa.
;	the mantissa is 24 bits long.
;	the binary point is to the left of the msb.
;	number = mantissa * 2 ~ exponent.
;	the mantissa is positive with a 1 assumed to be where the sign bit is.
;	the sign of the exponent is the first bit of the exponent.
;	the exponent is stored in excess $80, i.e., with a bias of +$80.
;	so, the exponent is a signed 8 bit number with $80 added to it.
;	an exponent of zero means the number is zero.
;	the other bytes may not be assumed to be zero.
;	to keep the same number in the fac while shifting,
;	to shift right, exp:=exp+1.
;	to shift left,  exp:=exp-1.
;
; In memory the number looks like this:
;	the exponent as a signed number +$80.
;	the sign bit in 7, bits 2-8 of mantissa are bits 6-0.
;		remember bit 1 of mantissa is always a one.
;	bits 9-16 of the mantissa.
;	bits 17-24 of the mantisa.
;
; Arithmetic routine calling conventions
;
; For one argument functions:
;	the argument is in the fac.
;	the result is left in the fac.
; For two argument operations:
;	the first argument is in arg (argexp,ho,mo,lo and argsgn).
;       the second argument is in the fac.
;	the result is left in the fac.
;
; The "t" entry points to the two argument operations have both arguments setup
; in the respective registers. Before calling arg may have been popped off the
; stack and into arg, for example. The other entry point assumes (xreg) points
; to the argument somewhere in memory. it is unpacked into arg by "conupk".
;
; On the stack, the sgn is pushed on first, the lo,mo,ho, and finally exp.
; Note all things are kept unpacked in arg, fac and on the stack.
;
; It is only when something is stored away that it is packed to four bytes,
; the unpacked format has a sn byte reflecting the sign of the ho turned on.
; The exp is the same as stored format. This is done for speed of operation.

addpr2	=addprc+addprc
addpr4	=addpr2+addpr2
addpr8	=addpr4+addpr4

fsub	jsr conupk

fsubt	lda facsgn
	eor #$ff	;complement it.
	sta facsgn
	eor argsgn	;complement arisgn.
	sta arisgn
	lda facexp	;set codes on facexp.
	jmp faddt	;(y)=argexp.

fadflt
	bcs normal	;here if signs differ. if carry, fac is set ok.
	jsr negfac	;negate (fac)
normal
	ldy #0
	tya
	clc
norm3
	ldx facho
	bne norm1
	ldx facho+1	;shift 8 bits at a time for speed.
	stx facho
	ldx facmoh+1
	stx facmoh
	ldx facmo+1
	stx facmo
	ldx facov
	stx faclo
	sty facov
	adc #8

	cmp #$18+addpr8
	bne norm3

zerofc	lda #0		;not needed by normal but by others.
zerof1	sta facexp	;number must be zero.
zeroml	sta facsgn	;make sign positive.
	rts		;all done.


fadd2	adc oldov
	sta facov
	lda faclo
	adc arglo
	sta faclo
	lda facmo
	adc argmo
	sta facmo
	lda facmoh
	adc argmoh
	sta facmoh
	lda facho
	adc argho
	sta facho
	jmp squeez	;go round if signs same.

norm2
	adc #1		;decrement shift counter.
	asl facov	;shift all left one bit.
	rol faclo
	rol facmo
	rol facmoh
	rol facho
norm1
	bpl norm2	;if msb=0 shift again.
	sec
	sbc facexp
	bcs zerofc
	eor #$ff
	adc #1		;complement.
	sta facexp
squeez
	bcc rndrts	;bits to shift?
rndshf
	inc facexp
	beq overr
	ror facho
	ror facmoh
	ror facmo
	ror faclo
	ror facov
rndrts	rts		;all done adding.

negfac
	lda facsgn
	eor #$ff	;complement fac entirely.
	sta facsgn
negfch
	lda facho
	eor #$ff	;complement just the number.
	sta facho
	lda facmoh
	eor #$ff
	sta facmoh
	lda facmo
	eor #$ff
	sta facmo
	lda faclo
	eor #$ff
	sta faclo
	lda facov
	eor #$ff
	sta facov
	inc facov
	bne incfrt
incfac
	inc faclo
	bne incfrt
	inc facmo
	bne incfrt	;if no carry, return.
	inc facmoh
	bne incfrt
	inc facho	;carry complement.
incfrt	rts

overr
	ldx #errov
	jmp error	;tell user.


;"shiftr" shifts (x+1:x+3) (-acca) bits right.
;shifts bits to start with if possible.

mulshf	ldx #resho-1	;entry point for multiplier.
shftr2	ldy 3+addprc,x	;shift bits first.
	sty facov
	ldy 3,x
	sty 4,x
	ldy 2,x		;get mo.
	sty 3,x		;store lo.
	ldy 1,x		;get ho.
	sty 2,x		;store mo.
	ldy bits
	sty 1,x		;store ho.
shiftr
	adc #8
	bmi shftr2
	beq shftr2
	sbc #8		;c can be either 1,0 and it works.
	tay
	lda facov
	bcs shftrt	;equiv to beq here.
shftr3
	asl 1,x
	bcc shftr4
	inc 1,x
shftr4
	ror 1,x
	ror 1,x 	;yes, two of them.
rolshf
	ror 2,x
	ror 3,x
	ror 4,x		;one mo time.
	ror a
	iny
	bne shftr3	;$$$ (most expensive!!!)
shftrt
	clc		;clear output of facov.
	rts

faddh	lda #<fhalf
	ldy #>fhalf
	jmp fadd
