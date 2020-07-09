;----------------------------------------------------------------------
; Floating Point Library for 6502: Exponentation
;----------------------------------------------------------------------
; (C)1978 Microsoft

		;exponentation function

		; first save the original argument and multiply the FAC
		; by log2(e).  The result is used to determine if
		; overflow will occur since exp(x)=2^(x*log2(e)) where
		; log2(e)=log(e) base 2.  Then save the integer part of
		; this to scale the answer at the end.  Since
		; 2^y=2^int(y)*2^(y-int(y)) and 2^int(y) is easy to
		; compute.  Now compute 2^(x*log2(e)-int(x*log2(e)) by
		; p(log(2)*(int(x*log2(e))+1)-x  where p is an approximation
		; polynomial. The result is then scaled by the power of two
		; previously saved.

logeb2	.byt $81,$38,$aa,$3b,$29	;log(e) base 2.

expcon	.byt 7				;degree-1
	.byt $71,$34,$58,$3e,$56	;0.000021498763697
	.byt $74,$16,$7e,$b3,$1b	;0.00014352314036
	.byt $77,$2f,$ee,$e3,$85	;0.0013422634824
	.byt $7a,$1d,$84,$1c,$2a	;0.0096140170199
	.byt $7c,$63,$59,$58,$0a	;0.055505126860
	.byt $7e,$75,$fd,$e7,$c6	;0.24022638462
	.byt $80,$31,$72,$18,$10	;0.69314718600
	.byt $81,0,0,0,0		;1.0

exp	lda #<logeb2	;multiply by log(e) base 2.
	ldy #>logeb2
	jsr fmult
	lda facov
	adc #$50
	bcc stold
	jsr incrnd
stold
	sta oldov
	jsr movef	;to save in arg without round.
	lda facexp
	cmp #$88	;if abs(fac) .ge. 128, too big.
	bcc exp1
gomldv
	jsr mldvex	;overflow or overflow.
exp1
	jsr int
	lda integr	;get low part.
	clc
	adc #$81
	beq gomldv	;overflow or overflow !!
	sec
	sbc #1		;subtract it.
	pha		;save a while.
	ldx #4+addprc	;prep to swap fac and arg.
swaplp
	lda argexp,x
	ldy facexp,x
	sta facexp,x
	sty argexp,x
	dex
	bpl swaplp
	lda oldov
	sta facov
	jsr fsubt
	jsr negop	;negate fac.
	lda #<expcon
	ldy #>expcon
	jsr poly
	lda #0
	sta arisgn 	;multiply by positive 1.0
	pla		;get scale factor.
	jsr mldexp	;modify facexp and check for overflow.
	rts		;has to do jsr due to pla's in muldiv.
