; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Font drawing

.setcpu "65c02"

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.import BitMaskPow2
.import FontSH5
.import base
.import BitMaskLeadingClear
.import BitMaskLeadingSet
.import GetChWdth1
.import _GetScanLine
.import FntIndirectJMP
.import b0, b1, b2, b3, b4, b5, b6, b7
.import c0, c1, c2, c3, c4, c5, c6, c7
.import d0, d1, d2, d3, d4, d5, d6, d7
.import e0, e1, e2, e3, e4, e5, e6, e7
.import f0, f1, f2, f3, f4, f5, f6, f7
.import g0, g1, g2, g3, g4, g5, g6, g7
.import noop
.import FontGt4
.import FontGt3
.import FontGt2
.import FontGt1

.if (!.defined(bsw128)) & (!.defined(wheels))
.import FontTVar1
.import FontTVar2
.endif

.ifdef bsw128
; XXX back bank, yet var lives on front bank!
PrvCharWidth = $880D
.else
.import PrvCharWidth
.endif

.ifdef bsw128
.import _TempHideMouse
.else
.import GetScanLine
.import GetRealSize
.endif

.global Font_9
.global FontPutChar
.global _GetRealSize

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

.segment "fonts2"

;---------------------------------------------------------------
; GetRealSize                                             $C1B1
;
; Function:  Returns the size of a character in the current
;            mode (bold, italic...) and current Font.
;
; Pass:      a   ASCII character
;            x   currentMode
; Return:    y   character width
;            x   character height
;            a   baseline offset
; Destroyed: nothing
;---------------------------------------------------------------
.ifndef wheels ; moved
_GetRealSize:
	subv 32
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
.endif

Font_1:
	ldy r1H
	iny
	sty E87FE
	sta r5L

.ifdef bsw128
	jsr GetChWdth1
.else
	ldx #0
	addv 32
	jsr GetRealSize
	tya
.endif
	pha
	lda r5L
	asl
	tay
	lda (curIndexTable),y
	sta r2L
	and #%00000111
	sta E87FD
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
	ldy E87FD
	lda BitMaskLeadingSet,y
	eor #$ff
	sta E87FC
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
	jsr GetRealSize
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

Font_2:
	ldx r1H
	jsr _GetScanLine
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
	clc
	adc r5L
	sta r5L
	sta veralo
	txa
	adc r5H
	sta r5H
	sta veramid
	lda #$11
	sta verahi

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
	sub E87FD
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

.ifdef wheels
	.res 9, 0 ; XXX
.endif

.ifdef wheels ; xxx moved, but unchanged
_GetRealSize:
	subv 32
	jsr GetChWdth1
	tay
	txa
	ldx curHeight
	pha
	and #$40
	beq @1
	iny
@1:	pla
	and #8
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

.endif

; called if currentMode & (SET_UNDERLINE | SET_ITALIC)
Font_3:
	lda currentMode
	bpl @2
	ldy r1H
	cpy E87FE
	beq @1
	dey
	cpy E87FE
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


.segment "fonts2"

Font_5:
	ldx r8L
	lda #0
@1:	sta E87FF,x
	dex
	bpl @1
	lda r8H
	and #%01111111
	bne @5
@2:	jsr Font_8
@3:	ldx r8L
@4:	lda E87FF,x
	sta Z45,x
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
@2:	lda Z45,y
	and BitMaskPow2,x
	beq @3
	lda BitMaskPow2,x
	eor #$ff
	and E87FF,y
	sta E87FF,y
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
@2:	lda Z45,y
	and BitMaskPow2,x
	beq @7
	lda E87FF,y
	ora BitMaskPow2,x
	sta E87FF,y
	inx
	cpx #8
	bne @3
	lda E87FE,y
	ora #1
	sta E87FE,y
.ifdef bsw128 ; XXX less efficient
	bra @4
.else
	bne @4
.endif
@3:	lda E87FF,y
	ora BitMaskPow2,x
	sta E87FF,y
