panic	jsr clschn      ;warm start basic...
	lda #0          ;clear channels
	sta channl
	jsr stkini      ;restore stack
	cli             ;enable irq's

ready	ldx #$80
	jmp (ierror)
nerror	txa             ;get  high bit
	bmi nready
	jmp nerrox
nready	jmp readyx

init	jsr initv       ;go init vectors
	jsr initcz      ;go init charget & z-page
	jsr initms      ;go print initilization messages
init2	ldx #stkend-256 ;set up end of stack
	txs
	bne ready       ;jmp...ready

initat	inc chrget+7
	bne chdgot
	inc chrget+8
chdgot	lda 60000
	cmp #':'
	bcs chdrts
	cmp #' '
	beq initat
	sec
	sbc #'0'
	sec
	sbc #$d0
chdrts	rts
inrndx	.byt 128,79,199,82,88

initcz	lda #76
	sta jmper
	sta usrpok
	lda #<fcerr
	ldy #>fcerr
	sta usrpok+1
	sty usrpok+2
	ldx #inrndx-initat-1
movchg	lda initat,x
	sta chrget,x
	dex
	bpl movchg
	ldx #initcz-inrndx-1
movch2	lda inrndx,x
	sta rndx,x
	dex
	bpl movch2
	lda #strsiz
	sta four6
	lda #0
	sta bits
	sta channl
	sta lastpt+1
	ldx #1
	stx buf-3
	stx buf-4
	ldx #tempst
	stx temppt
	sec             ;read bottom of memory
	jsr $ff9c
	stx txttab      ;now txtab has it
	sty txttab+1
	sec
	jsr $ff99       ;read top of memory
usedef	stx memsiz
	sty memsiz+1
	stx fretop
	sty fretop+1
	ldy #0
	tya
	sta (txttab),y
	inc txttab
	bne init20
	inc txttab+1
init20	rts

initms	lda txttab
	ldy txttab+1
	jsr reason
	lda #<fremes
	ldy #>fremes
	jsr strout
	sec
	jsr $ff99       ;read num ram banks
	tax
	bne initm2
	ldx #<2048
	lda #>2048
	bne initm3
initm2	sta facho
	lda #0
	asl facho
	rol
	asl facho
	rol
	asl facho
	rol
	ldx facho
initm3	jsr linprt
	lda #<freme2
	ldy #>freme2
	jsr strout
	lda memsiz
	sec
	sbc txttab
	tax
	lda memsiz+1
	sbc txttab+1
	jsr linprt
	lda #<words
	ldy #>words
	jsr strout
	jmp scrtch

bvtrs	.word nerror,nmain,ncrnch,nqplop,ngone,neval
;
initv	ldx #initv-bvtrs-1 ;init vectors
initv1	lda bvtrs,x
	sta ierror,x
	dex
	bpl initv1
	rts
chke0	.byt $00

fremes
	.byt $8f, $93
	.byt $9c, $df, $12, $20, $20, $df, $92, $20, $20, $20, $12, $a9, $20, $20, $92, $a9, 13
	.byt $9a, $20, $df, $12, $20, $20, $df, $92, $20, $12, $a9, $20, $20, $92, $a9
	.byt 5, "  **** COMMANDER X16 BASIC V2 ****", 13
	.byt $9f, $20, $20, $df, $12, $20, $20, $92, $20, $12, $20, $20, $92, $a9, 13
	.byt $1e, $20, $20, $20, $20, $12, $20, $92, $20, $12, $20, $92
	.byt 5, "     ",0

freme2	.byt "K HIGH RAM"
.ifdef PRERELEASE_VERSION
	.byte " - ROM VERSION R"
.if PRERELEASE_VERSION >= 100
	.byte (PRERELEASE_VERSION / 100) + '0'
.endif
.if PRERELEASE_VERSION >= 10
	.byte ((PRERELEASE_VERSION / 10) .mod 10) + '0'
.endif
	.byte (PRERELEASE_VERSION .mod 10) + '0'
.endif
	.byte 13
	.byt $9e, $20, $20, $12, $a9, $20, $20, $92, $20, $12, $20, $20, $df, 13
	.byt $81, $20, $12, $a9, $20, $20, $92, $a9, $20, $df, $12, $20, $20, $df, $92
	.byt 5, "  ", 0


words	.byt " BASIC BYTES FREE",13
	.byt $1c, $12, $a9, $20, $20, $92, $a9, $20, $20, $20, $df, $12, $20, $20, $df, 13
	.byt 5, 0
; ppach - print# patch to coout (save .a)
;
ppach	pha
	jsr $ffc9
	tax             ;save error code
	pla
	bcc ppach0      ;no error....
	txa             ;error code
ppach0	rts

;rsr 8/10/80 update panic :rem could use in error routine
;rsr 2/08/82 modify for vic-40 release
;rsr 4/15/82 add advertising sign-on
