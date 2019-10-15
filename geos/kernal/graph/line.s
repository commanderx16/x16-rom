; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: line functions

odd_left=$7f
odd_right=$7e
tmp640=$7d
tmp640b=$7c

.setcpu "65c02"

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.import BitMaskPow2Rev
.import BitMaskLeadingSet
.import BitMaskLeadingClear
.import _GetScanLine

.import inc_bgpage

.global ImprintLine
.global _HorizontalLine
.global _HorizontalLineCol
.global _InvertLine
.global _RecoverLine
.global _VerticalLine
.global _VerticalLineCol
.global GetColor

.segment "graph2a"

;---------------------------------------------------------------
; API extension
; ~~~~~~~~~~~~~
; If the user called SetColor, the color will be used, instead of
; the pattern passed in A.
; If the user called SetPattern, the bit pattern in A will be
; converted into a grayscale value.
;---------------------------------------------------------------

;---------------------------------------------------------------
; HorizontalLine                                          $C118
;
; Pass:      a    pattern byte
;            r3   x in pixel of left end (0-319)
;            r4   x in pixel of right end (0-319)
;            r11L y position in scanlines (0-199)
; Return:    r11L unchanged
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_HorizontalLine:
	jsr Convert8BitPattern
_HorizontalLineCol: ; called by Rectangle
	pha
	jsr GetLineStart
	pla
	bbrf 7, dispBufferOn, @1 ; ST_WR_FORE
	ldy r5L
	sty veralo
	ldy r5H
	sty veramid
	ldy #$11
	sty verahi
.ifdef vera640
	jsr HLineFG640
.else
	jsr HLineFG
.endif
@1:	bbrf 6, dispBufferOn, HLine_rts ; ST_WR_BACK
	jmp HLineBG

; foreground version
HLineFG:
	ldx r7H
	beq @2

; full blocks, 8 bytes at a time
	ldy #$20
@1:	jsr fill_y
	dex
	bne @1

; partial block, 8 bytes at a time
@2:	pha
	lda r7L
	lsr
	lsr
	lsr
	beq @6
	tay
	pla
	jsr fill_y

; remaining 0 to 7 bytes
	pha
@6:	lda r7L
	and #7
	beq @5
	tay
	pla
@3:	sta veradat
	dey
	bne @3
@4:	rts

@5:	pla
	rts

fill_y:	sta veradat
	sta veradat
	sta veradat
	sta veradat
	sta veradat
	sta veradat
	sta veradat
	sta veradat
	dey
	bne fill_y
HLine_rts:
	rts

; foreground version, 640@16c
HLineFG640:
	tax
	PushW r7
; first pixel if odd
	bit odd_left
	bpl :+
	lda verahi
	and #$0f ; disable auto-increment
	sta verahi
	txa
	and #$0f
	sta tmp640
	lda veradat
	and #$f0
	ora tmp640
	sta veradat
	lda verahi
	ora #$10 ; enable auto-increment
	sta verahi
:

; bytes = pixels / 2
	lsr r7H
	ror r7L
	lda #0
	ror
	sta odd_right

; put color into lo and hi nybble
	txa
	and #$0f
	sta tmp640
	asl
	asl
	asl
	asl
	ora tmp640

	ldx r7H
	beq @2

; full blocks, 8 bytes at a time
	ldy #$20
@1:	jsr fill_y
	dex
	bne @1

; partial block
@2:	ldy r7L
	beq @4
@3:	sta veradat
	dey
	bne @3
@4:	PopW r7

; last pixel if odd
	bit odd_right
	bpl :+
	asl
	asl
	asl
	asl
	sta tmp640
	lda veradat
	and #$0f
	ora tmp640
	sta veradat

:	rts


; background version
HLineBG:
	ldx r7H
	beq @2

; full blocks, 4 bytes at a time
	ldy #0
@1:	sta (r6),y
	iny
	sta (r6),y
	iny
	sta (r6),y
	iny
	sta (r6),y
	iny
	bne @1
	jsr inc_bgpage
	dex
	bne @1

; partial block
@2:	ldy r7L
	beq @4
	dey
@3:	sta (r6),y
	dey
	cpy #$ff
	bne @3
@4:	rts

;---------------------------------------------------------------
; InvertLine                                              $C11B
;
; Pass:      r3   x pos of left endpoint (0-319)
;            r4   x pos of right endpoint (0-319)
;            r11L y pos (0-199)
; Return:    r3-r4 unchanged
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
_InvertLine:
	jsr GetLineStart
	bbrf 7, dispBufferOn, @1 ; ST_WR_FORE
	ldy #$11
	PushW r7
	jsr ILineFG
	PopW r7
@1:	bbrf 6, dispBufferOn, @2 ; ST_WR_BACK
	jmp ILineBG
@2:	rts

; foreground version
ILineFG:
	lda #1
	sta veractl
	lda r5L
	sta veralo
	lda r5H
	sta veramid
	sty verahi
	lda #0
	sta veractl
	lda r5L
	sta veralo
	lda r5H
	sta veramid
	sty verahi

	ldy r7H
	beq @2

; full blocks, 8 bytes at a time
	ldy #$20
@1:	jsr invert_y
	dec r7H
	bne @1

; partial block, 8 bytes at a time
@2:	lda r7L
	lsr
	lsr
	lsr
	beq @6
	tay
	jsr invert_y

; remaining 0 to 7 bytes
@6:	lda r7L
	and #7
	beq @4
	tay
@3:	lda veradat
	eor #1
	sta veradat2
	dey
	bne @3
@4:	rts

