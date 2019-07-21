scrsz=$1000 ; must be power of two
scrlo=(>scrsz)-1 ; for masking offset in screen ram

;screen scroll routine
;
scrol	lda sal
	pha
	lda sah
	pha
	lda eal
	pha
	lda eah
	pha
;
;   s c r o l l   u p
;
scro0	ldx #$ff
	dec tblx
	dec lsxp
	dec lintmp
scr10	inx             ;goto next line
	jsr setpnt      ;point to 'to' line
	cpx #nlines-1   ;done?
	bcs scr41       ;branch if so
;
	lda ldtb2+1,x   ;setup from pntr
	sta sal
	lda ldtb1+1,x
	jsr scrlin      ;scroll this line up1
	bmi scr10
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
	cpx #nlines-1
	bne scrl5
;
	lda ldtb1+nlines-1
	ora #$80
	sta ldtb1+nlines-1
	lda ldtb1       ;double line?
	bpl scro0       ;yes...scroll again
;
	inc tblx
	inc lintmp
; XXX TODO
	lda #$7f        ;check for control key
	sta colm        ;drop line 2 on port b
	lda rows
	cmp #$fb        ;slow scroll key?(control)
	php             ;save status. restore port b
	lda #$7f        ;for stop key check
	sta colm
	plp
	bne mlp42
;
	ldy #0
mlp4	nop             ;delay
	dex
	bne mlp4
	dey
	bne mlp4
	sty ndx         ;clear key queue buffer
;
mlp42	ldx tblx
;
pulind	pla             ;restore old indirects
	sta eah
	pla
	sta eal
	pla
	sta sah
	pla
	sta sal
	rts

newlin
	ldx tblx
bmt1	inx
; cpx #nlines ;exceded the number of lines ???
; beq bmt2 ;vic-40 code
	lda ldtb1,x     ;find last display line of this line
	bpl bmt1        ;table end mark=>$ff will abort...also
bmt2	stx lintmp      ;found it
;generate a new line
	cpx #nlines-1   ;is one line from bottom?
	beq newlx       ;yes...just clear last
	bcc newlx       ;<nlines...insert line
	jsr scrol       ;scroll everything
	ldx lintmp
	dex
	dec tblx
	jmp wlog30
newlx	lda sal
	pha
	lda sah
	pha
	lda eal
	pha
	lda eah
	pha
	ldx #nlines
scd10	dex
	jsr setpnt      ;set up to addr
	cpx lintmp
	bcc scr40
	beq scr40       ;branch if finished
	lda ldtb2-1,x   ;set from addr
	sta sal
	lda ldtb1-1,x
	jsr scrlin      ;scroll this line down
	bmi scd10
scr40
	jsr clrln
	ldx #nlines-2
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
	jsr wlog30
;
	jmp pulind      ;go pul old indirects and return
;
; scroll line from sal to pnt
;
scrlin
	and #scrlo      ;clear any garbage stuff
	ora hibase      ;put in hiorder bits
	sta sal+1
	jsr tofrom      ;color to & from addrs
	lda #llen-1
	sta eal
scd20
	lda #$10
	sta $9f20
	lda eal
	asl
	clc
	adc sal
	sta $9f22
	lda sal+1
	adc #0
	sta $9f21
	lda $9f23       ;character
	pha
	ldy $9f23       ;color
	lda eal
	asl
	clc
	adc pnt
	sta $9f22
	lda pnt+1
	adc #0
	sta $9f21
	pla
	sta $9f23       ;character
	sty $9f23       ;color
	dec eal
	bpl scd20
	rts
;
; do color to and from addresses
; from character to and from adrs
;
tofrom
	jsr scolor
	lda sal         ;character from
	sta eal         ;make color from
	lda sal+1
	and #scrlo
	ora #>viccol
	sta eal+1
	rts
;
; set up pnt and y
; from .x
;
setpnt	lda ldtb2,x
	sta pnt
	lda ldtb1,x
	and #scrlo
	ora hibase
	sta pnt+1
	rts
;
; clear the line pointed to by .x
;
clrln	ldy #llen-1
	jsr setpnt
	jsr scolor
	lda #$10        ;auto-increment 1
	sta $9f20
	lda pnt+1
	sta $9f21
	lda pnt
	sta $9f22       ;set base address
clr10	lda #$20
	sta $9f23       ;store space
	lda color       ;always clear to current foregnd color
	sta $9f23
	dey
	bpl clr10
	rts

;
;put a char on the screen
;
dspp	tay             ;save char
	lda #2
	sta blnct       ;blink cursor
	jsr scolor      ;set color ptr
	tya             ;restore color
