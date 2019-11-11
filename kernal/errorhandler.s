	.segment "ERROR"
;***************************************
;* stop -- check stop key flag and     *
;* return z flag set if flag true.     *
;* also closes active channels and     *
;* flushes keyboard queue.             *
;* also returns key downs from last    *
;* keyboard row in .a.                 *
;***************************************
nstop	lda stkey       ;value of last row
	cmp #$7f        ;check stop key position
	bne stop2       ;not down
	php
	jsr clrch       ;clear channels
	sta ndx         ;flush queue
	plp
stop2	rts

;************************************
;*                                  *
;* error handler                    *
;*                                  *
;* prints kernal error message if   *
;* bit 6 of msgflg set.  returns    *
;* with error # in .a and carry.    *
;*                                  *
;************************************
;
error1	lda #1          ;too many files
	bra js12
error2	lda #2          ;file open
	bra js12
error3	lda #3          ;file not open
	bra js12
error4	lda #4          ;file not found
	bra js12
error5	lda #5          ;device not present
	bra js12
error6	lda #6          ;not input file
	bra js12
error7	lda #7          ;not output file
	bra js12
error8	lda #8          ;missing file name
	bra js12
error9	lda #9          ;bad device #
;
js12:	pha             ;error number on stack
	jsr clrch       ;restore i/o channels
;
	ldy #ms1-ms1
	bit msgflg      ;are we printing error?
	bvc erexit      ;no...
;
	jsr msg         ;print "cbm i/o error #"
	pla
	pha
	ora #$30        ;make error # ascii
	jsr bsout       ;print it
;
erexit	pla
	sec
	rts

