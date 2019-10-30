.import kbdmeta, ikbdmeta

	.segment "EDITOR"
maxchr=80
nwrap=2 ;max number of physical lines per logical line
;
;undefined function entry
;
; undefd ldx #0
; undef2 lda unmsg,x
; jsr prt
; inx
; cpx #unmsg2-unmsg
; bne undef2
; sec
; rts
;
; unmsg .byt $d,'?advanced function not available',$d
; unmsg2
;
;return address of first 6522
;
iobase
	ldx #<via1
	ldy #>via1
	rts
;
;return max rows,cols of screen
;
scrorg	ldx llen
	ldy nlines
	rts
;
;read/plot cursor position
;
plot	bcs plot10
xmon1	stx tblx
	sty pntr
	jsr stupt
plot10	ldx tblx
	ldy pntr
	rts

;
;set screen size
;
scnsiz	stx llen
	dex
	stx llenm1
	sty nlines
	iny
	sty nlinesp1
	dey
	dey
	sty nlinesm1
	dey
	sty nlinesm2
	jmp clsr ; clear screen

;
; set keyboard layout .a
;
setkbd	tay
	lda isomod
	bne setkb0
	lda #<kbdmeta
	ldx #>kbdmeta
	bne setkb3
setkb0	lda #<ikbdmeta
	ldx #>ikbdmeta
setkb3	sta 2
	stx 3
	lda #2
	sta fetvec
	tya
setkb2	sta curkbd
	asl
	asl
	asl
	asl             ;*16
	tay
	ldx #BANK_KEYBD
	jsr fetch
	beq setkb2      ;end of list? set #0
	ldx #0
setkb1	phx
	ldx #BANK_KEYBD
	jsr fetch
	plx
	sta kbdnam,x    ;8 bytes kbnam, 8  bytes kbtab
	inx
	iny
	cpx #16
	bne setkb1
	rts

;initialize i/o
;
cint	jsr iokeys

	jsr mseinit     ;init mouse

;
; establish screen memory
;
	jsr panic       ;set up vic

	lda #2
	jsr scrmod      ;set screen mode to default
;
	lda #0          ;make sure we're in pet mode
	sta mode
	sta blnon       ;we dont have a good char from the screen yet

	lda $9fbe       ;emulator detection
	cmp #'1'
	bne nemu
	lda $9fbf
	cmp #'6'
	bne nemu
	lda $9fbd       ;emulator keyboard layout
	.byte $2c
nemu	lda #0          ;US layout
	jsr setkbd
	lda #10
	sta xmax        ;maximum type ahead buffer size
	sta delay
	lda #blue << 4 | white
	sta color       ;init text color
	lda #$c
	sta blnct
	sta blnsw
clsr	lda hibase      ;fill hi byte ptr table
	ora #$80
	tay
	lda #0
	tax
lps1	pha
	tya
	sta ldtb1,x
	pla
	iny             ;carry bump hi byte
lps2	inx
	cpx nlinesp1    ;done # of lines?
	bne lps1        ;no...
	lda #$ff        ;tag end of line table
	sta ldtb1,x
	ldx nlinesm1    ;clear from the bottom line up
clear1	jsr clrln       ;see scroll routines
	dex
	bpl clear1

;home function
;
nxtd	ldy #0
	sty pntr        ;left column
	sty tblx        ;top line
;
;move cursor to tblx,pntr
;
stupt
	ldx tblx        ;get curent line index
	lda pntr        ;get character pointer
fndstr	ldy ldtb1,x     ;find begining of line
	bmi stok        ;branch if start found
	clc
	adc llen        ;adjust pointer
	sta pntr
	dex
	bpl fndstr
;
stok	jsr setpnt      ;set up pnt indirect 901227-03**********
;
	lda llenm1
	inx
fndend	ldy ldtb1,x
	bmi stdone
	clc
	adc llen
	inx
	bpl fndend
stdone
	sta lnmx
	rts

