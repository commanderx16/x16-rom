; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Loading

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.global DeskTopName
.global _EnterDT_Str1
.global _EnterDT_Str0

.segment "load1c"

DeskTopName:
.ifdef bsw128
	.byte "128 DESKTOP", 0
.elseif .defined(gateway)
	.byte "GATEWAY", 0
	.byte 0 ; PADDING
.elseif .defined(wheels)
	.byte "DESKTOP", 0
	.byte 0 ; PADDING
.else
	.byte "DESK TOP", 0
.endif

.segment "load1d"

_EnterDT_Str0:
	.byte "!", 0
_EnterDT_Str1:
	.byte "?", 0
