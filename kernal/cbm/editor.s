;----------------------------------------------------------------------
; Editor
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

.ifp02
.macro stz addr
	php
	pha
	lda #0
	sta addr
	pla
	plp
.endmacro
.endif

;screen editor constants
;
maxchr=80
nwrap=2 ;max number of physical lines per logical line

.export plot   ; set cursor position
.export scrorg ; return screen size
.export cint   ; initialize screen
.export prt    ; print character
.export loop5  ; input a line until carriage return

.importzp mhz  ; constant

.import dfltn, dflto ; XXX

.import iokeys
.import panic

; kernal
.export crsw
.export indx
.export lnmx
.export lstp
.export lsxp
.export cursor_blink
.export tblx
.export pntr

; screen driver
.import screen_mode
.import screen_set_charset
.import screen_get_color
.import screen_set_color
.import screen_get_char
.import screen_set_char
.import screen_set_char_color
.import screen_get_char_color
.import screen_set_position
.import screen_copy_line
.import screen_clear_line
.import screen_save_state
.import screen_restore_state
.export llen
.export scnsiz
.export color

; keyboard driver
.import kbd_config, kbd_scan, kbdbuf_clear, kbdbuf_put, kbdbuf_get, kbd_remove, kbdbuf_get_modifiers, kbdbuf_get_stop

; beep driver
.import beep

.import emulator_get_data

.include "banks.inc"
.include "mac.inc"

.segment "KVAR2" ; more KERNAL vars
; XXX TODO only one bit per byte is used, this should be compressed!
ldtb1	.res 61 +1       ;flags+endspace
	;       ^^ XXX at label 'lps2', the code counts up to
	;              numlines+1, THEN writes the end marker,
	;              which seems like one too many. This was
	;              worked around for now by adding one more
	;              byte here, but we should have a look at
	;              whether there's an off-by-one error over
	;              at 'lps2'!

; Screen
;
.export mode; [ps2kbd]
.export data; [cpychr]
mode	.res 1           ;    bit7=1: charset locked, bit6=1: ISO
gdcol	.res 1           ;    original color before cursor
autodn	.res 1           ;    auto scroll down flag(=0 on,<>0 off)
lintmp	.res 1           ;    temporary for line index
color	.res 1           ;    activ color nybble
rvs	.res 1           ;$C7 rvs field on flag
indx	.res 1           ;$C8
lsxp	.res 1           ;$C9 x pos at start
lstp	.res 1           ;$CA
blnsw	.res 1           ;$CC cursor blink enab
blnct	.res 1           ;$CD count to toggle cur
gdbln	.res 1           ;$CE char before cursor
blnon	.res 1           ;$CF on/off blink flag
crsw	.res 1           ;$D0 input vs get flag
pntr	.res 1           ;$D3 pointer to column
qtsw	.res 1           ;$D4 quote switch
lnmx	.res 1           ;$D5 40/80 max positon
tblx	.res 1           ;$D6
data	.res 1           ;$D7
insrt	.res 1           ;$D8 insert mode flag
llen	.res 1           ;$D9 x resolution
nlines	.res 1           ;$DA y resolution
nlinesp1 .res 1          ;    X16: y resolution + 1
nlinesm1 .res 1          ;    X16: y resolution - 1
verbatim .res 1

.segment "EDITOR"

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
	php
	sei
	phx
	phy
	lda blnon
	beq :+
	lda gdbln
	ldx gdcol       ;restore original color
	ldy #0
	sty blnon
	jsr dspp
:	ply
	plx
	stx tblx
	sty pntr
	jsr stupt
	plp
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

;
; establish screen memory
;
	jsr panic       ;set up vic

	; XXX this is too specific
	lda #0          ;80x60
	clc
	jsr screen_mode ;set screen mode to default
;
	lda #0          ;make sure we're in pet mode
	sta mode
	sta blnon       ;we dont have a good char from the screen yet

	jsr emulator_get_data
	jsr kbd_config  ;set keyboard layout

	lda #$c
	sta blnct
	sta blnsw

