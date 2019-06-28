	.segment "INIT"
; start - system reset
;
start	ldx #$ff
	sei
	txs
	cld
	jsr ioinit      ;go initilize i/o devices
	jsr ramtas      ;go ram test and set
	jsr restor      ;go set up os vectors
;
	jsr cint        ;go initilize screen
	cli             ;interrupts okay now
	jmp ($c000)     ;go to basic system

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
;
; set top of memory
;
	ldx #<mmtop
	ldy #>mmtop
	clc
	jsr settop
	lda #$08        ;set bottom of memory
	sta memstr+1    ;always at $0800
	lda #$04        ;screen always at $400
	sta hibase      ;set base of screen
	rts

; ioinit - initilize io devices
;
ioinit
.if 0
	lda #$7f        ;kill interrupts
	sta d1icr
	sta d2icr
	sta d1pra       ;turn on stop key
	lda #%00001000  ;shut off timers
	sta d1cra
	sta d2cra
	sta d1crb
	sta d2crb
; configure ports
	ldx #$00        ;set up keyboard inputs
	stx d1ddrb      ;keyboard inputs
	stx d2ddrb      ;user port (no rs-232)
	stx sidreg+24   ;turn off sid
	dex
	stx d1ddra      ;keyboard outputs
	lda #%00000111  ;set serial/va14/15 (clkhi)
	sta d2pra
	lda #%00111111  ;set serial in/out, va14/15out
	sta d2ddra
.else
	; XXX TODO: VIC-20: $FDF9
.endif
;
; set up banking
;
	; XXX TODO
;
;jsr clkhi ;clkhi to release serial devices  ^
;
iokeys	lda #<sixty     ;keyboard scan irq's
	sta d2t1l
	lda #>sixty
	sta d2t1h
	lda #$c0        ;enable t1 irq's
	sta d2ier
	jmp clklo       ;release the clock line***901227-03***
;
; sixty hertz value
;
sixty	= 17045         ; ntsc

setnam	sta fnlen
	stx fnadr
	sty fnadr+1
	rts

setlfs	sta la
	stx fa
	sty sa
	rts

readss	lda fa          ;see which devices' to read
	cmp #2          ;is it rs-232?
	bne readst      ;no...read serial/cass
	lda rsstat      ;yes...get rs-232 up
	pha
	lda #00         ;clear rs232 status when read
	sta rsstat
	pla
	rts
setmsg	sta msgflg
readst	lda status
udst	ora status
	sta status
	rts

settmo	sta timout
	rts

memtop	bcc settop
;
;carry set--read top of memory
;
gettop	ldx memsiz
	ldy memsiz+1
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
