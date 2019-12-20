
.export membot
.export memtop

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
	lda (tmp2),y    ;...want user to storage
movos2	sta (tmp2),y    ;put in user
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
settop	sta rambks
	stx memsiz
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
