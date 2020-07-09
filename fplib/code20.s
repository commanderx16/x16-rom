;----------------------------------------------------------------------
; Floating Point Library for 6502: Moving, Sign, Absolute
;----------------------------------------------------------------------
; (C)1978 Microsoft

movfr	lda resho	;move result to fac.
	sta facho
	lda resmoh
	sta facmoh
	lda resmo
	sta facmo
	lda reslo	;move lo and sign.
	sta faclo
	jmp normal	;all done.

movfm	sta index1	;move memory into fac from rom (unpacked).
	sty index1+1
	ldy #3+addprc
	lda (index1),y
	sta faclo
	dey
	lda (index1),y
	sta facmo
	dey
	lda (index1),y
	sta facmoh
	dey
	lda (index1),y
	sta facsgn
	ora #$80
	sta facho
	dey
	lda (index1),y
	sta facexp
	sty facov
	rts

; Move number from fac to memory.

mov2f	ldx #tempf2	;move from fac to temp fac 2
	bra :+
mov1f	ldx #tempf1	;move from fac to temp fac 1
:	ldy #0
	beq movmf
movmf	jsr round
	stx index1
	sty index1+1
	ldy #3+addprc
	lda faclo
	sta (index),y
	dey
	lda facmo
	sta (index),y
	dey
	lda facmoh
	sta (index),y
	dey
	lda facsgn	;include sign in ho.
	ora #$7f
	and facho
	sta (index),y
	dey
	lda facexp
	sta (index),y
	sty facov	;zero it since rounded.
	rts		;(y)=0.

movfa	lda argsgn

movfa1	sta facsgn
	ldx #4+addprc

movfal	lda argexp-1,x
	sta facexp-1,x
	dex
	bne movfal
	stx facov
	rts

movaf	jsr round

movef	ldx #5+addprc

movafl	lda facexp-1,x
	sta argexp-1,x
	dex
	bne movafl
	stx facov	;zero it since rounded.
movrts	rts

round
	lda facexp	;zero?
	beq movrts	;yes, done rounding,
	asl facov	;round?
	bcc movrts	;no, msb off.
incrnd
	jsr incfac	;yes, add one to lsb(fac).
	bne movrts	;no carry means done.
	jmp rndshf	;squeez msb in and rts.
			;
			; note (c) =1 since incpac doesn't touch c.
			;
			;put sign in fac in acca.
sign
	lda facexp
	beq signrt	;if number is zero, so is result.
fcsign
	lda facsgn
fcomps
	rol a
	lda #$ff	;assume negative.
	bcs signrt
	lda #1		;get +1.
signrt	rts

			;sgn function.
sgn
	jsr sign
			;float the signed integer in accb.
float
	sta facho	;put (accb) in high order.
	lda #0
	sta facho+1
	ldx #$88	;get the exponent.
			;float the signed number in fac.

floats
	lda facho
	eor #$ff
	rol a		;get comp of sign in carry.
floatc
	lda #0		;zero (acca) but not carry.
	sta faclo
	sta facmo
floatb
	stx facexp
	sta facov
	sta facsgn
	jmp fadflt

			;absolute value of fac.
abs
	lsr facsgn
	rts
			;
			;compare two numbers
			;
			;a=1 if arg .lt. fac.
			;a=0 if arg=fac.
			;a=-1 if arg .gt. fac.
			;

fcomp
	sta index2
fcompn	sty index2+1
	ldy #0
	lda (index2),y	;has argexp.
	iny		;bump pointer up.
	tax		;save a in x and reset codes.
	beq sign
	lda (index2),y
	eor facsgn	;signs the same.
	bmi fcsign	;signs differ so result is
	cpx facexp	;sign of fac again.
	bne fcompc

	lda (index2),y
	ora #$80
	cmp facho
	bne fcompc
	iny
	lda (index2),y
	cmp facmoh
	bne fcompc
	iny
	lda (index2),y
	cmp facmo
	bne fcompc
	iny
	lda #$7f
	cmp facov
	lda (index2),y
	sbc faclo	;get zero if equal.
	beq qintrt

fcompc
	lda facsgn
	bcc fcompd
	eor #$ff
fcompd	jmp fcomps	;a part of sign sets up acca.
