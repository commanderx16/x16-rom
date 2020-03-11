;----------------------------------------------------------------------
; Channel: Load
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

;**********************************
;* load ram function              *
;*                                *
;* loads or verifies from serial  *
;* bus devices >=4 to 31 as       *
;* determined by contents of      *
;* variable fa.                   *
;*                                *
;* alt load if sa=0, normal sa=1  *
;* .x , .y load address if sa=0   *
;* .a=0 performs load to ram      *
;* .a=1 performs verify           *
;* .a>1 performs load to vram;    *
;*      (.a-2)&0x0f is the bank   *
;*      number.                   *
;*                                *
;* high load return in x,y,a      *
;*                                *
;**********************************

loadsp	stx memuss      ;.x has low alt start
	sty memuss+1
load	jmp (iload)     ;monitor load entry
;
nload	and #$1f
	sta verck       ;store verify flag
	dec verck
	lda #0
	sta status
;
	lda fa          ;check device number
	bne ld20
;
ld10	jmp error9      ;bad device #-keyboard
;
ld15	jmp error4      ;file not found
;
ld20	cmp #4
	bcc ld10        ;disallow load from screen or tape
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
	bcs ld15        ;file not found...
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
	ldy verck       ;are we loading into vram?
	beq ld40        ;no
	bmi ld40        ;no
;
;initialize vera registers
;
	dey
	tya
	and #$01        ;mask the bank number
	ora #$10        ;set vera increment = 1
	sta VERA_ADDR_H ;set the bank and increment
	lda eal
	sta VERA_ADDR_L ;set address bits 7:0
	lda eah
	sta VERA_ADDR_M ;set address bits 15:8
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
	ldy verck       ;what operation are we doing?
	bmi ld50        ;load into ram
	beq ld47        ;verify
;
	sta VERA_DATA0  ;write into vram
	bne ld60        ;branch always
;
ld47	cmp (eal),y     ;verify it
	beq ld60        ;o.k....
	lda #16         ;no good...verify error (sperr)
	jsr udst        ;update status
	bra ld60
;
ld50	ldy #0
	sta (eal),y
ld60	inc eal         ;increment store addr
	bne ld64
	inc eah
;
;if necessary, wrap to next bank
;
	lda eah
	cmp #$c0        ;reached top of high ram?
	bne ld64        ;no
	lda verck       ;check mode
	beq ld62        ;verify
	bpl ld64        ;loading into vram
ld62	lda #$a0        ;wrap to bottom of high ram
	sta eah
	inc $9f61       ;move to next ram bank

ld64	bit status      ;eoi?
	bvc ld40        ;no...continue load
;
	jsr untlk       ;close channel
	jsr clsei       ;close the file
	jsr prnto
;
;set up return values
;
	lda verck
	clc
	bmi ld80
	beq ld80
	ldx VERA_ADDR_L
	ldy VERA_ADDR_M
	lda VERA_ADDR_H
	and #$01
	rts
ld80	ldx eal
	ldy eah
	lda #0
	rts

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
	bne ld410       ;are doing load
	ldy #ms21-ms1   ;are 'verifying'
ld410	jsr spmsg
	bit msgflg      ;printing messages?
	bpl frmto1      ;no...
	lda verck       ;check flag
	beq frmto1      ;skip if verify
	ldy #ms7-ms1    ;"from $"
msghex	jsr msg
	lda eah
	jsr hex8
	lda eal
hex8	tax
	lsr
	lsr
	lsr
	lsr
	jsr hex4
	txa
	and #$0f
hex4	cmp #$0a
	bcc hex010
	adc #$06
hex010	adc #$30
	jmp prt
frmto1	rts
prnto	bit msgflg      ;printing messages?
	bpl frmto1      ;no...
	lda verck       ;check flag
	beq frmto1      ;skip if verify
	ldy #ms8-ms1    ;"to $"
	bne msghex      ;branch always
