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
	sta curPattern+1
	rts

_SetColor:
	sta curPattern
	lda #0
	sta curPattern+1
	rts

