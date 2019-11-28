.import ps2_init ; [ps2]

	.segment "INIT"
; start - system reset
;
start	ldx #$ff
	sei
	txs
	jsr ioinit      ;go initilize i/o devices
	jsr ramtas      ;go ram test and set
	jsr restor      ;go set up os vectors
;
	jsr cint        ;go initilize screen
	cli             ;interrupts okay now


	jsr jsrfar
	.word $c000     ;go to basic system
	.byte BANK_BASIC
	                ;not reached

; restor - set kernal indirects and vectors (system)
;
restor	ldx #<vectss
	ldy #>vectss
	clc
;
; vector - set kernal indirect and vectors (user)
;
vector	stx tmp2
	sty tmp2+1
	ldy #vectse-vectss-1
movos1	lda cinv,y      ;get from storage
	bcs movos2      ;c...want storage to user
	lda (tmp2),y     ;...want user to storage
movos2	sta (tmp2),y     ;put in user
	sta cinv,y      ;put in storage
	dey
	bpl movos1
	rts
;
vectss	.word key,timb,nnmi
	.word nopen,nclose,nchkin
	.word nckout,nclrch,nbasin
	.word nbsout,nstop,ngetin
	.word nclall,timb ;goto break on a usrcmd jmp
	.word nload,nsave
vectse

; ramtas - memory size check and set
;
ramtas	lda #0          ;zero low memory
	tay
ramtz0	sta $0000,y     ;zero page
	sta $0200,y     ;user buffers and vars
	sta $0300,y     ;system space and user space
	iny
	bne ramtz0

	ldy #KVARSB0_END - KVARSB0_START + 1
:	sta KVARSB0_START-1,y
	dey
	bne :-

;
; set top of memory
;
	ldx #<mmtop
	ldy #>mmtop
	clc
	jsr settop
	lda #$08        ;set bottom of memory
	sta memstr+1    ;always at $0800
	lda #>vicscn
	sta hibase      ;set base of screen
;
; copy banking code into RAM
;
.import __KERNRAM_LOAD__, __KERNRAM_RUN__, __KERNRAM_SIZE__
	ldx #<__KERNRAM_SIZE__
ramtz1	lda __KERNRAM_LOAD__-1,x
	sta __KERNRAM_RUN__-1,x
	dex
	bne ramtz1

.import __KERNRAM2_LOAD__, __KERNRAM2_RUN__, __KERNRAM2_SIZE__
	ldx #<__KERNRAM2_SIZE__
ramtz2	lda __KERNRAM2_LOAD__-1,x
	sta __KERNRAM2_RUN__-1,x
	dex
	bne ramtz2

;
; detect number of RAM banks
;
	lda d1pra       ;RAM bank
	pha
	stz d1pra
	ldx $a000
	inx
	lda #1
:	sta d1pra
	ldy $a000
	stx $a000
	stz d1pra
	cpx $a000
	sta d1pra
	sty $a000
	beq :+
	asl
	bne :-
:	sta rambks
	stz d1pra
	dex
	stx $a000
	pla
	sta d1pra
	rts

; ioinit - initilize io devices
;
ioinit
	; XXX TODO: VIC-20: $FDF9
	jsr ps2_init    ;inhibit ps/2 communcation
;
; set up banking
;
	lda #$ff
	sta d1ddra
	sta d1ddrb
	lda #0
	sta d1pra ; RAM bank
;
;jsr clkhi ;clkhi to release serial devices  ^
;
iokeys
.if 0 ; VIA#2 timer IRQ for 60 Hz
	lda #<sixty     ;keyboard scan irq's
	sta d1t1l
	lda #>sixty
	sta d1t1h
	lda #$40        ;t1 free run
	sta d1acr
	lda #$c0        ;enable t1 irq's
	sta d1ier
.else ; VERA VSYNC IRQ for 60 Hz
	lda #1
	sta veraien
.endif
	jmp clklo       ;release the clock line***901227-03***
;
; sixty hertz value
;
sixty	= mhz * 1000000 / 60

setnam	sta fnlen
	stx fnadr
	sty fnadr+1
	rts

setlfs	sta la
	stx fa
	sty sa
	rts

setmsg	sta msgflg
readst	lda status
udst	ora status
	sta status
settmo	rts

memtop	bcc settop
;
;carry set--read top of memory
;
gettop	ldx memsiz
	ldy memsiz+1
	lda rambks
;
;carry clear--set top of memory
;
settop	stx memsiz
	sty memsiz+1
	rts

;manage bottom of memory
;
membot	bcc setbot
;
;carry set--read bottom of memory
;
	ldx memstr
	ldy memstr+1
;
;carry clear--set bottom of memory
;
setbot	stx memstr
	sty memstr+1
	rts

; rsr 8/5/80 change io structure
; rsr 8/15/80 add memory test
; rsr 8/21/80 change i/o for mod
; rsr 8/25/80 change i/o for mod2
; rsr 8/29/80 change ramtest for hardware mistake
; rsr 9/22/80 change so ram hang rs232 status read
; rsr 5/12/82 change start1 order to remove disk problem
