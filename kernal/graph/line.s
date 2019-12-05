; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: line functions

.setcpu "65c02"

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
	lda col1
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
@1:	sta (ptr_bg),y
	iny
	sta (ptr_bg),y
	iny
	sta (ptr_bg),y
	iny
	sta (ptr_bg),y
	iny
	bne @1
	jsr inc_bgpage
	dex
	bne @1

; partial block
@2:	ldy r7L
	beq @4
	dey
@3:	sta (ptr_bg),y
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
@1:	lda (ptr_bg),y
	sta veradat
	iny
	lda (ptr_bg),y
	sta veradat
	iny
	lda (ptr_bg),y
	sta veradat
	iny
	lda (ptr_bg),y
	sta veradat
	iny
	lda (ptr_bg),y
	sta veradat
	iny
	lda (ptr_bg),y
	sta veradat
	iny
	lda (ptr_bg),y
	sta veradat
	iny
	lda (ptr_bg),y
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
@3:	lda (ptr_bg),y
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
	sta (ptr_bg),y
	iny
	lda veradat
	sta (ptr_bg),y
	iny
	lda veradat
	sta (ptr_bg),y
	iny
	lda veradat
	sta (ptr_bg),y
	iny
	lda veradat
	sta (ptr_bg),y
	iny
	lda veradat
	sta (ptr_bg),y
	iny
	lda veradat
	sta (ptr_bg),y
	iny
	lda veradat
	sta (ptr_bg),y
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
	sta (ptr_bg),y
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

	PushW r0
	lda r3L
	sta r1L
	MoveW r4, r0
	jsr SetVRAMPtrFG_NEW
	PopW r0

	plx
	phx
	lda col1
	jsr VLineFG
	plx
	tya
@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
	phx

	PushW r0
	PushW r1
	MoveW r4, r0
	MoveB r3L, r1L
	jsr SetVRAMPtrBG_NEW
	PopW r1
	PopW r0

	plx
	lda col1
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
@2:	sta (ptr_bg),y
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
; XXX optimize
	PushW r0
	PushW r1
	MoveB r11L, r1L
	MoveW r3, r0
	jsr SetVRAMPtrFG_NEW
	jsr SetVRAMPtrBG_NEW
	PopW r1
	PopW r0

	MoveW r4, r7
	SubW r3, r7
	IncW r7
	rts
