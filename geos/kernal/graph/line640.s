; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: line functions, 640x400@16c

.setcpu "65c02"

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.import GetLineStart, inc_bgpage, fill_y

.global VLineFG640, ILineFG640, HLineFG640

.segment "graph2a"

.ifdef vera640

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


.if 0
; background version
HLineBG640: ; XXX TODO
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
.endif

; foreground version, 640@16c
ILineFG640:
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

	PushW r7
; first pixel if odd
	bit odd_left
	bpl :+
	lda veradat
	eor #1
	sta veradat2
:

; bytes = pixels / 2
	lsr r7H
	ror r7L
	lda #0
	ror
	sta odd_right

	ldx r7H
	beq @2

; full blocks, 8 bytes at a time
	ldy #$20
@1:	jsr invert_y_640
	dex
	bne @1

; partial block
@2:	ldy r7L
	beq @4
@3:	lda veradat
	eor #$11
	sta veradat2
	dey
	bne @3
@4:	PopW r7

; last pixel if odd
	bit odd_right
	bpl :+
	lda veradat
	eor #$10
	sta veradat2
:	rts

invert_y_640:
	lda veradat
	eor #$11
	sta veradat2
	lda veradat
	eor #$11
	sta veradat2
	lda veradat
	eor #$11
	sta veradat2
	lda veradat
	eor #$11
	sta veradat2
	lda veradat
	eor #$11
	sta veradat2
	lda veradat
	eor #$11
	sta veradat2
	lda veradat
	eor #$11
	sta veradat2
	lda veradat
	eor #$11
	sta veradat2
	dey
	bne invert_y_640
	rts

.if 0
; background version
ILineBG640: ; XXX TODO
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
.endif

.if 0
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
_RecoverLine640: ; XXX TODO
	jsr GetLineStart
	lda r5L
	sta veralo
	lda r5H
	sta veramid
	lda #$11
	sta verahi

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
	lda r5L
	sta veralo
	lda r5H
	sta veramid
	lda #$11
	sta verahi

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
.endif

VLineFG640:
	bit odd_left
	bpl @a
	and #$0f
	sta tmp640
	lda #$f0
	sta tmp640b
	bra @b
@a:	asl
	asl
	asl
	asl
	sta tmp640
	lda #$0f
	sta tmp640b
@b:
	lda r5L
	sta veralo
	lda r5H
	sta veramid
	lda #$01
	sta verahi
@2:	lda veradat
	and tmp640b
	ora tmp640
	sta veradat
	lda veralo
	clc
	adc #<320
	sta veralo
	bcc @1
	inc veramid
@1:	inc veramid
	dex
	bne @2
	rts

.if 0
VLineBG640: ; XXX TODO
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
.endif

.endif