clsr	lda #$80        ;fill end of line table
	ldx #0
lps1	sta ldtb1,x
	inx
	cpx nlinesp1    ;done # of lines?
	bne lps1        ;no...
	lda #$ff        ;tag end of line table
	sta ldtb1,x
	ldx nlinesm1    ;clear from the bottom line up
clear1	jsr screen_clear_line ;see scroll routines
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
stok	jsr screen_set_position
;
	lda llen
.ifp02
	clc
	sbc #1
.else
	dec
.endif
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

;
loop4	jsr prt
loop3
	jsr kbdbuf_get
	sta blnsw
	sta autodn      ;turn on auto scroll down
	beq loop3
	pha
	php
	sei
	lda blnon
	beq lp21
	lda gdbln
	ldx gdcol       ;restore original color
	ldy #0
	sty blnon
	jsr dspp
lp21	plp             ;restore I
	pla
	cmp #$83        ;run key?
	bne lp22
; put SHIFT+STOP text into keyboard buffer
	jsr kbdbuf_clear
	ldx #0
:	lda runtb,x
	jsr kbdbuf_put
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
lp27	jsr kbdbuf_clear
lp24	lda fkeytb,x
	jsr kbdbuf_put
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
	jsr screen_get_char
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
	cpx lsxp        ;check if on same line
	beq finpux      ;yes..return to send
	jsr findst      ;check if we wrapped down...
finpux	cpx lsxp
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
	jsr screen_get_char
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
lop53

; verbatim mode:
; if the character is reverse or >= $60, return 0
	bit verbatim
	stz verbatim
	bpl @0
	cmp #$60
	bcs @2a
@1:	pha
	jsr screen_get_char ; again
	bmi @2
	pla
	bra @0
@2:	pla
@2a:	lda #0
@0:

	inc pntr
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
	jmp screen_set_position ;make sure pnt is right

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
; verbatim mode
	bit verbatim
	bpl @prt0

	bit mode
	bvc :+          ;skip if PETSCII
; ISO: "no exceptions" quote mode
	pha
	lda #2
	sta qtsw
	pla
	inc insrt
	bra @l2
; PETSCII: handle ranges manually
:	cmp #$20
	bcs :+
	inc rvs
	ora #$40        ;$00-$1F: reverse, add $40
:	cmp #$80
	bcc @l2         ;$20-$7F: printable character
	cmp #$A0
	bcs @l2         ;$A0-$FF: printable character
	inc rvs
	and #$7F
	ora #$60        ;$80-$9F: reverse, clear MSB, add $60
@l2:	jsr @prt1
	stz verbatim
	stz rvs
	stz qtsw
	and #$ff        ;set flags
	rts

@prt0:	cmp #$80
	bne @prt1
	ror verbatim    ;C=1, enable
	and #$ff        ;set flags
	rts

@prt1:	pha
	sta data
	txa
	pha
	tya
	pha
	lda #0
	sta crsw
	ldy pntr
	lda data
	bpl :+
	jmp nxtx
:	ldx qtsw
	cpx #2          ;"no exceptions" quote mode?
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
	jsr screen_get_char
	dey
	jsr screen_set_char
	iny
	jsr screen_get_color
	dey
	jsr screen_set_color
	iny
	cpy lnmx
	bne bk15
; insert space
bk2	lda #' '
	jsr screen_set_char
	lda color
	jsr screen_set_color
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

	cmp #$0e        ;does he want lower case?
	bne upper       ;branch if not
	bit mode
	bvs outhre      ;ISO
	lda #3
	jsr screen_set_charset
	jmp loop2

upper
	cmp #$8e        ;does he want upper case
	bne lock        ;branch if not
	bit mode
	bvs outhre      ;ISO
	lda #2
	jsr screen_set_charset
outhre	jmp loop2

lock
	cmp #8          ;does he want to lock in this mode?
	bne unlock      ;branch if not
	lda #$80        ;else set lock switch on
	ora mode        ;don't hurt anything - just in case
	bmi lexit

