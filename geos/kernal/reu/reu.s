; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; C64/REU driver

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "c64.inc"

; syscalls
.global _DoRAMOp
.global _FetchRAM
.global _StashRAM
.global _SwapRAM
.global _VerifyRAM

.segment "reu"

_DoRAMOp:
_FetchRAM:
_StashRAM:
_SwapRAM:
_VerifyRAM:
	brk
