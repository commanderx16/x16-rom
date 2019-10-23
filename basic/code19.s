log	jsr sign
	beq logerr
	bpl log1
logerr	jmp fcerr
log1	lda facexp
	sbc #$7f
	pha
	lda #$80
	sta facexp
	lda #<sqr05
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
	jsr polyx
	lda #<neghlf
	ldy #>neghlf
	jsr fadd
	pla
	jsr finlog
	lda #<log2
	ldy #>log2
   jmp fmult
conupk	sta index1
	sty index1+1
	ldy #3+addprc
	lda (index1),y
	sta arglo
	dey
	lda (index),y
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
	lda facexp
	rts
muldiv	lda argexp
mldexp	beq zeremv
	clc
	adc facexp
	bcc tryoff
	bmi goover
	clc
	.byt $2c
tryoff	bpl zeremv
	adc #$80
	sta facexp
	bne *+5
	jmp zeroml
	lda arisgn
	sta facsgn
	rts
mldvex	lda facsgn
	eor #$ff
	bmi goover
zeremv	pla
	pla
	jmp zerofc
goover	jmp overr
tenc	.byt $84,$20,0,0,0
div10	jsr movaf
	lda #<tenc
	ldy #>tenc
	ldx #0
fdivf	stx arisgn
	jsr movfm
	jmp fdivt
fdiv	jsr conupk
fdivt	beq dv0err
	jsr round
	lda #0
	sec
	sbc facexp
	sta facexp
	jsr muldiv
	inc facexp
	beq goover
	ldx #253-addprc
	lda #1
divide	ldy argho
	cpy facho
	bne savquo
	ldy argmoh
	cpy facmoh
	bne savquo
	ldy argmo
	cpy facmo
	bne savquo
	ldy arglo
	cpy faclo
savquo	php
	rol a
	bcc qshft
	inx
	sta reslo,x
	beq ld100
	bpl divnrm
	lda #1
qshft	plp
	bcs divsub
shfarg	asl arglo
	rol argmo
	rol argmoh
	rol argho
	bcs savquo
	bmi divide
	bpl savquo
divsub	tay
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
ld100	lda #$40
	bne qshft
divnrm	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	sta facov
	plp
	jmp movfr
dv0err	ldx #errdvo
	jmp error

