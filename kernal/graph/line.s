; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: line functions

.global k_InvertLine
.global ImprintLine
.global HorizontalLine
.global RecoverLine
.global VerticalLine

.segment "GRAPH"

;---------------------------------------------------------------
; HorizontalLine
;
; Pass:      r3   x in pixel of left end (0-319)
;            r4   x in pixel of right end (0-319)
;            r11L y position in scanlines (0-199)
; Return:    r11L unchanged
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
HorizontalLine:
	lda k_col1
	pha
	jsr GetLineStart
	pla
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
	jsr HLineFG
@1:	bbrf 6, k_dispBufferOn, HLine_rts ; ST_WR_BACK
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
k_InvertLine:
	jsr GetLineStart
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
	ldy #$11
	jsr ILineFG
@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
	jmp ILineBG
@2:	rts

; foreground version
ILineFG:
	lda veralo
	ldx veramid
	inc veractl ; 1
	sta veralo
	stx veramid
	sty verahi
	stz veractl ; 0
	sty verahi

	ldx r7H
	beq @2

; full blocks, 8 bytes at a time
	ldy #$20
@1:	jsr invert_y
	dex
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
	ldx r7H
	beq @2

	ldy #0
@1:	lda (r6),y
	eor #1
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
@3:	lda (r6),y
	eor #1
	sta (r6),y
	dey
	cpy #$ff
	bne @3
@4:	rts

;---------------------------------------------------------------
; RecoverLine
;
; Pass:      r3   x pos of left endpoint (0-319)
;            r4   x pos of right endpoint (0-319)
;            r11L y pos of line (0-199)
; Return:    copies bits of line from background to
;            foreground sceen
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
RecoverLine:
	jsr GetLineStart

	ldx r7H
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
	dex
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

	ldx r7H
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
	dex
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
; VerticalLine
;
; Pass:      a pattern byte
;            r3L top of line (0-199)
;            r3H bottom of line (0-199)
;            r4  x position of line (0-319)
; Return:    draw the line
; Destroyed: a, x, y, r4 - r8, r11
;---------------------------------------------------------------
VerticalLine:
	lda r3H
	sec
	sbc r3L
	tax
	inx
	beq @2

	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
	phx
	ldx r3L

	PushW r3
	MoveW r4, r3
	jsr k_SetVRAMPtrFG
	PopW r3

	plx
	phx
	lda k_col1
	jsr VLineFG
	plx
	tya
@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
	phx
	ldx r3L

	PushW r3
	MoveW r4, r3
	jsr k_SetVRAMPtrBG
	PopW r3

	plx
	lda k_col1
	jmp VLineBG
@2:	rts

VLineFG:
	ldy #$71    ; increment in steps of $40
	sty verahi
:	sta veradat
	inc veramid ; increment hi -> add $140 = 320
	dex
	bne :-
	rts

VLineBG:
	ldy #0
@2:	sta (r6),y
	tya
	clc
	adc #$40 ; <320
	tay
	bne @1
	jsr inc_bgpage
@1:	jsr inc_bgpage
	dex
	bne @2
	rts

GetLineStart:
	ldx r11L
	jsr k_SetVRAMPtrFG
	jsr k_SetVRAMPtrBG

	MoveW r4, r7
	SubW r3, r7
	IncW r7
	rts