dspp2	pha
	lda pntr        ;set address
	asl
	clc
	adc pnt
	sta $9f22
	lda pnt+1
	adc #0
	sta $9f21
	lda #$10
	sta $9f20
	pla
	sta $9f23       ;store character
	stx $9f23       ;color to screen
	rts

; XXX TODO remove
scolor	lda pnt         ;generate color ptr
	sta user
	lda pnt+1
	and #$03
	ora #>viccol    ;vic color ram
	sta user+1
	rts

key	jsr $ffea       ;update jiffy clock
	lda blnsw       ;blinking crsr ?
	bne key4        ;no
	dec blnct       ;time to blink ?
	bne key4        ;no
	lda #20         ;reset blink counter
repdo	sta blnct
	lsr blnon       ;carry set if original char
	ldx gdcol       ;get char original color

	lda pntr        ;set address
	asl
	clc
	adc pnt
	sta $9f22
	lda pnt+1
	adc #0
	sta $9f21
	lda #$10
	sta $9f20
	lda $9f23       ;get character
	bcs key5        ;branch if not needed
;
	inc blnon       ;set to 1
	sta gdbln       ;save original char
	lda $9f23       ;get original color
	sta gdcol       ;save it
	ldx color       ;blink in this color
	lda gdbln       ;with original character
;
key5	eor #$80        ;blink it
	jsr dspp2       ;display it
;
key4
	jsr scnkey      ;scan keyboard
;
kprend	lda d2t1l       ;clear interupt flags
	pla             ;restore registers
	tay
	pla
	tax
	pla
	rti             ;exit from irq routines

; ****** general keyboard scan ******
;
.if 0
scnkey	lda #$00
	sta shflag
	ldy #64         ;last key index
	sty sfdx        ;null key found
	sta colm        ;raise all lines
	ldx rows        ;check for a key down
	cpx #$ff        ;no keys down?
	beq scnout      ;branch if none
	tay             ;.a=0 ldy #0
	lda #<mode1
	sta keytab
	lda #>mode1
	sta keytab+1
	lda #$fe        ;start with 1st column
	sta colm
scn20	ldx #8          ;8 row keyboard
	pha             ;save column output info
scn22	lda rows
	cmp rows        ;debounce keyboard
	bne scn22
scn30	lsr a           ;look for key down
	bcs ckit        ;none
	pha
	lda (keytab),y  ;get char code
	cmp #$05
	bcs spck2       ;if not special key go on
	cmp #$03        ;could it be a stop key?
	beq spck2       ;branch if so
	ora shflag
	sta shflag      ;put shift bit in flag byte
	bpl ckut
spck2
	sty sfdx        ;save key number
ckut	pla
ckit	iny
	cpy #65
	bcs ckit1       ;branch if finished
	dex
	bne scn30
	sec
	pla             ;reload column info
	rol a
	sta colm        ;next column on keyboard
	bne scn20       ;always branch
ckit1	pla             ;dump column output...all done
	jmp (keylog)    ;evaluate shift functions
rekey	ldy sfdx        ;get key index
	lda (keytab),y   ;get char code
	tax             ;save the char
	cpx lstx        ;same as prev char index?
	beq rpt10       ;yes
	ldy #$10        ;no - reset delay before repeat
	sty delay
	bne ckit2       ;always
rpt10	and #$7f        ;unshift it
	bit rptflg      ;check for repeat disable
	bmi rpt20       ;yes
	bvs scnrts
	cmp #$7f        ;no keys ?
scnout	beq ckit2       ;yes - get out
	cmp #$14        ;an inst/del key ?
	beq rpt20       ;yes - repeat it
	cmp #$20        ;a space key ?
	beq rpt20       ;yes
	cmp #$1d        ;a crsr left/right ?
	beq rpt20       ;yes
	cmp #$11        ;a crsr up/dwn ?
	bne scnrts      ;no - exit
rpt20	ldy delay       ;time to repeat ?
	beq rpt40       ;yes
	dec delay
	bne scnrts
rpt40	dec kount       ;time for next repeat ?
	bne scnrts      ;no
	ldy #4          ;yes - reset ctr
	sty kount
	ldy ndx         ;no repeat if queue full
	dey
	bpl scnrts
ckit2
	stx lstx        ;save this index to key found
	ldy shflag      ;update shift status
	sty lstshf
ckit3	cpx #$ff        ;a null key or no key ?
	beq scnrts      ;branch if so
	txa             ;need x as index so...
	ldx ndx         ;get # of chars in key queue
	cpx xmax        ;irq buffer full ?
	bcs scnrts      ;yes - no more insert
putque
	sta keyd,x      ;put raw data here
	inx
	stx ndx         ;update key queue count
scnrts
	lda #$7f        ;setup pb7 for stop key sense
	sta colm
	rts
