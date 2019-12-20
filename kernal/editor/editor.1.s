.import kbd_config, kbd_scan, kbd_clear, kbd_put, kbd_get, kbd_remove, kbd_get_modifiers, kbd_get_stop ; [ps2kbd]
.import mouse_init ; [ps2mouse]

; editor_vera
.import initv
.import scrmod
.import cpychr
.import ldausery
.import stausery
.import ldapnty
.import stapnty
.import dspp2
.import setpnt
.import scrlin
.import clrln
.export llen
.export scnsiz

maxchr=80
nwrap=2 ;max number of physical lines per logical line


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
	sty nlines
	iny
	sty nlinesp1
	dey
	dey
	sty nlinesm1
	jmp clsr ; clear screen

;initialize i/o
;
cint	jsr iokeys

	jsr mouse_init  ;init mouse

;
; establish screen memory
;
	jsr panic       ;set up vic

	lda #2
	sec
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
	bra :+
nemu	lda #0          ;US layout
:	jsr kbd_config
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
	lda llen
	dec
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

;
loop4	jsr prt
loop3
	jsr kbd_get
	sta blnsw
	sta autodn      ;turn on auto scroll down
	beq loop3
	pha
	sei
	lda blnon
	beq lp21
	lda gdbln
	ldx gdcol       ;restore original color
	ldy #0
	sty blnon
	jsr dspp
lp21	cli
	pla
	cmp #$83        ;run key?
	bne lp22
; put SHIFT+STOP text into keyboard buffer
	jsr kbd_clear
	ldx #0
:	lda runtb,x
	jsr kbd_put
	inx
	cpx #runtb_end-runtb
	bne :-
	bra loop3

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
lp27	jsr kbd_clear
lp24	lda fkeytb,x
	jsr kbd_put
	tay              ;set flags
	beq lp28
	inx
	bne lp24
lp28	pla
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
	bit mode
	bvs lop53       ;ISO
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
	bit mode
	bvs clp7        ;ISO
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
	bit mode
	bvs nc3         ;ISO
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
prt
.if 0
	pha
	lda blnsw
	beq @1
	pla
	.import GRAPH_put_char
	pha
	phx
	phy
	jsr GRAPH_put_char
	ply
	plx
	pla
	clc
	rts

@1:	pla
.endif

	pha
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
	bit mode
	bvs njt9        ;ISO
	cmp #$60        ;lower case?
	bcc njt8        ;no...
	and #$df        ;yes...make screen lower
	bne njt9        ;always
njt8	and #$3f
njt9	jsr qtswc
	jmp nxt3
ntcn	ldx insrt
	beq cnc3x
	bit mode
	bvc cnc3y       ;not ISO
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
; move line left
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
; insert space
bk2	lda #' '
	jsr stapnty
	lda color
	jsr stausery
	bpl jpl3
ntcn1	ldx qtsw
	beq nc3w
	bit mode
	bvc cnc3        ;not ISO
	jmp nvs
cnc3	jmp nc3
nc3w	cmp #$12
	bne nc1
	bit mode
	bvs nc1         ;ISO
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
	bit mode
	bvs nxtx1       ;ISO
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
; check whether last char in line is a space
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
; move line right
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
; insert space
	lda #$20
	jsr stapnty
	lda color
	jsr stausery
	inc insrt
insext	jmp loop2
up9	ldx insrt
	beq up2
up6
	bit mode
	bvs up1         ;ISO
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
	lda llen
	dec
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
        cmp #$01    ; check ctrl-a for invert.
        bne ntinv
        lda color    ; get current text color.
        asl a        ; swap msn/lsn.
        adc #$80
        rol a
        asl a
        adc #$80
        rol a
        sta color    ; stash back.
        rts
ntinv
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

;screen scroll routine
;
scrol
;
;   s c r o l l   u p
;
scro0	ldx #$ff
	dec tblx
	dec lsxp
	dec lintmp
scr10	inx             ;goto next line
	jsr setpnt      ;point to 'to' line
	cpx nlinesm1    ;done?
	bcs scr41       ;branch if so
;
	phx
	inx
	jsr scrlin      ;scroll this line up1
	plx
	bra scr10
;
scr41
	jsr clrln
;
	ldx #0          ;scroll hi byte pointers
scrl5	lda ldtb1,x
	and #$7f
	ldy ldtb1+1,x
	bpl scrl3
	ora #$80
scrl3	sta ldtb1,x
	inx
	cpx nlinesm1
	bne scrl5
;
	ldy nlinesm1
	lda ldtb1,y
	ora #$80
	sta ldtb1,y
	lda ldtb1       ;double line?
	bpl scro0       ;yes...scroll again
;
	inc tblx
	inc lintmp
	jsr kbd_get_modifiers
	and #4
	beq mlp42
;
	lda #<mhz
	ldy #0
mlp4	nop             ;delay
	dex
	bne mlp4
	dey
	bne mlp4
	sec
	sbc #1
	bne mlp4
	jsr kbd_clear   ;clear key queue buffer
;
mlp42	ldx tblx
;
pulind	rts

newlin
	ldx tblx
bmt1	inx
	lda ldtb1,x     ;find last display line of this line
	bpl bmt1        ;table end mark=>$ff will abort...also
bmt2	stx lintmp      ;found it
;generate a new line
	cpx nlinesm1    ;is one line from bottom?
	beq newlx       ;yes...just clear last
	bcc newlx       ;<nlines...insert line
	jsr scrol       ;scroll everything
	ldx lintmp
	dex
	dec tblx
	jmp wlog30
newlx	ldx nlines
scd10	dex
	jsr setpnt      ;set up to addr
	cpx lintmp
	bcc scr40
	beq scr40       ;branch if finished
	phx
	dex
	jsr scrlin      ;scroll this line down
	plx
	bra scd10
scr40
	jsr clrln
	ldx nlines
	dex
	dex
scrd21
	cpx lintmp      ;done?
	bcc scrd22      ;branch if so
	lda ldtb1+1,x
	and #$7f
	ldy ldtb1,x     ;was it continued
	bpl scrd19      ;branch if so
	ora #$80
scrd19	sta ldtb1+1,x
	dex
	bne scrd21
scrd22
	ldx lintmp
	jmp wlog30

;
;put a char on the screen
;
dspp	ldy #2
	sty blnct       ;blink cursor
	ldy pntr
	jmp dspp2

.import get_char_col

cursor_blink:
	lda blnsw       ;blinking crsr ?
	bne @5          ;no
	dec blnct       ;time to blink ?
	bne @5          ;no

	VERA_SAVE
	lda #20         ;reset blink counter
	sta blnct
	ldy pntr        ;cursor position
	lsr blnon       ;carry set if original char
	php
	jsr get_char_col;get character and color
	inc blnon       ;set to 1
	plp
	bcs @1          ;branch if not needed
	sta gdbln       ;save original char
	stx gdcol       ;save original color
	ldx color       ;blink in this color
@1	bit mode
	bvc @3          ;not ISO
	cmp #$9f
	bne @2
	lda gdbln
	bra @4
@2	lda #$9f
	bra @4
@3	eor #$80        ;blink it
@4	ldy pntr
	jsr dspp2       ;display it
	VERA_RESTORE

@5	rts