@4:	dex
	dex
	bpl @5
	lda E8800,y
	ora #$80
	sta E8800,y
.ifdef bsw128
	bra @6 ; XXX less efficient
.else
	bne @6
.endif
@5:	lda E87FF,y
	ora BitMaskPow2,x
	sta E87FF,y
@6:	inx
@7:	dex
	bpl @2
	cpy r8L
	bne @1
	rts

Font_9:
	lsr Z45
	ror Z45+1
	ror Z45+2
	ror Z45+3
	ror Z45+4
	ror Z45+5
	ror Z45+6
	ror Z45+7
	rts

; central character printing, called from conio.s
; character - 32 in A
FontPutChar:
	tay
	PushB r1H
	tya
	jsr Font_1 ; put pointer in r13
	bcs @9 ; return
.ifdef bsw128
	jsr _TempHideMouse
	bbrf 7, graphMode, @1
	jmp FontPutChar80
.endif
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
@7:	lda r5L
	clc
	adc #<SC_PIX_WIDTH
	sta r5L
	sta veralo
	lda r5H
	adc #>SC_PIX_WIDTH
	sta r5H
	sta veramid
	inc r1H
	dec r10H
	bne @1
@9:	PopB r1H
	rts

.ifdef bsw128
; FontPutChar for 80 column mode
LE6E0:	lda r5L
	add #SCREENPIXELWIDTH/8
	sta r5L
	sta r6L
	bcc @1
	inc r5H
	inc r6H
@1:	inc r1H
	CmpBI r1H, 100
	bne FontPutChar80
	bbrf 6, dispBufferOn, FontPutChar80
	AddVB $21, r6H
	bbsf 7, dispBufferOn, FontPutChar80
	sta r5H
FontPutChar80:
	clc
	lda currentMode
	and #SET_UNDERLINE | SET_ITALIC
	beq @1
	jsr Font_3
@1:	php
	bcs @2
	jsr FntIndirectJMP
@2:	bbsf 7, r8H, @6
	AddW curSetWidth, r2
@3:	plp
	bcs @5
	lda r1H
	cmp windowTop
	bcc @5
	cmp windowBottom
	bcc @4
	bne @5
@4:	jsr LE4BC
@5:	dec r10H
	bne LE6E0
	PopB r1H
	rts
@6:	jsr Font_5
	bra @3
.endif

Draw8Pixels:
	ldy Z45,x
	sty r4L    ; pixel pattern

	bit compatMode
	bmi Draw8PixelsCompat

; color mode
	bit r10L   ; inverted/underlined?
	bmi Draw8PixelsInv

; regular (color mode), translucent
	ldy col1 ; fg: primary color
@4:	asl
	bcc @1
	asl r4L
	bcc @0
	sty veradat
@3:	cmp #0
	bne @4
	rts
@1:	asl r4L
@0:	inc veralo
	bne @3
	inc veramid
@2:	bra @3

; inverted/underlined (color mode)
Draw8PixelsInv:
	phx
	ldx col1 ; fg: primary color
	ldy col2 ; bg: secondary color
; opaque drawing with fg color (x) and bg color (y)
Draw8PixelsOpaque:
@4:	asl
	bcc @1
	asl r4L
	bcc @5
	stx veradat
	bra @3
@5:	sty veradat
@3:	cmp #0
	bne @4
	plx
	rts
@1:	asl r4L
	inc veralo
	bne @3
	inc veramid
@2:	bra @3

Draw8PixelsCompat:
	bit r10L   ; inverted/underlined?
	bmi Draw8PixelsCompatInv

; regular (compat mode)
	phx
	ldx #0  ; fg: black
	ldy #1  ; bg: white
	bra Draw8PixelsOpaque

; inverted/underlined (compat mode)
Draw8PixelsCompatInv:
	phx
	ldx #0  ; fg: black
	ldy #15 ; bg: light gray
	bra Draw8PixelsOpaque
