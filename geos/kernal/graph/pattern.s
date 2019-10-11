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
	lda #0
	sta curPattern+1
	rts

