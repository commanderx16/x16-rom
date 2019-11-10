qint	lda facexp
	beq clrfac
	sec
	sbc #addpr8+$98
	bit facsgn
	bpl qishft
	tax
	lda #$ff
	sta bits
	jsr negfch
	txa
qishft	ldx #fac
	cmp #$f9
	bpl qint1
	jsr shiftr
	sty bits
qintrt	rts
qint1	tay
	lda facsgn
	and #$80
	lsr facho
	ora facho
	sta facho
	jsr rolshf
	sty bits
	rts
int	lda facexp
	cmp #addpr8+$98
	bcs intrts
	jsr qint
	sty facov
	lda facsgn
	sty facsgn
	eor #$80
	rol a
	lda #$98+8
	sta facexp
	lda faclo
	sta integr
	jmp fadflt
clrfac	sta facho
	sta facmoh
	sta facmo
	sta faclo
	tay 
intrts	rts

finlog	pha
	jsr movaf
	pla
	jsr float
faddt2	lda argsgn
	eor facsgn
	sta arisgn
	ldx facexp
	jmp faddt
