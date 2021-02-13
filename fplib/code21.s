;----------------------------------------------------------------------
; Floating Point Library for 6502
;----------------------------------------------------------------------
; (C)1978 Microsoft

;*********************************
; quick greatest integer function
;*********************************

			;quick greatest integer function.
			;leaves int(fac) in facho&mo&lo signed.
			;assumes fac .lt.2~23 =8388608

qint	lda facexp
	beq clrfac	;if zero, got it.
	sec
	sbc #addpr8+$98	;get number of palces to shift.
	bit facsgn
	bpl qishft
	tax
	lda #$ff
	sta bits	;put $ff in when shftr shifts bytes.
	jsr negfch	;truly negate quantity in fac.
	txa
qishft
	ldx #fac
	cmp #$f9
	bpl qint1	;if number of places .gt. 7.
			;shift 1 place at a time.
	jsr shiftr	;start shifting bytes, then bits.
	sty bits	;zero bits since adder wants zero.
qintrt	rts

qint1
	tay		;put count in counter.
	lda facsgn
	and #$80	;get sign bit.
	lsr facho	;save first shifted byte.
	ora facho
	sta facho
	jsr rolshf	;shift the rest.
	sty bits	;zero (bits).
	rts

;***************************
; greatest integer function
;***************************

int
	lda facexp
	cmp #addpr8+$98
	bcs intrts	;forget it.
	jsr round	;must 'round' fac per 'facov'
			;[fixes the infamous "INT(.9+.1)-> 0" Microsoft bug]
			;(04/08/85 FAB)
	jsr qint
	sty facov	;clr overflow byte.
	lda facsgn
	sty facsgn	;make fac look positive.
	eor #$80	;get complement of sign in carry.
	rol a
	lda #$98+8
	sta facexp
	lda faclo
	sta integr
	jmp fadflt

clrfac
	sta facho	;make it really zero.
	sta facmoh
	sta facmo
	sta faclo
	tay
intrts	rts

finlog
	pha
	jsr movaf	;save it for later.
	pla
	jsr float	;float the value in acca.
faddt2	lda argsgn
	eor facsgn
	sta arisgn	;resultant sign.
	ldx facexp	;set signs on thing to add.
	jmp faddt	;add together and return.

			;
			;here pack in the next digit of the exponent.
			;multiply the old exp by 10 and add in the next
			;digit. note: exp overflow is not checked for
			;
