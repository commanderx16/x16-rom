; Commander X16 KERNAL
; based on GEOS by Berkeley Softworks; reversed by Maciej Witkowiak, Michael Steil
;
; Font library: drawing

.export GRAPH_get_char_size 

;
; For italics (actually slanted) characters, the original GEOS
; code moves one pixel to the right after every two scanlines:
;
;     X
;    X
;    X
;   X
;   X
;  X
;  X
; X
; X
;
; With this defined, it will move one pixel to the right every
; *four* scanlines:
;
;   X
;  X
;  X
;  X
;  X
; X
; X
; X
; X
;
; This looks way better and matches the slant of Helvetica
; Italics vs. Helvetica Regular (1/4.6) better.
;
less_slanted = 1	

;---------------------------------------------------------------
; GRAPH_get_char_size
;
; Function:  Returns the size of a character in the current
;            mode (bold, italic...) and current Font.
;
; Pass:      a   ASCII character
;            x   style
;
; Return:  printable character:
;            c   0
;            a   baseline offset
;            x   character width
;            y   character height
;          control character:
;            c   1
;            x   new style
;---------------------------------------------------------------
GRAPH_get_char_size:
	cmp #$20
	bcc @control
	cmp #$80
	bcc @1
	cmp #$a0
	bcc @control
@1:	jsr get_char_size
	phx
	phy ; XXX rewrite code below instead
	plx
	ply
	clc ; C=0: printable caracter
	rts

.macro x_or_imm_sec_rts imm
	txa
	ora #imm
	tax
	sec ; C=1: control character
	rts
.endmacro

@control:
	cmp #$04 ; underline
	bne :+
	x_or_imm_sec_rts SET_UNDERLINE
:	cmp #$06 ; bold
	bne :+
	x_or_imm_sec_rts SET_BOLD
:	cmp #$0b ; italics
	bne :+
	x_or_imm_sec_rts SET_ITALIC
:	cmp #$0c ; outline
	bne :+
	x_or_imm_sec_rts SET_OUTLINE
:	cmp #$92 ; attribute clear
	bne :+
	ldx #0
:	sec
	rts
	
get_char_size:
	subv $20
_GetRealSize2:
	jsr GetChWdth1
	tay
	txa
.ifndef bsw128
	ldx curHeight
	pha
.endif
	and #$40
	beq @1
	iny
@1:
.ifdef bsw128
	txa
.else
	pla
.endif
	and #8
.ifdef bsw128
	bne @2
	ldx curHeight
	lda baselineOffset
	rts
@2:	ldx curHeight
	inx
	inx
	iny
	iny
	lda baselineOffset
	addv 2
	rts
.else
	beq @2
	inx
	inx
	iny
	iny
	lda baselineOffset
	addv 2
	rts
@2:	lda baselineOffset
	rts
.endif ; bsw128

Font_1:
	ldy r1H
	iny
	sty fontTemp2
	sta r5L

.ifdef bsw128
	jsr GetChWdth1
.else
	ldx #0
	addv 32
	jsr get_char_size
	tya
.endif
	pha
	lda r5L
	asl
	tay
	lda (curIndexTable),y
	sta r2L
	and #%00000111
	sta FontTVar4
	lda r2L
	and #%11111000
	sta r3L
	iny
	lda (curIndexTable),y
	sta r2H
	pla
	add r2L
	sta r6H
	clc
	sbc r3L
	lsr
	lsr
	lsr
	sta r3H
	tax
	cpx #3
	bcc @1
	ldx #3
@1:	lda Font_tabL,x
	sta r13L
	lda Font_tabH,x
	sta r13H
	lda r2L
	lsr r2H
	ror
	lsr r2H
	ror
	lsr r2H
	ror
	add cardDataPntr
	sta r2L
	lda r2H
	adc cardDataPntr+1
	sta r2H
	ldy FontTVar4
	lda BitMaskLeadingSet,y
	eor #$ff
	sta FontTVar3
	ldy r6H
	dey
	tya
	and #%00000111
	tay
	lda BitMaskLeadingClear,y
	eor #$ff
	sta r7H
.ifdef bsw128
	ldy #$00
