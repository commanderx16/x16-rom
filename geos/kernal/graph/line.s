; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: line functions

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
.import _GetScanLineVera

.global ImprintLine
.global _HorizontalLine
.global _InvertLine
.global _RecoverLine
.global _VerticalLine

bitmap_base = 0

.segment "graph2a"

PrepareXCoord:
	ldx r11L
	jsr _GetScanLine
	lda r4L
	and #%00000111
	tax
	lda BitMaskLeadingClear,x
	sta r8H
	lda r3L
	and #%00000111
	tax
	lda BitMaskLeadingSet,x
	sta r8L
	lda r3L
	and #%11111000
	sta r3L
	lda r4L
	and #%11111000
	sta r4L
	rts

;---------------------------------------------------------------
; HorizontalLine                                          $C118
;
; Pass:      a    pattern byte
;            r11L y position in scanlines (0-199)
;            r3   x in pixel of left end (0-319)
;            r4   x in pixel of right end (0-319)
; Return:    r11L unchanged
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_HorizontalLine:
	jsr convcol
	pha
	LoadW r5, bitmap_base
	ldx r11L
	jsr _GetScanLineVera

	AddW r3, r5

	ldy r5L
	sty veralo
	lda r5H
	sta veramid
	lda #$10
	sta verahi

	MoveW r4, r6
	SubW r3, r6
	inc r6L
	bne :+
	inc r6H
:
	pla

	ldy r6H
	beq @2
	ldy #0
@1:	sta veradat
	dey
	bne @1
	inc r1H
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
	PushW r3
	PushW r4
	jsr PrepareXCoord
	ldy r3L
	lda r3H
	beq @1
	inc r5H
	inc r6H
@1:
	CmpW r3, r4
	beq @4
	SubW r3, r4
	lsr r4H
	ror r4L
	lsr r4L
	lsr r4L
	lda r8L
	eor (r5),Y
@2:	eor #$FF
	sta (r6),Y
	sta (r5),Y
	tya
	addv 8
	tay
	bcc @3
	inc r5H
	inc r6H
@3:	dec r4L
	beq @5
	lda (r5),Y
	bra @2
@4:	lda r8L
	ora r8H
	bra @6
@5:	lda r8H
@6:	eor #$FF
	eor (r5),Y
	jmp HLinEnd1


ImprintLine:
	PushW r3
	PushW r4
	PushB dispBufferOn
	ora #ST_WR_FORE | ST_WR_BACK
	sta dispBufferOn
	jsr PrepareXCoord
	PopB dispBufferOn
	lda r5L
	ldy r6L
	sta r6L
	sty r5L
	lda r5H
	ldy r6H
	sta r6H
	sty r5H
	bra RLin0

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
	PushW r3
	PushW r4
	PushB dispBufferOn
	ora #ST_WR_FORE | ST_WR_BACK
	sta dispBufferOn
	jsr PrepareXCoord
RLin0a:
	PopB dispBufferOn
RLin0:
	ldy r3L
	lda r3H
	beq @1
	inc r5H
	inc r6H
@1:
	CmpW r3, r4
	beq @4
	SubW r3, r4
	lsr r4H
	ror r4L
	lsr r4L
	lsr r4L
	lda r8L
	jsr RecLineHelp
@2:	tya
	addv 8
	tay
	bcc @3
	inc r5H
	inc r6H
@3:	dec r4L
	beq @5
	lda (r6),Y
	sta (r5),Y
	bra @2
@4:	lda r8L
	ora r8H
	bra @6
@5:	lda r8H
@6:	jsr RecLineHelp
	jmp HLinEnd2

RecLineHelp:
	sta r7L
	and (r5),Y
	sta r7H
	lda r7L
	eor #$FF
	and (r6),Y
	ora r7H
	sta (r5),Y
	rts

HLinEnd1:
	sta (r6),Y
	sta (r5),Y
HLinEnd2:
	PopW r4
	PopW r3
	rts

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
	jsr convcol
	pha
	LoadW r5, bitmap_base
	ldx r3L
	beq :+
:	AddVW 320, r5
	dex
	bne :-
:

	AddW r4, r5


	lda r3H
	sec
	sbc r3L
	tax

	pla

	cpx #0
	beq @1

	ldy #$10
	sty verahi

:	ldy r5L
	sty veralo
	ldy r5H
	sty veramid
	sta veradat
	pha
	AddVW 320, r5
	pla
	dex
	bne :-

@1:	rts

convcol:
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
