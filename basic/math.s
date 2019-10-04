.if 0
;;;;;;
.feature labels_without_colons, pc_assignment
.importzp deccnt

.importzp fac
.importzp facexp
.importzp facho
.importzp facmoh
.importzp facmo
.importzp faclo
.importzp facsgn
.importzp degree
.importzp sgnflg
.importzp bits
.importzp argexp
.importzp argho
.importzp argmoh
.importzp argmo
.importzp arglo
.importzp argsgn
.importzp addprc
.importzp errov
.importzp resho
.importzp index
.importzp index1
.importzp index2
.importzp errdvo
.importzp tempf1
.importzp tempf2
.importzp txtptr
.importzp polypt
.importzp plustk
.importzp minutk

.import rndx
.import rdbas
.import tempf3
.import fdecpt
.import fbufpt
.import fbuffr
.import strout
.import curlin
.import intxt
.import dptflg
.import tenexp
.import expsgn
.import chrget
.import frmevl
.import integr
.import forpnt
.import reslo
.import resmo
.import resmoh
.import fcerr
.import error
.import oldov
.import facov
.import arisgn
zerrts
;;;;;;
.endif


faddh	lda #<fhalf
	ldy #>fhalf
	jmp fadd
fsub	jsr conupk
fsubt	lda facsgn
	eor #$ff
	sta facsgn
	eor argsgn
	sta arisgn
	lda facexp
	jmp faddt
fadd5	jsr shiftr
	bcc fadd4
fadd	jsr conupk
faddt	bne *+5
	jmp movfa
	ldx facov
	stx oldov
	ldx #argexp
	lda argexp
faddc	tay
	beq zerrts
	sec
	sbc facexp
	beq fadd4
	bcc fadda
	sty facexp
	ldy argsgn
	sty facsgn
	eor #$ff
	adc #0
	ldy #0
	sty oldov
	ldx #fac
	bne fadd1
fadda	ldy #0
	sty facov
fadd1	cmp #$f9
	bmi fadd5
	tay
	lda facov
	lsr 1,x
	jsr rolshf
fadd4	bit arisgn
	bpl fadd2
	ldy #facexp
	cpx #argexp
	beq subit
	ldy #argexp
subit	sec
	eor #$ff
	adc oldov
	sta facov
	lda 3+addprc,y
	sbc 3+addprc,x
	sta faclo
	lda addprc+2,y
	sbc 2+addprc,x
	sta facmo
	lda 2,y
	sbc 2,x
	sta facmoh
	lda 1,y
	sbc 1,x
	sta facho
fadflt	bcs normal
	jsr negfac
normal	ldy #0
	tya
	clc
norm3	ldx facho
	bne norm1
	ldx facho+1
	stx facho
	ldx facmoh+1

	stx facmoh
	ldx facmo+1
	stx facmo
	ldx facov
	stx faclo
	sty facov
	adc #$08
addpr2	=addprc+addprc
addpr4	=addpr2+addpr2
addpr8	=addpr4+addpr4
	cmp #$18+addpr8
	bne norm3
zerofc	lda #0
zerof1	sta facexp
zeroml	sta facsgn
	rts
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
	jmp squeez
norm2	adc #1
	asl facov
	rol faclo
	rol facmo
	rol facmoh
	rol facho
norm1	bpl norm2
	sec
	sbc facexp
	bcs zerofc
	eor #$ff
	adc #1
	sta facexp
squeez	bcc rndrts
rndshf	inc facexp
	beq overr
	ror facho
	ror facmoh
	ror facmo
	ror faclo
	ror facov
rndrts	rts
negfac	lda facsgn
	eor #$ff
	sta facsgn
negfch	lda facho
	eor #$ff
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
incfac	inc faclo
	bne incfrt
	inc facmo
	bne incfrt
	inc facmoh
	bne incfrt
	inc facho
incfrt	rts
overr	ldx #errov
	jmp error
mulshf	ldx #resho-1
shftr2	ldy 3+addprc,x
	sty facov
	ldy 3,x
	sty 4,x
	ldy 2,x
	sty 3,x
	ldy 1,x
	sty 2,x
	ldy bits
	sty 1,x
shiftr	adc #$08
	bmi shftr2
	beq shftr2
	sbc #$08
	tay
	lda facov
	bcs shftrt
shftr3	asl 1,x
	bcc shftr4
	inc 1,x
shftr4	ror 1,x
	ror 1,x
rolshf	ror 2,x
	ror 3,x
	ror 4,x
	ror a
	iny
	bne shftr3
shftrt	clc
	rts
fone	.byt $81,$00,$00,$00,$00
logcn2	.byt $03,$7f,$5e,$56
	.byt $cb,$79,$80,$13
	.byt $9b,$0b,$64,$80
	.byt $76,$38,$93,$16
	.byt $82,$38,$aa,$3b,$20
