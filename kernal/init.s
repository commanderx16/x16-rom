.import ps2_init ; [ps2]
; mouse driver
.import mouse_init

.export membot
.export memtop
.export rambks

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
iokeys
	jsr mouse_init  ;init mouse

	lda #1
	sta veraien     ;VERA VSYNC IRQ for 60 Hz
	jmp clklo       ;release the clock line***901227-03***

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

;
;return address of first 6522
;
iobase
	ldx #<via1
	ldy #>via1
	rts

; rsr 8/5/80 change io structure
; rsr 8/15/80 add memory test
; rsr 8/21/80 change i/o for mod
; rsr 8/25/80 change i/o for mod2
; rsr 8/29/80 change ramtest for hardware mistake
; rsr 9/22/80 change so ram hang rs232 status read
; rsr 5/12/82 change start1 order to remove disk problem
