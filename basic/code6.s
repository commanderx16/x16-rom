inpcom
	; check for TI/TI$/DA$ assignment
	ldy forpnt+1
	cpy #>zero
	beq :+
	jmp getspt ; no
:
	lda varnam
	cmp #'D' ; DA$?
	beq asgndt

	; TI$ assignment
	jsr frefac
	cmp #6
	bne fcerr2 ; wrong length

	; get date, so we can set it again
	jsr clock_get_date_time

	; hours
	jsr zerofc
	ldy #0
	jsr timnum
	jsr mul10
	ldy #1
	jsr timnum
	jsr getadr
	cpy #24
	bcs fcerr2
	sty r1H

	; minutes
	jsr zerofc
	ldy #2
	jsr timnum
	jsr mul10
	ldy #3
	jsr timnum
	jsr getadr
	cpy #60
	bcs fcerr2
	sty r2L

	; seconds
	jsr zerofc
	ldy #4
	jsr timnum
	jsr mul10
	ldy #5
	jsr timnum
	jsr getadr
	cpy #60
	bcs fcerr2
	sty r2H

	jmp clock_set_date_time

	; get a digit and add it to FAC
timnum	lda (index),y
	jsr qnum
	bcc gotnum
fcerr2	jmp fcerr
gotnum	sbc #$2f
	jmp finlog

	; DA$ assignment
asgndt
	jsr frefac
	cmp #8
	bne fcerr2 ; wrong length

	; get time, so we can set it again
	jsr clock_get_date_time

	; year
	jsr zerofc
	ldy #0
	jsr timnum
	jsr mul10
	ldy #1
	jsr timnum
	jsr mul10
	ldy #2
	jsr timnum
	jsr mul10
	ldy #3
	jsr timnum
	jsr getadr
	tax
	tya
	sec
	sbc #<1900
	tay
	txa
	sbc #>1900
	bne fcerr2 ; YY < 1900 or YY > 1900+255
	sty r0L

	; month
	jsr zerofc
	ldy #4
	jsr timnum
	jsr mul10
	ldy #5
	jsr timnum
	jsr getadr
	tya
	beq fcerr2 ; MM == 0
	cmp #13
	bcs fcerr2 ; MM > 12
	sta r0H

	; day
	jsr zerofc
	ldy #6
	jsr timnum
	jsr mul10
	ldy #7
	jsr timnum
	jsr getadr
	tya
	beq fcerr2 ; DD == 0
	cmp #32
	bcs fcerr2 ; DD > 32
	sta r1L

	jmp clock_set_date_time

getspt	ldy #2
	lda (facmo),y
	cmp fretop+1
	bcc dntcpy
	bne qvaria
	dey
	lda (facmo),y
	cmp fretop
	bcc dntcpy
qvaria	ldy faclo
	cpy vartab+1
	bcc dntcpy
	bne copy
	lda facmo
	cmp vartab
	bcs copy
dntcpy	lda facmo
	ldy facmo+1
	jmp copyc
copy	ldy #0
	lda (facmo),y
	jsr strini
	lda dscpnt
	ldy dscpnt+1
	sta strng1
	sty strng1+1
	jsr movins
	lda #<dsctmp
	ldy #>dsctmp
copyc	sta dscpnt
	sty dscpnt+1
	jsr fretms
	ldy #0
	lda (dscpnt),y
	sta (forpnt),y
	iny
	lda (dscpnt),y
	sta (forpnt),y
	iny
	lda (dscpnt),y
	sta (forpnt),y
	rts
printn	jsr cmd
	jmp iodone
cmd	jsr getbyt
	beq saveit
	lda #44
	jsr synchr
saveit	php
	stx channl
	jsr coout
	plp
	jmp print
strdon	jsr strprt
newchr	jsr chrgot
print	beq crdo
printc	beq prtrts
	cmp #tabtk
	beq taber
	cmp #spctk
	clc
	beq taber
	cmp #44
	beq comprt
	cmp #59
	beq notabr
	jsr frmevl
	bit valtyp
	bmi strdon
	jsr fout
	jsr strlit
	jsr strprt
	jsr outspc
	bne newchr
fininl	lda #0
	sta buf,x
zz5=buf-1
	ldx #<zz5
	ldy #>zz5
	lda channl
	bne prtrts
crdo	lda #13
	jsr outdo
	bit channl
	bpl crfin
;
	lda #10
	jsr outdo
crfin	eor #255
prtrts	rts
comprt	sec
	jsr plot        ;get tab position in x
	tya
ncmpos	=$1e
	sec
morco1	sbc #clmwid
	bcs morco1
	eor #255
	adc #1
	bne aspac
taber	php
	sec
	jsr plot        ;read tab position
	sty trmpos
	jsr gtbytc
	cmp #41
	bne snerr4
	plp
	bcc xspac
	txa
	sbc trmpos
	bcc notabr
aspac	tax
xspac	inx
xspac2	dex
	bne xspac1
notabr	jsr chrget
	jmp printc

