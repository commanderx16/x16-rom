getbyt	jsr frmnum
conint	jsr posint
	ldx facmo
	bne gofuc
	ldx faclo
	jmp chrgot
val	jsr len1
	bne *+5
	jmp zerofc
	ldx txtptr
	ldy txtptr+1
	stx strng2
	sty strng2+1
	ldx index1
	stx txtptr
	clc
	adc index1
	sta index2
	ldx index1+1
	stx txtptr+1
	bcc val2
	inx
val2	stx index2+1
	ldy #0
	lda (index2),y
	pha
	tya             ;a=0
	sta (index2),y
	jsr chrgot
	jsr fin
	pla
	ldy #0
	sta (index2),y
st2txt	ldx strng2
	ldy strng2+1
	stx txtptr
	sty txtptr+1
valrts	rts
getnum	jsr frmadr
combyt	jsr chkcom
	jmp getbyt
frmadr	jsr frmnum
getadr	jsr getadr2
	sty poker
	sta poker+1
	rts
peek	lda poker+1
	pha
	lda poker
	pha
	jsr getadr
	ldy #0
	lda poker+1
	cmp #$c0
	bcs peek1
	lda (poker),y   ;RAM
	jmp peek2
peek1	lda #poker
.import fetvec, fetch
	sta fetvec
	ldx #BANK_KERNAL
	jsr fetch       ;ROM
peek2	tay
dosgfl	pla
	sta poker
	pla
	sta poker+1
	jmp sngflt
poke	jsr getnum
	txa
	ldy #0
	sta (poker),y
	rts
fnwait	jsr getnum
	stx andmsk
	ldx #0
	jsr chrgot
	beq stordo
	jsr combyt
stordo	stx eormsk
	ldy #0
waiter	lda (poker),y
	eor eormsk
	and andmsk
	beq waiter
	rts

;**************************
; routines moved from the
; floating point library
;**************************

inprt	lda #<intxt
	ldy #>intxt
	jsr strout
	lda curlin+1
	ldx curlin
linprt	sta facho
	stx facho+1
	ldx #$90
	sec
	jsr floatc
	jsr foutc
	jmp strout

movvf	ldx forpnt
	ldy forpnt+1
	jmp movmf

;**************************************
finh	bcc fin	; skip test for 0-9
	cmp #'$'
	beq finh2
	cmp #'%'
	bne fin
finh2	jmp frmevl
;**************************************
fin	ldy #$00
	ldx #$09+addprc
finzlp	sty deccnt,x
	dex
	bpl finzlp
	bcc findgq
	cmp #'-'
	bne qplus
	stx sgnflg
	beq finc
qplus	cmp #'+'
	bne fin1
finc	jsr chrget
findgq	bcc findig
fin1	cmp #'.'
	beq findp
	cmp #'E'
	bne fine
	jsr chrget
	bcc fnedg1
	cmp #minutk
	beq finec1
	cmp #'-'
	beq finec1
	cmp #plustk
	beq finec
	cmp #'+'
	beq finec
	bne finec2
finec1	ror expsgn
finec	jsr chrget
fnedg1	bcc finedg
finec2	bit expsgn
	bpl fine
	lda #0
	sec
	sbc tenexp
	jmp fine1
findp	ror dptflg
	bit dptflg
	bvc finc
fine	lda tenexp
fine1	sec
	sbc deccnt
	sta tenexp
	beq finqng
	bpl finmul
findiv	jsr div10
	inc tenexp
	bne findiv
	beq finqng
finmul	jsr mul10
	dec tenexp
	bne finmul
finqng	lda sgnflg
	bmi negxqs
	rts
negxqs	jmp negop
findig	pha
	bit dptflg
	bpl findg1
	inc deccnt
findg1	jsr mul10
	pla
	sec
	sbc #'0'
	jsr finlog
	jmp finc

finedg	lda tenexp
	cmp #$0a
	bcc mlex10
	lda #$64
	bit expsgn
	bmi mlexmi
overr	ldx #errov
	jmp error
mlex10	asl a
	asl a
	clc
	adc tenexp
	asl a
	clc
	ldy #0
	adc (txtptr),y
	sec
	sbc #'0'
mlexmi	sta tenexp
	jmp finec

