;----------------------------------------------------------------------
; Channel: OPEN
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

;***********************************
;*                                 *
;* open function                   *
;*                                 *
;* creates an entry in the logical *
;* files tables consisting of      *
;* logical file number--la, device *
;* number--fa, and secondary cmd-- *
;* sa.                             *
;*                                 *
;* a file name descriptor, fnadr & *
;* fnlen are passed to this routine*
;*                                 *
;***********************************
;
nopen	ldx la          ;check file #
	bne op98        ;is not the keyboard
;
	jmp error6      ;not input file...
;
op98	jsr lookup      ;see if in table
	bne op100       ;not found...o.k.
;
	jmp error2      ;file open
;
op100	ldx ldtnd       ;logical device table end
	cpx #10         ;maximum # of open files
	bcc op110       ;less than 10...o.k.
;
	jmp error1      ;too many files
;
op110	inc ldtnd       ;new file
	lda la
	sta lat,x       ;store logical file #
	lda sa
	ora #$60        ;make sa an serial command
	sta sa
	sta sat,x       ;store command #
	lda fa
	sta fat,x       ;store device #
;
;perform device specific open tasks
;
	beq op175       ;is keyboard...done.
	cmp #3
	beq op175       ;is screen...done.
	bcc op150       ;are cassettes 1 & 2
;
	jsr openi       ;is on serial...open it
	bcc op175       ;branch always...done
;
;perform tape open stuff
;
op150	cmp #2
	bne op152
;
	jmp opn232
op152	jmp error9
op175	clc             ;flag good open
	rts             ;exit in peace

openi	lda sa
	bmi op175       ;no sa...done
;
	ldy fnlen
	beq op175       ;no file name...done
;
	lda #0          ;clear the serial status
	sta status
;
	lda fa
	jsr listn       ;device la to listen
;
	lda sa
	ora #$f0
	jsr secnd
;
	lda status      ;anybody home?
	bpl op35        ;yes...continue
;
;this routine is called by other
;kernal routines which are called
;directly by os.  kill return
;address to return to os.
;
	pla
	pla
	jmp error5      ;device not present
;
op35	lda fnlen
	beq op45        ;no name...done sequence
;
;send file name over serial
;
	ldy #0
op40	lda (fnadr),y
	jsr ciout
	iny
	cpy fnlen
	bne op40
;
op45	jmp cunlsn      ;jsr unlsn: clc: rts

; rsr  8/25/80 - add rs-232 code
; rsr  8/26/80 - top of memory handler
; rsr  8/29/80 - add filename to m51regs
; rsr  9/02/80 - fix ordering of rs-232 routines
; rsr 12/11/81 - modify for vic-40 i/o
; rsr  2/08/82 - clear status in openi
; rsr  5/12/82 - compact rs232 open/close code
