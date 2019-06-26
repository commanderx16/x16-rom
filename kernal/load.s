;**********************************
;* load ram function              *
;*                                *
;* loads from cassette 1 or 2, or *
;* serial bus devices >=4 to 31   *
;* as determined by contents of   *
;* variable fa. verify flag in .a *
;*                                *
;* alt load if sa=0, normal sa=1  *
;* .x , .y load address if sa=0   *
;* .a=0 performs load,<> is verify*
;*                                *
;* high load return in x,y.       *
;*                                *
;**********************************

loadsp	stx memuss      ;.x has low alt start
	sty memuss+1
load	jmp (iload)     ;monitor load entry
;
nload	sta verck       ;store verify flag
	lda #0
	sta status
;
	lda fa          ;check device number
	bne ld20
;
ld10	jmp error9      ;bad device #-keyboard
;
ld20	cmp #3
	beq ld10        ;disallow screen load
	bcc ld100       ;handle tapes different
;
;load from cbm ieee device
;
	ldy fnlen       ;must have file name
	bne ld25        ;yes...ok
;
	jmp error8      ;missing file name
;
ld25	ldx sa          ;save sa in .x
	jsr luking      ;tell user looking
	lda #$60        ;special load command
	sta sa
	jsr openi       ;open the file
;
	lda fa
	jsr talk        ;establish the channel
	lda sa
	jsr tksa        ;tell it to load
;
	jsr acptr       ;get first byte
	sta eal
;
	lda status      ;test status for error
	lsr a
	lsr a
	bcs ld90        ;file not found...
	jsr acptr
	sta eah
;
	txa             ;find out old sa
	bne ld30        ;sa<>0 use disk address
	lda memuss      ;else load where user wants
	sta eal
	lda memuss+1
	sta eah
ld30	jsr loding      ;tell user loading
;
ld40	lda #$fd        ;mask off timeout
	and status
	sta status
;
	jsr stop        ;stop key?
	bne ld45        ;no...
;
	jmp break       ;stop key pressed
;
ld45	jsr acptr       ;get byte off ieee
	tax
	lda status      ;was there a timeout?
	lsr a
	lsr a
	bcs ld40        ;yes...try again
	txa
	ldy verck       ;performing verify?
	beq ld50        ;no...load
	ldy #0
	cmp (eal),y      ;verify it
	beq ld60        ;o.k....
	lda #16         ;no good...verify error (sperr)
	jsr udst        ;update status
	.byt $2c        ;skip next store
;
ld50	sta (eal),y
ld60	inc eal         ;increment store addr
	bne ld64
	inc eah
ld64	bit status      ;eoi?
	bvc ld40        ;no...continue load
;
	jsr untlk       ;close channel
	jsr clsei       ;close the file
	bcc ld180       ;branch always
;
ld90	jmp error4      ;file not found
;
;load from tape
;
ld100
	jmp error9      ;bad device #
ld180	clc             ;good exit
;
; set up end load address
;
	ldx eal
	ldy eah
;
ld190	rts

;subroutine to print to console:
;
;searching [for name]
;
luking	lda msgflg      ;supposed to print?
	bpl ld115       ;...no
	ldy #ms5-ms1    ;"searching"
	jsr msg
	lda fnlen
	beq ld115
	ldy #ms6-ms1    ;"for"
	jsr msg

;subroutine to output file name
;
outfn	ldy fnlen       ;is there a name?
	beq ld115       ;no...done
	ldy #0
ld110	lda (fnadr),y
	jsr bsout
	iny
	cpy fnlen
	bne ld110
;
ld115	rts

;subroutine to print:
;
;loading/verifing
;
loding	ldy #ms10-ms1   ;assume 'loading'
	lda verck       ;check flag
	beq ld410       ;are doing load
	ldy #ms21-ms1   ;are 'verifying'
ld410	jmp spmsg

