;most references to kernal are defined here
;
erexit	cmp #$f0        ;check for special case
	bne erexix
; top of memory has changed
	sty memsiz+1
	stx memsiz
	jmp cleart      ;act as if he typed clear
erexix	tax             ;set termination flags
	bne erexiy
	ldx #erbrk      ;break error
erexiy	jmp error       ;normal error

clschn	=$ffcc

outch	jsr $ffd2
	bcs erexit
	rts

inchr	jsr $ffcf
	bcs erexit
	rts

ccall	=$ffe7

coout	jsr ppach       ; go out to save .a for print# patch
	bcs erexit
	rts

coin	jsr $ffc6
	bcs erexit
	rts

readst	=$ffb7

cgetl	jsr $ffe4
	bcs erexit
	rts

setmsg	=$ff90

plot	=$fff0

csys	jsr frmadr      ;get int. addr
	lda #>csysrz    ;push return address
	pha
	lda #<csysrz
	pha
	lda spreg       ;status reg
	pha
	lda sareg       ;load 6502 regs
	ldx sxreg
	ldy syreg
	plp             ;load 6502 status reg
	jmp (linnum)    ;go do it
csysrz	=*-1            ;return to here
	php             ;save status reg
	sta sareg       ;save 6502 regs
	stx sxreg
	sty syreg
	pla             ;get status reg
	sta spreg
	rts             ;return to system

csave	jsr plsv        ;parse parms
	bcs nsnerr6
	jmp snerr6      ;disallow bank/address parms
nsnerr6	ldx vartab      ;end save addr
	ldy vartab+1
	lda #<txttab    ;indirect with start address
	jsr $ffd8       ;save it
	bcs erexit
	rts

cverf	lda #1          ;verify flag
	bra :+

cload	lda #0          ;load flag
:	pha
	jsr plsv        ;parse parameters
	bcs cld9
cld8                    ;entry-point for BLOAD
	ldx andmsk
	stx ram_bank
cld9	pla
;
cld10	; jsr $ffe1 ;check run/stop
; cmp #$ff ;done yet?
; bne cld10 ;still bouncing
	sta verck
	ldx poker       ;.x and .y have alt...
	ldy poker+1     ;...load address
	jsr $ffd5       ;load it
	bcs jerxit      ;problems
;
	lda verck
	cmp #1
	bne cld50       ;was load
;
;finish verify
;
	ldx #ervfy      ;assume error
	jsr $ffb7       ;read status
	and #$10        ;check error
	bne cld55       ;replaces beq *+5/jmp error
;
;print verify 'ok' if direct
;
	lda txtptr
	cmp #bufpag
	beq cld20
	lda #<okmsg
	ldy #>okmsg
	jmp strout
;
cld20	rts

;
;finish load
;
cld50	jsr $ffb7       ;read status
	and #$ff-$40    ;clear e.o.i.
	beq cld60       ;was o.k.
	ldx #erload
cld55	jmp error
;
cld60	lda eormsk
	bne cld20
	lda txtptr+1
	cmp #bufpag     ;direct?
	bne cld70       ;no...
;
cld65	stx vartab
	sty vartab+1    ;end load address
	lda #<reddy
	ldy #>reddy
	jsr strout
	jmp fini
;
;program load
;
cld70	jsr stxtpt
	jsr lnkprg
	jmp fload

copen	jsr paoc        ;parse statement
	jsr $ffc0       ;open it
	bcs jerxit      ;bad stuff or memsiz change
	rts             ;a.o.k.

snerr6	jmp snerr

cclos	jsr paoc        ;parse statement
	lda andmsk      ;get la
	jsr $ffc3       ;close it
	bcc cld20       ;it's okay...no memsize change
;
jerxit	jmp erexit

;
;parse load and save commands
;
;[filename[,dev[,relocate]]]
; or:
;[filename[,dev[,bank,address]]]
;
;if the first form is used:
;- poker points to the start of basic
;- the carry flag is set
;- eormsk contains 0
;otherwise:
;- relocate is taken as 0
;- the bank number is in andmsk
;- poker contains the specified address
;- the carry flag is clear
;- eormsk contains 1
;
plsvbin
	lda #2          ;enable headerless mode
	bra :+
plsv
	lda #0          ;disable headerless mode
:	sta addend      ;headerless mode stashed in addend
;default file name
;
	lda #0          ;length=0
	sta eormsk
	jsr $ffbd
;
;default device #
;
	pha
	jsr getfa
	tax
	pla
	ldy #0          ;command 0
	jsr $ffba
;
;default address
;
	lda txttab
	sta poker
	lda txttab+1
	sta poker+1
;
	jsr chrgot      ;end of statement?
	beq plsv30      ;yes
	jsr paoc15      ;get/set file name
	jsr paoc20      ;quit if no comma
	jsr getbyt      ;get 'fa'
	ldy #0          ;command 0
	stx andmsk
	jsr paoc19      ;store x,y then maybe quit
	jsr getbyt      ;get 'sa'
	txa             ;new command
	tay
	ldx andmsk      ;device #
	jsr paoc19      ;store x,y then maybe quit
	sty andmsk      ;bank number
	ldy addend      ;headerless mode?
	jsr $ffba
	jsr frmadr      ;put address in poker
;
;eat trailing garbage after address parm
;
;	jsr chrgot
;	beq plsv20
;plsv10	jsr chrget
;	bne plsv10
;
plsv20	inc eormsk
plsv30	rts

;store file parms then maybe end
paoc19	jsr $ffba

;quit if there's no comma
;
paoc20	jsr chrgot
	cmp #','
	beq paoc30
	pla
	pla
	sec
	rts
paoc30	jmp chrget

;parse open/close
;
paoc	lda #0
	jsr $ffbd       ;default file name
;
	jsr chrgot
	beq snerr6      ;must got something
	jsr getbyt      ;get la
	stx andmsk
	jsr getfa
	tax
	lda andmsk      ;restore la
	ldy #0          ;default command
	jsr paoc19      ;store x,y then maybe quit
	jsr getbyt
	stx eormsk
	ldy #0          ;default command
	lda andmsk      ;get la
	cpx #3
	bcc paoc5
	dey             ;default ieee to $ff
paoc5	jsr paoc19      ;store x,y then maybe quit
	jsr getbyt      ;get sa
	txa
	tay
	ldx eormsk
	lda andmsk
	jsr paoc19      ;store x,y then maybe quit
paoc15	jsr frmstr      ;length in .a
	ldx index1
	ldy index1+1
	jmp $ffbd

; rsr 8/10/80 - change sys command
; rsr 8/26/80 - add open&close memsiz detect
; rsr 10/7/80 - change load (remove run wait)
; rsr 4/10/82 - inline fix program load
; rsr 7/02/82 - fix print# problem
