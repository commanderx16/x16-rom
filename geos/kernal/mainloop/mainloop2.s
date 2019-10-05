; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Main Loop

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.import _MainLoop

.global _MainLoop2

.segment "mainloop2"

.if (!.defined(wheels)) && (!.defined(bsw128))
_MainLoop2:
	jmp _MainLoop
.endif

