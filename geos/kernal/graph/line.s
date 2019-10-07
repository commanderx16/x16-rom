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

.global ImprintLine
.global _HorizontalLine
.global _InvertLine
.global _RecoverLine
.global _VerticalLine

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
	sta r7L
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
	jsr HLineHelp
@2:	sta (r6),Y
	sta (r5),Y
	tya
	addv 8
	tay
	bcc @3
	inc r5H
	inc r6H
@3:	dec r4L
	beq @5
	lda r7L
	bra @2
@4:	lda r8L
	ora r8H
	bra @6

@5:	lda r8H
@6:	jsr HLineHelp
HLinEnd1:
	sta (r6),Y
	sta (r5),Y
HLinEnd2:
	PopW r4
	PopW r3
	rts


HLineHelp:
	sta r11H
	and (r6),Y
HLineHelp2:
	sta r7H
	lda r11H
	eor #$FF
	and r7L
	ora r7H
	rts

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
	sta r8L
	PushB r4L
	and #%00000111
	tax
	lda BitMaskPow2Rev,x
	sta r7H
	lda r4L
	and #%11111000
	sta r4L
	ldy #0
	ldx r3L
@1:	stx r7L
	jsr _GetScanLine
	AddW r4, r5
	AddW r4, r6
	lda r7L
	and #%00000111
	tax
	lda BitMaskPow2Rev,x
	and r8L
	bne @2
	lda r7H
	eor #$FF
	and (r6),Y
	bra @3
@2:	lda r7H
	ora (r6),Y
@3:	sta (r6),Y
	sta (r5),Y
	ldx r7L
	inx
	cpx r3H
	beq @1
	bcc @1
	PopB r4L
	rts
