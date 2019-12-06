; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: line functions

.setcpu "65c02"

.segment "GRAPH"

;---------------------------------------------------------------
; HorizontalLine
;
; Pass:      r0   x position of first pixel
;            r1   y position
;            r2   x position of last pixel
;---------------------------------------------------------------
HorizontalLine:
	jsr GetLineStartAndWidth
	lda col1
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
; Pass:      r0   x
;            r1   y1
;            r2   (unused)
;            r3   y2
;            a    color
;---------------------------------------------------------------
VerticalLine:
	; make sure y2 >= y1
	lda r3L
	cmp r1L
	bcs @0
	ldx r1L
	stx r3L
	sta r1L

@0:	lda r3L
	sec
	sbc r1L
	tax
	inx
	beq @2 ; .x = number of pixels to draw

	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE

	jsr SetVRAMPtrFG

	phx
	lda col1
	ldy #$71    ; increment in steps of $40
	sty verahi
:	sta veradat
	inc veramid ; increment hi -> add $140 = 320
	dex
	bne :-

	plx

@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK

	jsr SetVRAMPtrBG

	ldy #0
	lda col1
@b:	sta (ptr_bg),y
	tya
	clc
	adc #$40 ; <320
	tay
	bne @a
	jsr inc_bgpage
@a:	jsr inc_bgpage
	dex
	bne @b

@2:	rts


GetLineStartAndWidth:
	; make sure x2 > x1
	lda r2L
	sec
	sbc r0L
	lda r2H
	sbc r0H
	bcs @2
	lda r0L
	ldx r2L
	stx r0L
	sta r2L
	lda r0H
	ldx r2H
	stx r0H
	sta r2H

@2:	jsr SetVRAMPtrFG
	jsr SetVRAMPtrBG

	MoveW r2, r15
	SubW r0, r15
	IncW r15
	rts