.endif
	lda currentMode
.ifndef bsw128
	tax
.endif
	and #SET_OUTLINE
	beq @2
.ifdef bsw128
	ldy #$80
@2:	sty r8H
.else
	lda #$80
@2:
	sta r8H
.endif
	lda r5L
.ifdef bsw128
	ldx currentMode
	jsr _GetRealSize2
.else
	addv 32
	jsr get_char_size
.endif
	sta r5H
	SubB r5H, r1H
	stx r10H
	tya
	pha
	lda r11H
	bmi @3
	CmpW rightMargin, r11
	bcc Font_16
@3:	lda currentMode
	and #SET_ITALIC
	bne @4
	tax
@4:	txa
	lsr
.ifdef less_slanted
	lsr
.endif
	sta r3L
	add r11L
	sta FontTVar2
	lda r11H
	adc #0
	sta FontTVar2+1
	PopB PrvCharWidth
	add FontTVar2
	sta r11L
	lda #0
	adc FontTVar2+1
	sta r11H
	bmi Font_17
	CmpW leftMargin, r11
	bcs Font_17
	jsr Font_2
	ldx #0
	lda currentMode
	and #SET_REVERSE
	beq @5
	dex
@5:	stx r10L
	clc
	rts

Font_16:
	PopB PrvCharWidth
	add r11L
	sta r11L
	bcc Font_18
	inc r11H
	sec
	rts

Font_17:
	SubB r3L, r11L
	bcs Font_18
	dec r11H
Font_18:
	sec
	rts

.define Font_tab FontGt1, FontGt2, FontGt3, FontGt4
Font_tabL:
	.lobytes Font_tab
Font_tabH:
	.hibytes Font_tab

GetChWdth1:
	cmp #$5f ; code $7F = DEL
	beq @2
	asl
	tay
	iny
	iny
	lda (curIndexTable),y
	dey
	dey
	sec
	sbc (curIndexTable),y
	rts
@2:	lda PrvCharWidth
	rts

Font_2:
	; find out effective x position:
	; if FontTVar2 is negative or left of leftMargin,
	; start at leftMargin
	lda FontTVar2
	ldx FontTVar2+1
	bmi @2
	cpx leftMargin+1
	bne @1
	cmp leftMargin
@1:	bcs @3
@2:	ldx leftMargin+1
	lda leftMargin
@3:	pha
	and #%11111000
	sta r4L

	tay
	PushW r1
	sty r0L
	stx r0H
	MoveB r1H, r1L
	stz r1H
	jsr FB_cursor_position
	PopW r1

	MoveB FontTVar2+1, r3L
	lsr r3L
	lda FontTVar2
	ror
	lsr r3L
	ror
	lsr r3L
	ror
	sta r7L
	lda leftMargin+1
	lsr
	lda leftMargin
	ror
	lsr
	lsr

	sub r7L
	bpl @7
	lda #0
@7:	sta FontTVar1
	lda FontTVar2
	and #%00000111
	sta r7L
	pla
	and #%00000111
	tay
	lda BitMaskLeadingSet,y
	sta r3L
	eor #$ff
	sta r9L
	ldy r11L
	dey
	ldx rightMargin+1
	lda rightMargin
	cpx r11H
	bne @8
	cmp r11L
@8:	bcs @9
	tay
@9:	tya
	and #%00000111
	tax
	lda BitMaskLeadingClear,x
	sta r4H
	eor #$ff
	sta r9H
	tya
	sub r4L
	bpl @A
	lda #0
@A:	lsr
	lsr
	lsr
	add FontTVar1
	sta r8L
	cmp r3H
	bcs @B
	lda r3H
@B:	cmp #3
	bcs @D
.ifndef bsw128
	cmp #2
	bne @C
	lda #1
@C:
.endif
	asl
	asl
	asl
	asl
	sta r12L
	lda r7L
	sub FontTVar4
	addv 8
	add r12L
	tax
	lda Font_tab2,x
.ifdef bsw128
	adc #<base
.else
	addv <base
.endif
	tay
	lda #0
	adc #>base
	bne @E
@D:	lda #>FontSH5
	ldy #<FontSH5
