; continuation of exponent routine
;
stold	sta oldov
	jsr movef
	lda facexp
	cmp #$88
	bcc exp1
gomldv	jsr mldvex
exp1	jsr int
	lda integr
	clc
	adc #$81
	beq gomldv
	sec
	sbc #1
	pha
	ldx #4+addprc
swaplp	lda argexp,x
	ldy facexp,x
	sta facexp,x
	sty argexp,x
	dex
	bpl swaplp
	lda oldov
	sta facov
	jsr fsubt
	jsr negop
	lda #<expcon
	ldy #>expcon
	jsr poly
	lda #0
	sta arisgn
	pla
	jsr mldexp
	rts
polyx	sta polypt
	sty polypt+1
	jsr mov1f
	lda #tempf1
	jsr fmult
	jsr poly1
	lda #<tempf1
	ldy #>tempf1
	jmp fmult
poly	sta polypt
	sty polypt+1
poly1	jsr mov2f
	lda (polypt),y
	sta degree
	ldy polypt
	iny
	tya
	bne poly3
	inc polypt+1
poly3	sta polypt
	ldy polypt+1
poly2	jsr fmult
	lda polypt
	ldy polypt+1
	clc
	adc #4+addprc
	bcc poly4
	iny
poly4	sta polypt
	sty polypt+1
	jsr fadd
	lda #<tempf2
	ldy #>tempf2
	dec degree
	bne poly2
	rts
rmulc	.byt $98,$35,$44,$7a,$00
raddc	.byt $68,$28,$b1,$46,$00
rnd	jsr sign
rnd_0	bmi rnd1
	bne qsetnr
; XXX Initializing the RNG seed should be moved
; XXX out of FPLIB to remove the dependency on
; XXX KERNAL. In fact, generating a seed should
; XXX be done by KERNAL, combining all sources
; XXX on entropy.
	jsr rdbas
	stx index1
	sty index1+1
	ldy #4
	lda (index1),y
	sta facho
	iny
	lda (index1),y
	sta facmo
	ldy #8
	lda (index1),y
	sta facmoh
	iny
	lda (index1),y
	sta faclo
	jmp strnex
qsetnr	lda #<rndx
	ldy #>rndx
	jsr movfm
	lda #<rmulc
	ldy #>rmulc
	jsr fmult
	lda #<raddc
	ldy #>raddc
	jsr fadd
rnd1	ldx faclo
	lda facho
	sta faclo
	stx facho
	ldx facmoh
	lda facmo
	sta facmoh
	stx facmo
strnex	lda #0
	sta facsgn
	lda facexp
	sta facov
	lda #$80
	sta facexp
	jsr normal
	ldx #<rndx
	ldy #>rndx
gmovmf	jmp movmf

;**************************
; routines moved from BASIC
;**************************

ayint	lda facexp
	cmp #144
	bcc qintgo
	lda #<n32768
	ldy #>n32768
	jsr fcomp
	beq qintgo
gofuc	jmp fcerr
qintgo	jmp qint

n32768	.byt 144,128,0,0,0

givayf2	sta facho
	sty facho+1
	ldx #144
	jmp floats

getadr2	lda facsgn
	bmi gofuc
	lda facexp
	cmp #145
	bcs gofuc
	jsr qint
	lda facmo
	ldy facmo+1
	rts

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

rnd2	ora #0          ;set flags
	jmp rnd_0