.else
scnkey	ldx $9f60
	beq scnrts2
	cpx #$f0
	bne scn1
	lda $9f60
	cmp #$12        ;lshift
	beq scnkey1
	cmp #$59        ;rshift
	beq scnkey1     ;BUG: rshift up can cancel lshift
scnrts2	rts             ;otherwise ignore key up
scnkey1	lda shflag
	and #$fe
	sta shflag
	rts
; extended set
scn1	cpx #$e0        ;extended set
	bne scn2
	lda $9f60
	cmp #$6b        ;csr left
	bne scn4
	lda #$9d
	bne scn3
scn4	cmp #$72        ;csr down
	bne scn5
	lda #$11
	bne scn3
scn5	cmp #$74        ;csr right
	bne scn6
	lda #$1d
	bne scn3
scn6	cmp #$75        ;csr up
	bne scn7
	lda #$91
	bne scn3
scn7	cmp #$6c        ;home
	bne scnrts
	lda shflag
	and #1
	beq scn8
	lda #$93
	bne scn3
scn8	lda #$13
	bne scn3
; modifier keys
scn2	cpx #$12        ;lshift
	beq scn21
	cpx #$59        ;rshift
	bne scn20
scn21	lda shflag
	ora #1
	sta shflag
	rts
; keys from the table
scn20	lda shflag
	and #1
	bne scn10
	lda scancode_to_petscii,x
	jmp scn3
scn10	lda scancode_to_petscii_shifted,x
scn3	ldx ndx         ;get # of chars in key queue
	cpx xmax        ;irq buffer full ?
	bcs scnrts      ;yes - no more insert
	sta keyd,x      ;put raw data here
	inx
	stx ndx         ;update key queue count
scnrts	rts

scancode_to_petscii:
; $00-$0f
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; $10-$1f
.byte $00,$00,$00,$00,$00,'Q','1',$00,$00,$00,'Z','S','A','W','2',$00
; $20-$2f
.byte $00,'C','X','D','E','4','3',$00,$00,' ','V','F','T','R','5',$00
; $30-$3f
.byte $00,'N','B','H','G','Y','6',$00,$00,$00,'M','J','U','7','8',$00
; $40-$4f
.byte $00,',','K','I','O','0','9',$00,$00,'.','/','L',';','P','-',$00
; $50-$5f
.byte $00,$00,$27,$00,'[','=',$00,$00,$00,$00,$0d,']',$00,'\',$00,$00
; $60-$6f
.byte $00,$00,$00,$00,$00,$00,$14,$00,$00,$00,$00,$00,$00,$00,$00,$00

scancode_to_petscii_shifted:
; $00-$0f
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; $10-$1f
.byte $00,$00,$00,$00,$00,'Q'+$80,'!',$00,$00,$00,'Z'+$80,'S'+$80,'A'+$80,'W'+$80,'@',$00
; $20-$2f
.byte $00,'C'+$80,'X'+$80,'D'+$80,'E'+$80,'$','#',$00,$00,' ','V'+$80,'F'+$80,'T'+$80,'R'+$80,'%',$00
; $30-$3f
.byte $00,'N'+$80,'B'+$80,'H'+$80,'G'+$80,'Y'+$80,'^',$00,$00,$00,'M'+$80,'J'+$80,'U'+$80,'7','8',$00
; $40-$4f
.byte $00,',','K'+$80,'I'+$80,'O'+$80,')','(',$00,$00,'.','?','L'+$80,';','P'+$80,'_',$00
; $50-$5f
.byte $00,$00,'"',$00,'{','+',$00,$00,$00,$00,$8d,'}',$00,'|',$00,$00
; $60-$6f
.byte $00,$00,$00,$00,$00,$00,$94,$00,$00,$00,$00,$00,$00,$00,$00,$00
.endif

.if 0
;
; shift logic
;
shflog
	lda shflag
	cmp #$03        ;commodore shift combination?
	bne keylg2      ;branch if not
	cmp lstshf      ;did i do this already
	beq scnrts      ;branch if so
	lda mode
	bmi shfout      ;dont shift if its minus

switch	; XXX TODO: switch upper/lower case character set
	jmp shfout

;
keylg2
	asl a
	cmp #$08        ;was it a control key
	bcc nctrl       ;branch if not
	lda #6          ;else use table #4
;
nctrl
notkat
	tax
	lda keycod,x
	sta keytab
	lda keycod+1,x
	sta keytab+1
shfout
	jmp rekey
.endif

; rsr 12/08/81 modify for vic-40
; rsr  2/18/82 modify for 6526 input pad sense
; rsr  3/11/82 fix keyboard debounce, repair file
; rsr  3/11/82 modify for commodore 64
