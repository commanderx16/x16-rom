; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: line functions

.setcpu "65c02"

.segment "GRAPH"

;---------------------------------------------------------------
; HorizontalLine
;
; Pass:      r3   x position of first pixel
;            r4   x position of last pixel
;            r11L y position in scanlines
; Return:    r11L unchanged
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
HorizontalLine:
	PushW r0
	PushW r1
	PushW r2
	MoveW r3, r0
	MoveW r11L, r1L
	MoveW r4, r2
	jsr HorizontalLine_NEW
	PopW r2
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; HorizontalLine
;
; Pass:      r0   x position of first pixel
;            r1   y position
;            r2   x position of last pixel
;---------------------------------------------------------------
; TODO: right to left OK?
HorizontalLine_NEW:
	lda col1
	pha
	jsr GetLineStartAndWidth
	pla
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
	jsr HLineFG
@1:	bbrf 6, k_dispBufferOn, HLine_rts ; ST_WR_BACK
	jmp HLineBG

; foreground version
HLineFG:
	ldx r15H
	beq @2

; full blocks, 8 bytes at a time
	ldy #$20
@1:	jsr fill_y
	dex
	bne @1

; partial block, 8 bytes at a time
@2:	pha
	lda r15L
	lsr
	lsr
	lsr
	beq @6
	tay
	pla
	jsr fill_y

; remaining 0 to 7 bytes
	pha
@6:	lda r15L
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
	ldx r15H
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
@2:	ldy r15L
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
; Pass:      r0   x position of first pixel
;            r1   y position
;            r2   x position of last pixel
;---------------------------------------------------------------
RecoverLine:
	PushW r0
	PushW r1
	PushW r2
	MoveW r3, r0
	MoveW r11L, r1L
	MoveW r4, r2
	jsr RecoverLine_NEW
	PopW r2
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; RecoverLine
;
; Pass:      r0   x pos of left endpoint (0-319)
;            r1   y pos of line (0-199)
;            r2   x pos of right endpoint (0-319)
; Return:    copies bits of line from background to
;            foreground sceen
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
RecoverLine_NEW:
	jsr GetLineStartAndWidth

	ldx r15H
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
@2:	ldy r15L
	beq @4
	dey
@3:	lda (ptr_bg),y
	sta veradat
	dey
	cpy #$ff
	bne @3
@4:	rts

ImprintLine:
	PushW r0
	PushW r1
	PushW r2
	MoveW r3, r0
	MoveW r11L, r1L
	MoveW r4, r2
	jsr ImprintLine_NEW
	PopW r2
	PopW r1
	PopW r0
	rts


ImprintLine_NEW:
	jsr GetLineStartAndWidth

	ldx r15H
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
@2:	ldy r15L
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
	jsr SetVRAMPtrFG
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
	jsr SetVRAMPtrBG
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

GetLineStartAndWidth:
	jsr SetVRAMPtrFG
	jsr SetVRAMPtrBG

	MoveW r2, r15
	SubW r0, r15
	IncW r15
	rts