unlock
	cmp #9          ;does he want to unlock the keyboard?
	bne isoon       ;branch if not
	lda #$7f        ;clear the lock switch
	and mode        ;dont hurt anything
lexit	sta mode
	jmp loop2       ;get out

isoon
	cmp #$0f        ;switch to ISO mode?
	bne isooff      ;branch if not
	lda #1
	jsr screen_set_charset
	lda mode
	ora #$40
	bra isosto

isooff
	cmp #$8f        ;switch to PETSCII mode?
	bne bell        ;branch if not
	lda #2
	jsr screen_set_charset
	lda mode
	and #$ff-$40
isosto	sta mode
	lda #$ff
	jsr kbd_config  ;reload keymap
	jsr clsr        ;clear screen
	jmp loop2

bell
	cmp #$07        ;bell?
	bne outhre      ;branch if not
	jsr beep
	jmp loop2

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
	cpx #2          ;"no exceptions" quote mode?
	beq up5
	cmp #$d
	bne up5
	jmp nxt1
up5	ldx qtsw
	bne up6
	cmp #$14
	bne up9
; check whether last char in line is a space
	ldy lnmx
	jsr screen_get_char
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
	jsr screen_get_char
	iny
	jsr screen_set_char
	dey
	jsr screen_get_color
	iny
	jsr screen_set_color
	dey
	cpy pntr
	bne ins2
; insert space
	lda #$20
	jsr screen_set_char
	lda color
	jsr screen_set_color
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
	bne up3
	ldx #0          ;scroll screen DOWN!
	jsr bmt2        ;insert line at top of screen
	lda ldtb1
	ora #$80        ;first line is not an extension
	sta ldtb1
	jsr stupt
	bra jpl2
up3	dec tblx
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
.ifp02
	clc
	sbc #1
.else
	dec
.endif
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
        cmp #1          ;check ctrl-a for invert.
        bne ntinv
        lda color       ;get current text color.
        asl a           ;swap msn/lsn.
        adc #$80
        rol a
        asl a
        adc #$80
        rol a
        sta color       ;stash back.
        lda #1          ;restore .a
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
	pha
	lda color
	and #$f0        ;keep bg color
	stx color
	ora color
	sta color       ;change the color
	pla             ;restore .a
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
	jsr screen_set_position ;point to 'to' line
	cpx nlinesm1    ;done?
	bcs scr41       ;branch if so
;
.ifp02
	txa
	pha
.else
	phx
.endif
	inx
	jsr screen_copy_line ;scroll this line up1
.ifp02
	pla
	tax
.else
	plx
.endif
	bra scr10
;
scr41
	jsr screen_clear_line
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
	jsr kbdbuf_get_modifiers
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
	jsr kbdbuf_clear
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
	jsr screen_set_position ;set up to addr
	cpx lintmp
	bcc scr40
	beq scr40       ;branch if finished
.ifp02
	txa
	pha
.else
	phx
.endif
	dex
	jsr screen_copy_line ;scroll this line down
.ifp02
	pla
	tax
.else
	plx
.endif
	bra scd10
scr40
	jsr screen_clear_line
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
	jmp screen_set_char_color

cursor_blink:
	lda blnsw       ;blinking crsr ?
	bne @5          ;no
	dec blnct       ;time to blink ?
	bne @5          ;no

	jsr screen_save_state
	lda #20         ;reset blink counter
	sta blnct
	ldy pntr        ;cursor position
	lsr blnon       ;carry set if original char
	php
	jsr screen_get_char_color
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
	jsr screen_set_char_color       ;display it
	jsr screen_restore_state

@5	rts


runtb	.byt "LOAD",$d,"RUN:",$d
runtb_end:

fkeytb	.byt "LIST:", 13, 0
	.byt "MONITOR:", 13, 0
	.byt "RUN:", 13, 0
	.byt $93, "S", 'C' + $80, "255", 13, 0
	.byt "LOAD", 13, 0
	.byt "SAVE", '"', 0
	.byt "DOS",'"', "$",13, 0
	.byt "DOS", '"', 0
