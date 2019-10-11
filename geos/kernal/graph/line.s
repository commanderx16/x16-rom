; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: line functions

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
.import _GetScanLineVera

.global ImprintLine
.global _HorizontalLine
.global _HorizontalLineCol
.global _InvertLine
.global _RecoverLine
.global _VerticalLine
.global _VerticalLineCol
.global GetColor
.global GetColor2

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
	ldx r6H
	phx
	jsr HLine1
	plx
	stx r6H
@1:	bbrf 6, dispBufferOn, @2 ; ST_WR_BACK
	ldy r5L
	sty veralo
	ldy r5H
	sty veramid
	ldy #$10
	sty verahi
	jmp HLine1
@2:	rts

HLine1:
	ldy r6H
	beq @2
	ldy #0
@1:	sta veradat
	dey
	bne @1
	dec r6H
	bne @1
@2:	ldy r6L
	beq @4
	dey
@3:	sta veradat
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
	PushW r6
	jsr ILine1
	PopW r6
@1:	bbrf 6, dispBufferOn, @2 ; ST_WR_BACK
	ldy #$10
	jmp ILine1
@2:	rts

ILine1:
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

	ldy r6H
	beq @2
	ldy #0
@1:	lda veradat
	eor #1
	sta veradat2
	dey
	bne @1
	dec r6H
	bne @1
@2:	ldy r6L
	beq @4
	dey
@3:	lda veradat
	eor #1
	sta veradat2
	dey
	cpy #$ff
	bne @3
@4:	rts


ImprintLine:
	jsr GetLineStart
	ldx #$11
	ldy #$10
	jmp RLine1

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
	ldx #$10
	ldy #$11
RLine1:
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
	stx verahi

	ldy r6H
	beq @2
	ldy #0
@1:	lda veradat
	sta veradat2
	dey
	bne @1
	dec r6H
	bne @1
@2:	ldy r6L
	beq @4
	dey
@3:	lda veradat
	sta veradat2
	dey
	cpy #$ff
	bne @3
@4:	rts

;---------------------------------------------------------------
; VerticalLine                                            $C121
;
; Pass:      a pattern
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
	jsr _GetScanLineVera
	AddW r4, r5

	lda r3H
	sec
	sbc r3L
	tax
	pla
	inx
	beq @2

	bbrf 7, dispBufferOn, @1 ; ST_WR_FORE
	phx
	ldy #1
	jsr VLine1
	plx
	tya
@1:	bbrf 6, dispBufferOn, @2 ; ST_WR_BACK
	ldy #0
	jmp VLine1
@2:	rts

VLine1:
	sty verahi
	ldy r5L
	sty veralo
	ldy r5H
	sty veramid
	tay
:	sty veradat
	AddVW 320, veralo
	dex
	bne :-
	rts

GetLineStart:
	ldx r11L
	jsr _GetScanLineVera
	AddW r3, r5
	MoveW r4, r6
	SubW r3, r6
	IncW r6
	rts

;---------------------------------------------------------------
; Color compatibility logic
;---------------------------------------------------------------

; in compat mode, this converts 8 bit patterns into shades of gray
Convert8BitPattern:
	bit curPattern+1
	bmi @0 ; compat mode
	lda curPattern ; get color instead
	rts
@0:
	ldx #8
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

; in compat mode, this converts patterns (0-33) into colors that look nice
GetColor:
	lda curPattern
GetColor2:
	bit curPattern+1
	bpl @1
; compat mode
	cmp #2 ; 50% shading
	bne @3
	lda #14 ; light blue
	rts
@3:	cmp #9 ; horizontal stripes
	bne @2
	lda #6 ; dark blue
	rts
@2:	cmp #2
	bcs @1
	eor #1 ; swap black and white
@1:	rts

