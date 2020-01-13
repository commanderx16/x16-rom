; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; C64/C128: Start a program in BASIC mode

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "c64.inc"

.global _ToBASIC

.segment "tobasic2"

_ToBASIC:
	;XXX TODO X16
	brk

