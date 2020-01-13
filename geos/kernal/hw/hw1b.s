; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Hardware initialization

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "c64.inc"

.import ResetMseRegion
.import Init_KRNLVec
.import KbdQueTail
.import KbdQueHead
.import KbdQueFlag
.import InitVDC

.import SetColorMode

.global _DoFirstInitIO

.segment "hw1b"

_DoFirstInitIO:
	ldx #$ff
	stx KbdQueFlag
	inx
	stx KbdQueHead
	stx KbdQueTail
	jmp ResetMseRegion