; this is a patch for input logic 901227-03**********
;   fixes input"xxxxxxx-40-xxxxx";a$ problem
;
finput	cpx lsxp        ;check if on same line
	beq finpux      ;yes..return to send
	jmp findst      ;check if we wrapped down...
finpux	rts

;panic nmi entry
;
vpan	jsr panic       ;fix vic screen
	jmp nxtd        ;home cursor

panic	lda #3          ;reset default i/o
	sta dflto
	lda #0
	sta dfltn

;init video
;
initv
	lda #0
	sta veractl     ;set ADDR1 active

	jsr cpypet1

	lda #$00        ;$F3000: layer 1 registers
	sta veralo
	lda #$30
	sta veramid
	lda #$1f
	sta verahi

	ldx #0
px4	lda tvera_layer1,x
	sta veradat
	inx
	cpx #tvera_layer1_end-tvera_layer1
	bne px4

	lda #$00        ;$F0000: composer registers
	sta veralo
	sta veramid
	ldx #0
px5	lda tvera_composer,x
	sta veradat
	inx
	cpx #tvera_composer_end-tvera_composer
	bne px5
	rts

inicpy	lda #<tilbas
	sta veralo
	lda #>tilbas
	sta veramid
	lda #$10 | (tilbas >> 16)
	sta verahi
	rts

; PETSCII character set
cpypet1	jsr inicpy
	lda #0
	sta data
	sta tmp2
	lda #$c0
	sta tmp2+1       ;character data at ROM 0000
	ldx #4
	jsr copyv
	dec data
	lda #$c0
	sta tmp2+1       ;character data at ROM 0000
	ldx #4
	jmp copyv

cpypet2	jsr inicpy
	lda #0
	sta data
	sta tmp2
	lda #$c4
	sta tmp2+1       ;character data at ROM 0400
	ldx #4
	jsr copyv
	dec data
	lda #$c4
	sta tmp2+1       ;character data at ROM 0400
	ldx #4
	jmp copyv

; ISO character set
cpyiso	jsr inicpy
	lda #0
	sta data
	sta tmp2
	lda #$c8
	sta tmp2+1       ;character data at ROM 0800
	ldx #8
;
copyv	ldy #0
px3	lda (tmp2),y
	eor data
	sta veradat
	iny
	bne px3
	inc tmp2+1
	dex
	bne px3
	rts

;NTSC=1

tvera_layer1
	.byte 0 << 5 | 1  ;mode=0, enabled=1
	.byte 1 << 2 | 2  ;maph=64, mapw=128
	.word mapbas >> 2 ;map_base
	.word tilbas >> 2 ;tile_bas
	.word 0, 0        ;hscroll, vscroll
tvera_layer1_end

mapbas	=0
tilbas	=$0f800         ;top of bank 0 of VRAM

.ifdef NTSC
; ***** NTSC (with overscan)
hstart  =46
hstop   =591
vstart  =35
vstop   =444

tvera_composer
	.byte 2           ;NTSC
	.byte 150, 150    ;hscale, vscale
	.byte 14          ;border color
	.byte <hstart
	.byte <hstop
	.byte <vstart
	.byte <vstop
	.byte (vstop >> 8) << 5 | (vstart >> 8) << 4 | (hstop >> 8) << 2 | (hstart >> 8)
tvera_composer_end
.else
; ***** VGA
hstart  =0
hstop   =640
vstart  =0
vstop   =480

tvera_composer
	.byte 1           ;VGA
	.byte 128, 128    ;hscale, vscale
	.byte 14          ;border color
	.byte <hstart
	.byte <hstop
	.byte <vstart
	.byte <vstop
	.byte (vstop >> 8) << 5 | (vstart >> 8) << 4 | (hstop >> 8) << 2 | (hstart >> 8)
tvera_composer_end
.endif

;
;remove character from queue
;
lp2	ldy keyd
	ldx #0
lp1	lda keyd+1,x
	sta keyd,x
	inx
	cpx ndx
	bne lp1
	dec ndx
	tya
	cli
	clc             ;good return
	rts