sqr05	.byt $80,$35,$04,$f3,$34
sqr20	.byt $81,$35,$04,$f3,$34
neghlf	.byt $80,$80,$00,$00,$00
log2	.byt $80,$31,$72,$17,$f8
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
fmult	jsr conupk
fmultt	bne *+5
	jmp multrt
	jsr muldiv
	lda #0
	sta resho
	sta resmoh
	sta resmo
	sta reslo
	lda facov
	jsr mltply
	lda faclo
	jsr mltply
	lda facmo
	jsr mltply
	lda facmoh
	jsr mltply
	lda facho
	jsr mltpl1
	jmp movfr
mltply	bne *+5
	jmp mulshf
mltpl1	lsr a
	ora #$80
mltpl2	tay
	bcc mltpl3
	clc
	lda reslo
	adc arglo
	sta reslo
	lda resmo
	adc argmo
	sta resmo
	lda resmoh
	adc argmoh
	sta resmoh
	lda resho
	adc argho
	sta resho
mltpl3	ror resho
	ror resmoh
	ror resmo
	ror reslo
	ror facov
	tya
	lsr a
	bne mltpl2
multrt	rts
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
mul10	jsr movaf
	tax
	beq mul10r
	clc
	adc #2
	bcs goover
finml6	ldx #0
	stx arisgn
	jsr faddc
	inc facexp
	beq goover
mul10r	rts
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

movfr	lda resho
	sta facho
	lda resmoh
	sta facmoh
	lda resmo
	sta facmo
	lda reslo
	sta faclo
	jmp normal
movfm	sta index1
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
mov2f	ldx #tempf2
	.byt $2c
mov1f	ldx #tempf1
	ldy #0
	beq movmf
movvf	ldx forpnt
	ldy forpnt+1
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
	lda facsgn
	ora #$7f
	and facho
	sta (index),y
	dey
	lda facexp
	sta (index),y
	sty facov
	rts
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
	stx facov
movrts	rts
round	lda facexp
	beq movrts
	asl facov
	bcc movrts
incrnd	jsr incfac
	bne movrts
	jmp rndshf
sign	lda facexp
	beq signrt
fcsign	lda facsgn
fcomps	rol a
	lda #$ff
	bcs signrt
	lda #1
signrt	rts
sgn	jsr sign
float	sta facho
	lda #0
	sta facho+1
	ldx #$88
floats	lda facho
	eor #$ff
	rol a
floatc	lda #0
	sta faclo
	sta facmo
floatb	stx facexp
	sta facov
	sta facsgn
	jmp fadflt
abs	lsr facsgn
	rts
fcomp	sta index2
fcompn	sty index2+1
	ldy #0
	lda (index2),y
	iny
	tax
	beq sign
	lda (index2),y
	eor facsgn
	bmi fcsign
	cpx facexp
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
	sbc faclo
	beq qintrt
fcompc	lda facsgn
	bcc fcompd
	eor #$ff
fcompd	jmp fcomps

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
finlog	pha
	jsr movaf
	pla
	jsr float
	lda argsgn
	eor facsgn
	sta arisgn
	ldx facexp
	jmp faddt
finedg	lda tenexp
	cmp #$0a
	bcc mlex10
	lda #$64
	bit expsgn
	bmi mlexmi
	jmp overr
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

n0999	.byt $9b,$3e,$bc,$1f,$fd
n9999	.byt $9e,$6e,$6b,$27,$fd
nmil	.byt $9e,$6e,$6b,$28,$00
inprt	lda #<intxt
	ldy #>intxt
	jsr strou2
	lda curlin+1
	ldx curlin
linprt	sta facho
	stx facho+1
	ldx #$90
	sec
	jsr floatc
	jsr foutc
strou2	jmp strout
fout	ldy #1
foutc	lda #' '
	bit facsgn
	bpl fout1
	lda #'-'
fout1	sta fbuffr-1,y
	sta facsgn
	sty fbufpt
	iny
	lda #'0'
	ldx facexp
	bne *+5
	jmp fout19
	lda #0
	cpx #$80
	beq fout37
	bcs fout7
fout37	lda #<nmil
	ldy #>nmil
	jsr fmult
	lda #250-addpr2-addprc
fout7	sta deccnt
fout4	lda #<n9999
	ldy #>n9999
	jsr fcomp
	beq bigges
	bpl fout9
fout3	lda #<n0999
	ldy #>n0999
	jsr fcomp
	beq fout38
	bpl fout5
fout38	jsr mul10
	dec deccnt
	bne fout3
fout9	jsr div10
	inc deccnt
	bne fout4
fout5	jsr faddh
bigges	jsr qint
	ldx #1
	lda deccnt
	clc
	adc #addpr2+addprc+7
	bmi foutpi
	cmp #addpr2+addprc+$08
	bcs fout6
	adc #$ff
	tax
	lda #2
