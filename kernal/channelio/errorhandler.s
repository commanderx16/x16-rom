	.segment "ERROR"
;***************************************
;* stop -- check stop key flag and     *
;* return z flag set if flag true.     *
;* also closes active channels and     *
;* flushes keyboard queue.             *
;* also returns key downs from last    *
;* keyboard row in .a.                 *
;***************************************
nstop	jsr kbd_get_stop;check stop key
	bne stop2       ;not down
	php
	jsr clrch       ;clear channels
	jsr kbd_clear   ;flush queue
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
	bra :+
error2	lda #2          ;file open
	bra :+
error3	lda #3          ;file not open
	bra :+
error4	lda #4          ;file not found
	bra :+
error5	lda #5          ;device not present
	bra :+
error6	lda #6          ;not input file
	bra :+
error7	lda #7          ;not output file
	bra :+
error8	lda #8          ;missing file name
	bra :+
error9	lda #9          ;bad device #
;
:	pha             ;error number on stack
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