@E:	sta r12H
	sty r12L
.ifndef bsw128
clc_rts:
	clc
.endif
	rts

Font_tab2:
	.byte <(noop-base)
	.byte <(b7-base)
	.byte <(b6-base)
	.byte <(b5-base)
	.byte <(b4-base)
	.byte <(b3-base)
	.byte <(b2-base)
	.byte <(b1-base)
	.byte <(c0-base)
	.byte <(c1-base)
	.byte <(c2-base)
	.byte <(c3-base)
	.byte <(c4-base)
	.byte <(c5-base)
	.byte <(c6-base)
	.byte <(c7-base)
	.byte <(noop-base)
.ifdef bsw128
	.byte <(g7-base)
	.byte <(g6-base)
	.byte <(g5-base)
	.byte <(g4-base)
	.byte <(g3-base)
	.byte <(g2-base)
	.byte <(g1-base)
	.byte <(f0-base)
	.byte <(f1-base)
	.byte <(f2-base)
	.byte <(f3-base)
	.byte <(f4-base)
	.byte <(f5-base)
	.byte <(f6-base)
	.byte <(f7-base)
	.byte <(noop-base)
.endif
	.byte <(d7-base)
	.byte <(d6-base)
	.byte <(d5-base)
	.byte <(d4-base)
	.byte <(d3-base)
	.byte <(d2-base)
	.byte <(d1-base)
	.byte <(e0-base)
	.byte <(e1-base)
	.byte <(e2-base)
	.byte <(e3-base)
	.byte <(e4-base)
	.byte <(e5-base)
	.byte <(e6-base)
	.byte <(e7-base)

; called if currentMode & (SET_UNDERLINE | SET_ITALIC)
Font_3:
	lda currentMode
	bpl @2
	ldy r1H
	cpy fontTemp2
	beq @1
	dey
	cpy fontTemp2
	bne @2
@1:	lda r10L
	eor #$ff
	sta r10L
@2:
.ifdef wheels
	bbsf ITALIC_BIT, currentMode, @X
	clc
	rts
@X:
.else
	bbrf ITALIC_BIT, currentMode, clc_rts
.endif
	lda r10H
	lsr
	bcs @5
.ifdef less_slanted
	lsr
	bcs @5
.endif
	ldx FontTVar2
	bne @3
	dec FontTVar2+1
@3:	dex
	stx FontTVar2
	ldx r11L
	bne @4
	dec r11H
@4:	dex
	stx r11L
	jsr Font_2
@5:	CmpW rightMargin, FontTVar2
	bcc @6
	CmpW leftMargin, r11
.ifdef bsw128
	bcc clc_rts
.else
	rts
.endif
@6:
	sec
	rts
.ifdef bsw128
clc_rts:
	clc
        rts
.endif

Font_4:
	ldx FontTVar1
	cpx r8L
	beq @3 ; start == end -> one card
	bcs @4 ; start > end -> rts

; multiple cards

; first card
	lda r9L    ; mask for first card
	jsr Draw8Pixels
@1:	inx
	cpx r8L
	beq @2     ; end card

; middle cards
	lda #$ff
	jsr Draw8Pixels
	bra @1

; end card
@2:	lda r9H    ; mask for last card
	jmp Draw8Pixels

; single card
@3:	lda r9L
	and r9H
	jmp Draw8Pixels

@4:	rts

Font_5:
	ldx r8L
	lda #0
@1:	sta fontTemp2+1,x
	dex
	bpl @1
	lda r8H
	and #%01111111
	bne @5
@2:	jsr Font_8
@3:	ldx r8L
@4:	lda fontTemp2+1,x
	sta fontTemp1,x
	dex
	bpl @4
	inc r8H
	rts
@5:	cmp #1
	beq @6
	ldy r10H
	dey
	beq @2
	dey
	php
	jsr Font_8
	jsr Font_6
	plp
	beq @7
@6:	jsr Font_6
	jsr FntIndirectJMP
	jsr Font_8
	SubW curSetWidth, r2
@7:	jsr FntIndirectJMP
	jsr Font_8
	jsr Font_7
	bra @3