;
loop4	jsr prt
loop3
	lda ndx
	sta blnsw
	sta autodn      ;turn on auto scroll down
	beq loop3
	sei
	lda blnon
	beq lp21
	lda gdbln
	ldx gdcol       ;restore original color
	ldy #0
	sty blnon
	jsr dspp
lp21	jsr lp2
	cmp #$83        ;run key?
	bne lp22
	ldx #9
	sei
	stx ndx
lp23	lda runtb-1,x
	sta keyd-1,x
	dex
	bne lp23
	beq loop3
lp22	pha
	sec
	sbc #$85         ;f1 key?
	bcc lp29
	cmp #8
	bcs lp29         ;beyond f8
	cmp #4
	rol              ;convert to f1-f8 -> 0-7
	and #7
	ldx #0
	tay
	beq lp27
lp25	lda fkeytb,x     ;search for replacement
	beq lp26
	inx
	bne lp25
lp26	inx
	dey
	bne lp25
lp27	lda fkeytb,x
	sta keyd,y
	beq lp28
	inx
	iny
	bne lp27
lp28	sty ndx
	pla
loop3a	jmp loop3
;
lp29	pla
	cmp #$d
	bne loop4
	ldy lnmx
	sty crsw
clp5
	jsr ldapnty
	cmp #' '
	bne clp6
	dey
	bne clp5
clp6	iny
	sty indx
	ldy #0
	sty autodn      ;turn off auto scroll down
	sty pntr
	sty qtsw
	lda lsxp
	bmi lop5
	ldx tblx
	jsr finput      ;check for same line as start  901227-03**********
	cpx lsxp
	bne lop5
	lda lstp
	sta pntr
	cmp indx
	bcc lop5
	bcs clp2

;input a line until carriage return
;
loop5	tya
	pha
	txa
	pha
	lda crsw
	beq loop3a
lop5	ldy pntr
	jsr ldapnty
notone
	sta data
	bit isomod
	bmi lop53
lop51	and #$3f
	asl data
	bit data
	bpl lop54
	ora #$80
lop54	bcc lop52
	ldx qtsw
	bne lop53
lop52	bvs lop53
	ora #$40
lop53	inc pntr
	jsr qtswc
	cpy indx
	bne clp1
clp2	lda #0
	sta crsw
	lda #$d
	ldx dfltn       ;fix gets from screen
	cpx #3          ;is it the screen?
	beq clp2a
	ldx dflto
	cpx #3
	beq clp21
clp2a	jsr prt
clp21	lda #$d
clp1	sta data
	pla
	tax
	pla
	tay
	lda data
	bit isomod
	bmi clp7
	cmp #$de        ;is it <pi> ?
	bne clp7
	lda #$ff
clp7	clc
	rts

qtswc	cmp #$22
	bne qtswl
	lda qtsw
	eor #$1
	sta qtsw
	lda #$22
qtswl	rts

nxt33
	bit isomod
	bmi nc3
	ora #$40
nxt3	ldx rvs
	beq nvs
nc3	ora #$80
nvs	ldx insrt
	beq nvs1
	dec insrt
nvs1	ldx color       ;put color on screen
	jsr dspp
	jsr wlogic      ;check for wraparound
loop2	pla
	tay
	lda insrt
	beq lop2
	lsr qtsw
lop2	pla
	tax
	pla
	clc             ;good return
	cli
	rts

wlogic
	jsr chkdwn      ;maybe we should we increment tblx
	inc pntr        ;bump charcter pointer
	lda lnmx        ;
	cmp pntr        ;if lnmx is less than pntr
	bcs wlgrts      ;branch if lnmx>=pntr
	cmp #maxchr-1   ;past max characters
	beq wlog10      ;branch if so
	lda autodn      ;should we auto scroll down?
	beq wlog20      ;branch if not
	jmp bmt1        ;else decide which way to scroll

