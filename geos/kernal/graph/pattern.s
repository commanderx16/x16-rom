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
; Pass:      a color (0-255)
; Return:    currentPattern - updated
; Destroyed: a
;---------------------------------------------------------------
_SetPattern:
	sta curPattern
	lda #$80
	sta compatMode
	rts

_SetColor:
	sta curPattern
	stx curPattern+1
	stz compatMode
	rts