Font_6:
	AddW curSetWidth, r2
	rts

Font_7:
	ldy #$ff
@1:	iny
	ldx #7
@2:	lda fontTemp1,y
	and BitMaskPow2,x
	beq @3
	lda BitMaskPow2,x
	eor #$ff
	and fontTemp2+1,y
	sta fontTemp2+1,y
@3:	dex
	bpl @2
	cpy r8L
	bne @1
	rts

Font_8:
	jsr Font_9
	ldy #$ff
@1:	iny
	ldx #7
@2:	lda fontTemp1,y
	and BitMaskPow2,x
	beq @7
	lda fontTemp2+1,y
	ora BitMaskPow2,x
	sta fontTemp2+1,y
	inx
	cpx #8
	bne @3
	lda fontTemp2,y
	ora #1
	sta fontTemp2,y
.ifdef bsw128 ; XXX less efficient
	bra @4
.else
	bne @4
.endif
@3:	lda fontTemp2+1,y
	ora BitMaskPow2,x
	sta fontTemp2+1,y
@4:	dex
	dex
	bpl @5
	lda fontTemp2+2,y
	ora #$80
	sta fontTemp2+2,y
.ifdef bsw128
	bra @6 ; XXX less efficient
.else
	bne @6
.endif
@5:	lda fontTemp2+1,y
	ora BitMaskPow2,x
	sta fontTemp2+1,y
@6:	inx
@7:	dex
	bpl @2
	cpy r8L
	bne @1
	rts

Font_9:
	lsr fontTemp1
	ror fontTemp1+1
	ror fontTemp1+2
	ror fontTemp1+3
	ror fontTemp1+4
	ror fontTemp1+5
	ror fontTemp1+6
	ror fontTemp1+7
	rts


; central character printing, called from conio.s
; character - 32 in A
FontPutChar:
	tay
	PushB r1H
	tya
	jsr Font_1 ; put pointer in r13
	bcs @9 ; return
@1:	clc
	lda currentMode
	and #SET_UNDERLINE | SET_ITALIC
	beq @2
	jsr Font_3
@2:	php
	bcs @3
	jsr FntIndirectJMP ; call r13
@3:	bbrf 7, r8H, @4
	jsr Font_5
	bra @5
@4:	jsr Font_6
@5:	plp
	bcs @7
	lda r1H
	cmp windowTop
	bcc @7
	cmp windowBottom
	bcc @6
	bne @7
@6:	jsr Font_4
@7:
	jsr FB_cursor_next_line

	inc r1H
	dec r10H
	bne @1
@9:	PopB r1H
	rts

Draw8Pixels:
	ldy fontTemp1,x
	sty r0L    ; pixel pattern

	bit r10L   ; inverted/underlined?
	bmi Draw8PixelsInv

	; check for opaque mode
	lsr currentMode ; bit #0
	php
	rol currentMode
	plp
	bcs @5

	; transclucent, regular
	phx
	ldx col1 ; fg: primary color
	and r0L
	jsr FB_set_8_pixels
	plx
	rts

; opaque mode, regular
@5:	ldy col_bg  ; bg
	phx
	ldx col1 ; fg: primary color
	jsr FB_set_8_pixels_opaque
	plx
	rts

; inverted/underlined
Draw8PixelsInv:
	ldy col2 ; bg: secondary color
	phx
	ldx col1 ; fg: primary color
	jsr FB_set_8_pixels_opaque
	plx
	rts

FntIndirectJMP:
	ldy #0
	jmp (r13)

BitMaskPow2:
	.byte %00000001
	.byte %00000010
	.byte %00000100
	.byte %00001000
	.byte %00010000
	.byte %00100000
	.byte %01000000
	.byte %10000000
BitMaskLeadingSet:
	.byte %00000000
	.byte %10000000
	.byte %11000000
	.byte %11100000
	.byte %11110000
	.byte %11111000
	.byte %11111100
	.byte %11111110
BitMaskLeadingClear:
	.byte %01111111
	.byte %00111111
	.byte %00011111
	.byte %00001111
	.byte %00000111
	.byte %00000011
	.byte %00000001
	.byte %00000000