wlog20
	ldx tblx        ;see if we should scroll down
	cpx nlines 
	bcc wlog30      ;branch if not
	jsr scrol       ;else do the scrol up
	dec tblx        ;and adjust curent line#
	ldx tblx
wlog30	asl ldtb1,x     ;wrap the line
	lsr ldtb1,x
	inx             ;index to next lline
	lda ldtb1,x     ;get high order byte of address
	ora #$80        ;make it a non-continuation line
	sta ldtb1,x     ;and put it back
	dex             ;get back to current line
	lda lnmx        ;continue the bytes taken out
	clc
	adc llen
	sta lnmx
findst
	lda ldtb1,x     ;is this the first line?
	bmi finx        ;branch if so
	dex             ;else backup 1
	bne findst
finx
	jmp setpnt      ;make sure pnt is right

wlog10	dec tblx
	jsr nxln
	lda #0
	sta pntr        ;point to first byte
wlgrts	rts

bkln	ldx tblx
	bne bkln1
	stx pntr
	pla
	pla
	bne loop2
;
bkln1	dex
	stx tblx
	jsr stupt
	ldy lnmx
	sty pntr
	rts

;print routine
;
prt	pha
	sta data
	txa
	pha
	tya
	pha
	lda #0
	sta crsw
	ldy pntr
	lda data
	bpl *+5
	jmp nxtx
	ldx qtsw
	cpx #2          ;"no exceptions" quote mode (used by monitor)
	beq njt1
	cmp #$d
	bne njt1
	jmp nxt1
njt1	cmp #' '
	bcc ntcn
	bit isomod
	bmi njt9
	cmp #$60        ;lower case?
	bcc njt8        ;no...
	and #$df        ;yes...make screen lower
	bne njt9        ;always
njt8	and #$3f
njt9	jsr qtswc
	jmp nxt3
ntcn	ldx insrt
	beq cnc3x
	bit isomod
	bpl cnc3y
	jmp nvs
cnc3y	jmp nc3
cnc3x	cmp #$14
	bne ntcn1
	tya
	bne bak1up
	jsr bkln
	jmp bk2
bak1up	jsr chkbak      ;should we dec tblx
	dey
	sty pntr
bk15	iny
	jsr ldapnty
	dey
	jsr stapnty
	iny
	jsr ldausery
	dey
	jsr stausery
	iny
	cpy lnmx
	bne bk15
bk2	lda #' '
	jsr stapnty
	lda color
	jsr stausery
	bpl jpl3
ntcn1	ldx qtsw
	beq nc3w
	bit isomod
	bpl cnc3
	jmp nvs
cnc3	jmp nc3
nc3w	cmp #$12
	bne nc1
	bit isomod
	bmi nc1
	sta rvs
nc1	cmp #$13
	bne nc2
	jsr nxtd
nc2	cmp #$1d
	bne ncx2
	iny
	jsr chkdwn
	sty pntr
	dey
	cpy lnmx
	bcc ncz2
	dec tblx
	jsr nxln
	ldy #0
jpl4	sty pntr
ncz2	jmp loop2
ncx2	cmp #$11
	bne colr1
	clc
	tya
	adc llen
	tay
	inc tblx
	cmp lnmx
	bcc jpl4
	beq jpl4
	dec tblx
curs10	sbc llen
	bcc gotdwn
	sta pntr
	bne curs10
gotdwn	jsr nxln
jpl3	jmp loop2
colr1	jsr chkcol      ;check for a color
	jmp lower       ;was jmp loop2

;check color
;

;shifted keys
;
nxtx
keepit
	and #$7f
	bit isomod
	bmi nxtx1
	cmp #$7f
	bne nxtx1
	lda #$5e
nxtx1
nxtxa
	cmp #$20        ;is it a function key
	bcc uhuh
	jmp nxt33
uhuh
	ldx qtsw
	cpx #2
	beq up5
	cmp #$d
	bne up5
	jmp nxt1
up5	ldx  qtsw
	bne up6
	cmp #$14
	bne up9
	ldy lnmx
	jsr ldapnty
	cmp #' '
	bne ins3
	cpy pntr
	bne ins1