foutpi	sec
fout6	sbc #2
	sta tenexp
	stx deccnt
	txa
	beq fout39
	bpl fout8
fout39	ldy fbufpt
	lda #'.'
	iny
	sta fbuffr-1,y
	txa
	beq fout16
	lda #'0'
	iny
	sta fbuffr-1,y
fout16	sty fbufpt
fout8	ldy #0
foutim	ldx #$80
fout2	lda faclo
	clc
	adc foutbl+2+addprc,y
	sta faclo
	lda facmo
	adc foutbl+1+addprc,y
	sta facmo
	lda facmoh
	adc foutbl+1,y
	sta facmoh
	lda facho
	adc foutbl,y
	sta facho
	inx
	bcs fout41
	bpl fout2
	bmi fout40
fout41	bmi fout2
fout40	txa
	bcc foutyp
	eor #$ff
	adc #$0a
foutyp	adc #$2f
	iny
	iny
	iny
	iny
	sty fdecpt
	ldy fbufpt
	iny
	tax
	and #$7f
	sta fbuffr-1,y
	dec deccnt
	bne stxbuf
	lda #'.'
	iny
	sta fbuffr-1,y
stxbuf	sty fbufpt
	ldy fdecpt
	txa
	eor #$ff
	and #$80
	tax
	cpy #fdcend-foutbl
	beq fouldy
	cpy #timend-foutbl
	bne fout2
fouldy	ldy fbufpt
fout11	lda fbuffr-1,y
	dey
	cmp #'0'
	beq fout11
	cmp #'.'
	beq fout12
	iny
fout12	lda #'+'
	ldx tenexp
	beq fout17
	bpl fout14
	lda #0
	sec
	sbc tenexp
	tax

	lda #'-'
fout14	sta fbuffr+1,y
	lda #'E'
	sta fbuffr,y
	txa
	ldx #$2f
	sec
fout15	inx
	sbc #$0a
	bcs fout15
	adc #$3a
	sta fbuffr+3,y
	txa
	sta fbuffr+2,y
	lda #0
	sta fbuffr+4,y
	beq fout20
fout19	sta fbuffr-1,y
fout17	lda #0
	sta fbuffr,y
fout20	lda #<fbuffr
	ldy #>fbuffr
	rts
fhalf	.byt $80,$00
zero	.byt $00,$00,$00
foutbl	.byt $fa,$0a,$1f,$00,$00
	.byt $98,$96,$80,$ff
	.byt $f0,$bd,$c0,$00
	.byt $01,$86,$a0,$ff
	.byt $ff,$d8,$f0,$00,$00
	.byt $03,$e8,$ff,$ff
	.byt $ff,$9c,$00,$00,$00,$0a
	.byt $ff,$ff,$ff,$ff
fdcend	.byt $ff,$df,$0a,$80
	.byt $00,$03,$4b,$c0,$ff
	.byt $ff,$73,$60,$00,$00
	.byt $0e,$10,$ff,$ff
	.byt $fd,$a8,$00,$00,$00,$3c
timend
;
cksma0	.byt $00        ;$a000 8k room check sum adj
patchs	.res 30          ; patch area
;
sqr	jsr movaf
	lda #<fhalf
	ldy #>fhalf
	jsr movfm
fpwrt	beq exp
	lda argexp
	bne fpwrt1
	jmp zerof1
fpwrt1	ldx #<tempf3
	ldy #>tempf3
	jsr movmf
	lda argsgn
	bpl fpwr1
	jsr int
	lda #<tempf3
	ldy #>tempf3
	jsr fcomp
	bne fpwr1
	tya
	ldy integr
fpwr1	jsr movfa1
	tya
	pha
	jsr log
	lda #<tempf3
	ldy #>tempf3
	jsr fmult
	jsr exp
	pla
	lsr a
	bcc negrts
negop	lda facexp
	beq negrts
	lda facsgn
	eor #$ff
	sta facsgn
negrts	rts

logeb2	.byt $81,$38,$aa,$3b,$29
expcon	.byt $07,$71,$34,$58,$3e
	.byt $56,$74,$16,$7e
	.byt $b3,$1b,$77,$2f
	.byt $ee,$e3,$85,$7a
	.byt $1d,$84,$1c,$2a
	.byt $7c,$63,$59,$58
	.byt $0a,$7e,$75,$fd
	.byt $e7,$c6,$80,$31
	.byt $72,$18,$10,$81
	.byt 0,0,0,0
;
; start of kernal rom
;
exp	lda #<logeb2
	ldy #>logeb2
	jsr fmult
	lda facov
	adc #$50
	bcc stoldx
	jsr incrnd
; continues into stold
stoldx
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
	bmi rnd1
	bne qsetnr
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

