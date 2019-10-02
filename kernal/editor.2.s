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
	cpx nlinesm1    ;done?
	bcs scr41       ;branch if so
;
	lda #0          ;setup from pntr
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
newlx	lda sal
	pha
	lda sah
	pha
	ldx nlines
scd10	dex
	jsr setpnt      ;set up to addr
	cpx lintmp
	bcc scr40
	beq scr40       ;branch if finished
	lda #0          ;set from addr
	sta sal
	lda ldtb1-1,x
	jsr scrlin      ;scroll this line down
	bmi scd10
scr40
	jsr clrln
	ldx nlinesm2
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

	;destination into addr1
	lda #$10
	sta verahi
	lda pnt
	sta veralo
	lda pnt+1
	sta veramid

	lda #1
	sta veractl

	;source into addr2
	lda #$10
	sta verahi
	lda sal
	sta veralo
	lda sal+1
	sta veramid

	lda #0
	sta veractl

	ldy llenm1
scd20	lda veradat2    ;character
	sta veradat
	lda veradat2    ;color
	sta veradat
	dey
	bpl scd20
	rts
;
; set up pnt and y
; from .x
;
setpnt	lda #0
	sta pnt
	lda ldtb1,x
	and #scrmsk
	ora hibase
	sta pnt+1
	rts
;
; clear the line pointed to by .x
;
clrln	ldy llen
	jsr setpnt
	lda pnt
	sta veralo      ;set base address
	lda pnt+1
	sta veramid
	lda #$10        ;auto-increment = 1
	sta verahi
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
dspp	ldy #2
	sty blnct       ;blink cursor
dspp2	ldy pntr
	jsr stapnty
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
	php
	jsr ldapnty     ;get character
	inc blnon       ;set to 1
	plp
	bcs key5        ;branch if not needed
	sta gdbln       ;save original char
	lda veradat     ;get original color
	sta gdcol       ;save it
	ldx color       ;blink in this color
	lda gdbln       ;with original character
;
key5
	bit isomod
	bpl key3
	cmp #$9f
	bne key2
	lda gdbln
	.byte $2c
key2	lda #$9f
	.byte $2c
key3	eor #$80        ;blink it
	jsr dspp2       ;display it
;
key4
	jsr scnkey      ;scan keyboard
;
kprend
.if 0 ; VIA#2 timer IRQ for 60 Hz
	lda d1t1l       ;clear interupt flags
.else
	lda #1
	sta veraisr
.endif
	ply             ;restore registers
	plx
	pla
	rti             ;exit from irq routines

; rsr 12/08/81 modify for vic-40
; rsr  2/18/82 modify for 6526 input pad sense
; rsr  3/11/82 fix keyboard debounce, repair file
; rsr  3/11/82 modify for commodore 64