ins3	cpy #maxchr-1
	beq insext      ;exit if line too long
	jsr newlin      ;scroll down 1
ins1	ldy lnmx
ins2	dey
	jsr ldapnty
	iny
	jsr stapnty
	dey
	jsr ldausery
	iny
	jsr stausery
	dey
	cpy pntr
	bne ins2
	lda #$20
	jsr stapnty
	lda color
	jsr stausery
	inc insrt
insext	jmp loop2
up9	ldx insrt
	beq up2
up6
	bit isomod
	bmi up1
	ora #$40
up1	jmp nc3
up2	cmp #$11
	bne nxt2
	ldx tblx
	beq jpl2
	dec tblx
	lda pntr
	sec
	sbc llen
	bcc upalin
	sta pntr
	bpl jpl2
upalin	jsr stupt
	bne jpl2
nxt2	cmp #$12
	bne nxt6
	lda #0
	sta rvs
nxt6	cmp #$1d
	bne nxt61
	tya
	beq bakbak
	jsr chkbak
	dey
	sty pntr
	jmp loop2
bakbak	jsr bkln
	jmp loop2
nxt61	cmp #$13
	bne sccl
	jsr clsr
jpl2	jmp loop2
sccl
	ora #$80        ;make it upper case
	jsr chkcol      ;try for color
	jmp upper       ;was jmp loop2
;
nxln	lsr lsxp
	ldx tblx
nxln2	inx
	cpx nlines      ;off bottom?
	bne nxln1       ;no...
	jsr scrol       ;yes...scroll
nxln1	lda ldtb1,x     ;double line?
	bpl nxln2       ;yes...scroll again
	stx tblx
	jmp stupt
nxt1
	ldx #0
	stx insrt
	stx rvs
	stx qtsw
	stx pntr
	jsr nxln
jpl5	jmp loop2
;
;
; check for a decrement tblx
;
chkbak	ldx #nwrap
	lda #0
chklup	cmp pntr
	beq back
	clc
	adc llen
	dex
	bne chklup
	rts
;
back	dec tblx
	rts
;
; check for increment tblx
;
chkdwn	ldx #nwrap
	lda llenm1
dwnchk	cmp pntr
	beq dnline
	clc
	adc llen
	dex
	bne dwnchk
	rts
;
dnline	ldx tblx
	cpx nlines
	beq dwnbye
	inc tblx
;
dwnbye	rts

chkcol
	ldx #15         ;there's 15 colors
chk1a	cmp coltab,x
	beq chk1b
	dex
	bpl chk1a
	rts
;
chk1b
	lda color
	and #$f0        ;keep bg color
	stx color
	ora color
	sta color       ;change the color
	rts

coltab
;blk,wht,red,cyan,magenta,grn,blue,yellow
	.byt $90,$05,$1c,$9f,$9c,$1e,$1f,$9e
	.byt $81,$95,$96,$97,$98,$99,$9a,$9b

ldausery
	tya
	sec
	rol
	bcc ldapnt2 ; always

ldapnty	tya
	cmp llen
	bcc ldapnt1
	sec
	sbc llen
	asl
	sta veralo
	lda pnt+1
	adc #1 ; C=0
	bne ldapnt3

ldapnt1	asl
ldapnt2	sta veralo
	lda pnt+1
ldapnt3	sta veramid
	lda #$10
	sta verahi
	lda veradat
	rts

stausery
	pha
	tya
	sec
	rol
	bcc stapnt2 ; always

stapnty	pha
	tya
	cmp llen
	bcc stapnt1
	sec
	sbc llen
	asl
	sta veralo
	lda pnt+1
	adc #1 ; C=0
	bne stapnt3

stapnt1	asl
stapnt2	sta veralo
	lda pnt+1
stapnt3	sta veramid
	lda #$10
	sta verahi
	pla
	sta veradat
	rts

; rsr modify for vic-40 system
; rsr 12/31/81 add 8 more colors
