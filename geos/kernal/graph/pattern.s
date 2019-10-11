; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: SetPattern syscall

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.setcpu "65c02"

.import PatternTab

.global _SetPattern
.global _SetColor

.segment "graph2l2"

;---------------------------------------------------------------
; SetPattern                                              $C139
;
; Pass:      a pattern nbr (0-33)
; Return:    col1 - updated
; Destroyed: a
;---------------------------------------------------------------
_SetPattern:
; convert patterns (0-33) into colors that look nice
GetColor:
	cmp #2 ; 50% shading
	beq @a
	cmp #9 ; horizontal stripes
	beq @b
	cmp #2
	bcs @c
	eor #1 ; swap black and white
	bra @c
@a:	lda #14 ; light blue
	.byte $2c
@b:	lda #6 ; dark blue
@c:	sta col1
	lda #$80
	sta compatMode
	rts

;---------------------------------------------------------------
; SetColor
;
; Pass:      a primary color (0-255)
;            x secondary color (0-255)
; Return:    col1, col2 - updated
;---------------------------------------------------------------
_SetColor:
	sta col1   ; primary color
	stx col2 ; secondary color
	stz compatMode
	rts

