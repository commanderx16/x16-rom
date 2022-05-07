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
boot	lda #0
	jsr setmsg
	ldx #bootfnlen-1
:	lda bootfn,x
	sta buf,x
	dex
	bpl :-
	ldx #<buf
	ldy #>buf
	lda #bootfnlen
	jsr setnam
	jsr getfa
	tax
	lda #1
	ldy #1
	jsr setlfs
	lda #0
	jsr load
	jsr readst
	and #$ff-$40 ; any error but EOI?
	beq :+       ; no
	jsr clear_disk_status
	jmp ready
:	stx vartab
	sty vartab+1    ;end load address
	jsr lnkprg
	jsr crdo
	jsr runc
	jmp newstt
bootfn:
	.byte "AUTOBOOT.X16"
bootfnlen=*-bootfn

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
	; line 0
	.byt $9c, $12, $df, $92, "     ", $12, $a9
	.byt $0d
	; line 1
	.byt $9a, $12, $b4, $df, $92, "   ", $12, $a9, $a7, $92
	.byt 5, " **** COMMANDER X16 BASIC V2 ****"
	.byt $0d
	; line 2
	.byt $9f, $12, $b5, " ", $df, $92, " ", $12, $a9, " ", $b6
	.byt $0d
	; line 3
	.byt $1e, " ", $b7, $12, $bb, $92, " ", $12, $ac, $92, $b7
	.byt 5, "  ",0
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
	.byt $0d
	; line 4
	.byt $9e, " ", $af, $12, $be, $92, " ", $12, $bc, $92, $af
	.byt $0d
	; line 5
	.byt $81, $a7, $12, " ", $92, $a9, " ", $df, $12, " ", $92, $b4
	.byt 5, " ", 0
words	.byt " BASIC BYTES FREE"
	.byt $0d
	; line 6
	.byt $1c, $b6, $a9, "   ", $df, $b5
	.byt $0d
	.byt 5
	.byt 0

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
