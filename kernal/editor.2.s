scrsz   =$4000          ;screen ram size, rounded up to power of two
scrmsk  =(>scrsz)-1     ;for masking offset in screen ram

;screen scroll routine
;
scrol	lda sal
	pha
	lda sah
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
	and #scrmsk     ;clear any garbage stuff
	ora hibase      ;put in hiorder bits
	sta sal+1
.if 0                   ;slow version
	lda #llen-1
	sta eal
scd20
	lda #$10
	sta veractl
	lda eal
	asl
	clc
	adc sal
	sta veralo
	lda sal+1
	adc #0
	sta verahi
	lda veradat     ;character
	pha
	ldy veradat     ;color
	lda eal
	asl
	clc
	adc pnt
	sta veralo
	lda pnt+1
	adc #0
	sta verahi
	pla
	sta veradat     ;character
	sty veradat     ;color
	dec eal
	bpl scd20
.else                   ;fast version that uses 20 bytes of zero page
	lda #0
scd20	sta eal

	lda #$10
	sta veractl
	lda eal
	clc
	adc sal
	sta veralo
	lda sal+1
	adc #0
	sta verahi

	ldy #20-1
scd21	lda veradat
	sta tmpscrl,y
	dey
	bpl scd21

	lda eal
	clc
	adc pnt
	sta veralo
	lda pnt+1
	adc #0
	sta verahi

	ldy #20-1
scd22	lda tmpscrl,y
	sta veradat
	dey
	bpl scd22

	lda eal
	clc
	adc #20
	cmp #llen*2-1
	bcc scd20
	lda #$ff; to make bmi happy
.endif
	rts
;
; set up pnt and y
; from .x
;
setpnt	lda ldtb2,x
	sta pnt
	lda ldtb1,x
	and #scrmsk
	ora hibase
	sta pnt+1
	rts
;
; clear the line pointed to by .x
;
clrln	ldy #llen
	jsr setpnt
	lda pnt
	sta veralo      ;set base address
	lda pnt+1
	sta verahi
	lda #$10        ;auto-increment = 1
	sta veractl
clr10	lda #$20
	sta veradat     ;store space
	lda color       ;always clear to current foregnd color
	sta veradat
	dey
	bne clr10
	rts

;
;put a char on the screen
;
dspp	tay             ;save char
	lda #2
	sta blnct       ;blink cursor
	tya             ;restore color
dspp2	pha
	lda pntr        ;set address
	asl
	clc
	adc pnt
	sta veralo
	lda pnt+1
	adc #0
	sta verahi
	lda #$10        ;auto-increment = 1
	sta veractl
	pla
	sta veradat     ;store character
	stx veradat     ;color to screen
	rts

key	jsr $ffea       ;update jiffy clock
	lda blnsw       ;blinking crsr ?
	bne key4        ;no
	dec blnct       ;time to blink ?
	bne key4        ;no
	lda #20         ;reset blink counter
repdo	sta blnct
	ldy pntr        ;cursor position
	lsr blnon       ;carry set if original char
	ldx gdcol       ;get char original color
	jsr ldapnty     ;get character
	bcs key5        ;branch if not needed
;
	inc blnon       ;set to 1
	sta gdbln       ;save original char
	lda veradat     ;get original color
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
kprend
.ifdef C64
	lda d1icr       ;clear interupt flags
.else
	lda d2t1l       ;clear interupt flags
.endif
	pla             ;restore registers
	tay
	pla
	tax
	pla
	rti             ;exit from irq routines

; ****** general keyboard scan ******
;
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
	cpy lstx        ;same as prev char index?
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
	ldy sfdx        ;get index of key
	sty lstx        ;save this index to key found
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
scnrts	lda #$7f        ;setup pb7 for stop key sense
	sta colm
	rts

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

switch
	; XXX TODO: switch upper/lower case character set
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

; rsr 12/08/81 modify for vic-40
; rsr  2/18/82 modify for 6526 input pad sense
; rsr  3/11/82 fix keyboard debounce, repair file
; rsr  3/11/82 modify for commodore 64