invert_y:
	lda veradat
	eor #1
	sta veradat2
	lda veradat
	eor #1
	sta veradat2
	lda veradat
	eor #1
	sta veradat2
	lda veradat
	eor #1
	sta veradat2
	lda veradat
	eor #1
	sta veradat2
	lda veradat
	eor #1
	sta veradat2
	lda veradat
	eor #1
	sta veradat2
	lda veradat
	eor #1
	sta veradat2
	dey
	bne invert_y
	rts

; background version
ILineBG:
	ldy r7H
	beq @2

	ldy #0
@1:	lda (r6),y
	eor #1
	sta (r6),y
	iny
	bne @1
	jsr inc_bgpage
	dec r7H
	bne @1

; partial block
@2:	ldy r7L
	beq @4
	dey
@3:	lda (r6),y
	eor #1
	sta (r6),y
	dey
	cpy #$ff
	bne @3
@4:	rts

;---------------------------------------------------------------
; RecoverLine                                             $C11E
;
; Pass:      r3   x pos of left endpoint (0-319)
;            r4   x pos of right endpoint (0-319)
;            r11L y pos of line (0-199)
; Return:    copies bits of line from background to
;            foreground sceen
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
_RecoverLine:
	jsr GetLineStart
	lda r5L
	sta veralo
	lda r5H
	sta veramid
	lda #$11
	sta verahi

	ldy r7H
	beq @2

; full blocks, 8 bytes at a time
	ldy #0
@1:	lda (r6),y
	sta veradat
	iny
	lda (r6),y
	sta veradat
	iny
	lda (r6),y
	sta veradat
	iny
	lda (r6),y
	sta veradat
	iny
	lda (r6),y
	sta veradat
	iny
	lda (r6),y
	sta veradat
	iny
	lda (r6),y
	sta veradat
	iny
	lda (r6),y
	sta veradat
	iny
	bne @1
	jsr inc_bgpage
	dec r7H
	bne @1

; partial block
@2:	ldy r7L
	beq @4
	dey
@3:	lda (r6),y
	sta veradat
	dey
	cpy #$ff
	bne @3
@4:	rts

ImprintLine:
	jsr GetLineStart
	lda r5L
	sta veralo
	lda r5H
	sta veramid
	lda #$11
	sta verahi

	ldy r7H
	beq @2

; full blocks, 8 bytes at a time
	ldy #0
@1:	lda veradat
	sta (r6),y
	iny
	lda veradat
	sta (r6),y
	iny
	lda veradat
	sta (r6),y
	iny
	lda veradat
	sta (r6),y
	iny
	lda veradat
	sta (r6),y
	iny
	lda veradat
	sta (r6),y
	iny
	lda veradat
	sta (r6),y
	iny
	lda veradat
	sta (r6),y
	iny
	bne @1
	jsr inc_bgpage
	dec r7H
	bne @1

; partial block
@2:	ldy r7L
	beq @4
	dey
@3:	lda veradat
	sta (r6),y
	dey
	cpy #$ff
	bne @3
@4:	rts

;---------------------------------------------------------------
; VerticalLine                                            $C121
;
; Pass:      a pattern byte
;            r3L top of line (0-199)
;            r3H bottom of line (0-199)
;            r4  x position of line (0-319)
; Return:    draw the line
; Destroyed: a, x, y, r4 - r8, r11
;---------------------------------------------------------------
_VerticalLine:
	jsr Convert8BitPattern
_VerticalLineCol:
	pha
	ldx r3L
	jsr _GetScanLine
	AddW r4, r5
	AddW r4, r6

	lda r3H
	sec
	sbc r3L
	tax
	pla
	inx
	beq @2

	bbrf 7, dispBufferOn, @1 ; ST_WR_FORE
	phx
.ifdef vera640
	jsr VLineFG640
.else
	jsr VLineFG
.endif
	plx
	tya
@1:	bbrf 6, dispBufferOn, @2 ; ST_WR_BACK
	jmp VLineBG
@2:	rts

VLineFG:
	ldy r5L
	sty veralo
	ldy r5H
	sty veramid
	ldy #$71    ; increment in steps of $40
	sty verahi
:	sta veradat
	inc veramid ; increment hi -> add $140 = 320
	dex
	bne :-
	rts

VLineFG640:
	and #$0f
	sta tmp640
	lda #$f0
	sta tmp640b

	lda r5L
	sta veralo
	lda r5H
	sta veramid
	lda #$00
	sta verahi
@2:	lda veradat
	and tmp640b
	ora tmp640
	lda #$23
	sta veradat
	lda veralo
	clc
	adc #<320
	sta veralo
	bcc @1
	inc veramid
@1:	dex
	bne @2
	rts

VLineBG:
	ldy #0
:	sta (r6),y
	tya
	clc
	adc #$40 ; <320
	tay
	bne :+
	jsr inc_bgpage
:	jsr inc_bgpage
	dex
	bne :-
	rts

GetLineStart:
	ldx r11L
	jsr _GetScanLine
.ifdef vera640
	MoveW r3, r7
	lsr r7L
	ror r7L

	lda #0
	ror
	sta odd_left

	AddW r7, r5
	AddW r7, r6
.else
	AddW r3, r5
	AddW r3, r6
.endif

	MoveW r4, r7
	SubW r3, r7
	IncW r7
	rts

;---------------------------------------------------------------
; Color compatibility logic
;---------------------------------------------------------------

; in compat mode, this converts 8 bit patterns into shades of gray
Convert8BitPattern:
	bit compatMode
	bmi @0
	lda col1
	rts
@0:	ldx #8
	ldy #8
@1:	lsr
	bcc @2
	dey
@2:	dex
	bne @1
	cpy #8
	beq @3
	tya
	asl
	ora #16
	rts
@3:	lda #16+15
	rts
