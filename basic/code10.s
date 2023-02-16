;test pointer to variable to see
;if constant is contained in basic.
;array variables have zeroes placed
;in ram. undefined simple variables
;have pointer to zero in basic.
;
tstrom	sec
	lda facmo
	sbc #<romloc
	lda faclo
	sbc #>romloc
	rts

isvar	jsr ptrget
isvret	sta facmo
	sty facmo+1
	ldx varnam
	ldy varnam+1
	lda valtyp
	bne :+
	jmp gooo
:	lda #0
	sta facov
	jsr tstrom      ;see if an array
	bcc tstr10      ;don't test st(i),ti(i)
	cpx #'T'
	bne tstr10
	cpy #'I'+$80
	bne tstr10

	; read TI$: We convert each component
	; (seconds, minutes, hours) to a two-digit ASCIIZ
	; string. This is done by adding 100 to the value
	; and printing it. The first two characters of the
	; result will be a SPACE and the leading '1', so
	; the two digits will be at offsets 2 and 3.
	; We do this for all components and collect them
	; on the stack, then put them together at the end.

	jsr clock_get_date_time

	; seconds
	lda r2H
	jsr component2ascii

	lda lofbuf+3
	pha
	lda lofbuf+2
	pha

	; minutes
	lda r2L
	jsr component2ascii

	lda lofbuf+3
	pha
	lda lofbuf+2
	pha

	; hours
	lda r1H
	jsr component2ascii

	; Hours is at lofbuf+2.  But strings that start at lofbuf
	; (which is in page 0) will get treated differently by strlit/strlitl
	; than strings that start at lofbuf+1 or lofbuf+2 (in page 1) so
	; shift it down.

	lda lofbuf+2
	sta lofbuf
	lda lofbuf+3
	sta lofbuf+1

	; Copy the minutes and seconds into place
	pla
	sta lofbuf+2 ; MM
	pla
	sta lofbuf+3 ; MM
	pla
	sta lofbuf+4 ; SS
	pla
	sta lofbuf+5 ; SS
	lda #0
	sta lofbuf+6 ; Z

	jmp strlitl

	; Read DA$: Like $TI we convert components to
	; ASCIIZ strings, cutting a character or two off
	; each (SPACE, and sometimes a leading 1).
tstr10	cpx #'D'
	bne tstr11
	cpy #'A'+$80
	bne tstr11

	jsr clock_get_date_time
	lda r1L
	ora r0H
	ora r0L
	bne :+
	sta lofbuf+1
	jmp strlitl
:
	; day
	lda r1L
	jsr component2ascii

	lda lofbuf+3
	pha
	lda lofbuf+2
	pha

	; month
	lda r0H
	jsr component2ascii

	lda lofbuf+3
	pha
	lda lofbuf+2
	pha

	; year
	lda r0L
	clc
	adc #<1900
	tay
	lda #>1900
	jsr component2ascii2

	; Now year is at lofbuf+1.  But strings that start at lofbuf
	; (which is in page 0) will get treated differently by strlit/strlitl
	; than strings that start at lofbuf+1 or lofbuf+2 (in page 1) so
	; shift it down.

	ldy #0
:	lda lofbuf+1,y       ; in
	sta lofbuf,y         ; out
	iny                  ; count
	cpy #4               ; 4 bytes copied yet?
	bne :-

	; Copy the months and days into place
	pla
	sta lofbuf+4 ; MM
	pla
	sta lofbuf+5 ; MM
	pla
	sta lofbuf+6 ; DD
	pla
	sta lofbuf+7 ; DD
	lda #0
	sta lofbuf+8 ; Z

	jmp strlitl

component2ascii:
	clc
	adc #100
	tay
	lda #0
component2ascii2:
	jsr givayf
	ldy #0
	jmp foutc


tstr11	rts


gooo	bit intflg
	bpl gooooo
	ldy #0
	lda (facmo),y
	tax
	iny
	lda (facmo),y
	tay
	txa
	jmp givayf0
gooooo	jsr tstrom      ;see if array
	bcc gomovf      ;don't test st(i),ti(i)
	cpx #'T'
	bne qstatv
	cpy #'I'
	bne gomovf
	; read TI
	jsr rdtim
	stx facmo
	sty facmoh
	sta faclo
	ldy #0
	sty facho
	tya
	ldx #160
	jmp floatb

qstatv	cpx #'S'
	bne gomovf
	cpy #'T'
	bne gomovf
	jsr readst
	jmp float
gomovf	lda facmo
	ldy facmo+1
	jmp movfm
isfun
;**************************************
; new function execution
;**************************************
	cmp #$ce ; escape token
	bne nesct3

	jsr chrget
	bne :+
snerr9:	jmp snerr
:	sec
	sbc #$d0
	cmp #num_esc_functions
	bcs snerr9

	asl a
	tay
	lda ptrfunc,y
	sta jmper+1
	lda ptrfunc+1,y
	sta jmper+2
	jsr jmper
	jmp chknum

nesct3
;**************************************
	asl a
	pha
	tax
	jsr chrget
	cpx #lasnum+lasnum-255
	bcc oknorm
	jsr chkopn
	jsr frmevl
	jsr chkcom
	jsr chkstr
	pla
	tax
	lda facmo+1
	pha
	lda facmo
	pha
	txa
	pha
	jsr getbyt
	pla
	tay
	txa
	pha
	jmp fingo
oknorm	jsr parchk
	pla
	tay
fingo	lda fundsp-onefun-onefun+256,y
	sta jmper+1
	lda fundsp-onefun-onefun+257,y
	sta jmper+2
	jsr jmper
	jmp chknum
orop	ldy #255
	bra :+
andop	ldy #0
:	sty count
	jsr ayint
	lda facmo
	eor count
	sta integr
	lda faclo
	eor count
	sta integr+1
	jsr movfa
	jsr ayint
	lda faclo
	eor count
	and integr+1
	eor count
	tay
	lda facmo
	eor count
	and integr
	eor count
	jmp givayf0
dorel	jsr chkval
	bcs strcmp
	lda argsgn
	ora #127
	and argho
	sta argho
	lda #<argexp
	ldy #>argexp
	jsr fcomp
	tax
	jmp qcomp
strcmp	lda #0
	sta valtyp
	dec opmask
	jsr frefac
	sta dsctmp
	stx dsctmp+1
	sty dsctmp+2
	lda argmo
	ldy argmo+1
	jsr fretmp
	stx argmo
	sty argmo+1
	tax
	sec
	sbc dsctmp
	beq stasgn
	lda #1
	bcc stasgn
	ldx dsctmp
	lda #$ff
stasgn	sta facsgn
	ldy #255
	inx
nxtcmp	iny
	dex
	bne getcmp
	ldx facsgn
qcomp	bmi docmp
	clc
	bcc docmp
getcmp	lda (argmo),y

