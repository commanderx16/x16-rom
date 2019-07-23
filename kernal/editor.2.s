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
	lda shflag
	and #4
	beq mlp42
;
	lda #mhz
	ldy #0
mlp4	nop             ;delay
	dex
	bne mlp4
	dey
	bne mlp4
	sec
	sbc #1
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
kprend	lda d2t1l       ;clear interupt flags
	pla             ;restore registers
	tay
	pla
	tax
	pla
	rti             ;exit from irq routines

; ****** general keyboard scan ******
;
scnkey	ldx $9f70
	beq scnrts2
	cpx #$f0
	bne scn1
; key was released
	lda $9f70
	cmp #$76
	bne scnkey0
	lda #$ff        ;stop
	sta stkey
	rts
scnkey0	cmp #$12        ;lshift
	beq scnkey1
	cmp #$59        ;rshift
	beq scnkey1     ;BUG: rshift up can cancel lshift
	cmp #$11        ;lalt
	beq scnkey2
	cmp #$14        ;lctrl
	beq scnkey3
scnrts2	rts             ;otherwise ignore key up
scnkey1	lda #$ff-1      ;shift
	.byte $2c
scnkey2	lda #$ff-2      ;commodore
	.byte $2c
scnkey3	lda #$ff-4      ;control
	and shflag
	sta shflag
	rts
; extended set
scn1	cpx #$e0        ;extended set
	bne scn2
	lda $9f70
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
scn2	cpx #$76
	beq scn23
	cpx #$12        ;lshift
	beq scn22
	cpx #$59        ;rshift
	beq scn22
	cpx #$11        ;lalt
	beq scn21
	cpx #$14        ;lctrl
	bne scn20
	lda #4          ;control
	.byte $2c
scn21	lda #2          ;commodore
	.byte $2c
scn22	lda #1          ;shift
	.byte $2c
	ora shflag
	sta shflag
	rts
scn23	lda #$7f        ;stop
	sta stkey
; keys from the table
scn20	lda shflag
	lsr
	bcs scn10
	lsr
	bcs scn11
	lsr
	bcs scn12
	lda mode1,x     ;regular
	jmp scn3
scn12	lda contrl,x    ;+control
	jmp scn3
scn11	lda mode3,x     ;+commodore
	jmp scn3
scn10	lda mode2,x     ;+shift
scn3	ldx ndx         ;get # of chars in key queue
	cpx xmax        ;irq buffer full ?
	bcs scnrts      ;yes - no more insert
	sta keyd,x      ;put raw data here
	inx
	stx ndx         ;update key queue count
scnrts	rts

; rsr 12/08/81 modify for vic-40
; rsr  2/18/82 modify for 6526 input pad sense
; rsr  3/11/82 fix keyboard debounce, repair file
; rsr  3/11/82 modify for commodore 64
