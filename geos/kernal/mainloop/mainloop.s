; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Main Loop

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "c64.inc"

.import _DoUpdateTime
.import _ExecuteProcesses
.import _DoCheckButtons
.import _DoCheckDelays
.import __GetRandom
.import ProcessCursor
.import __ProcessDelays
.import __ProcessTimers
.import ProcessMouse
.import CallRoutine

.global _MNLP
.global _MainLoop

.global _InterruptMain

.segment "mainloop1"

_MainLoop:
	jsr _DoCheckButtons
	jsr _ExecuteProcesses ; process
	jsr _DoCheckDelays    ; process
	jsr _DoUpdateTime
	lda appMain+0
	ldx appMain+1
_MNLP:	jsr CallRoutine
	cli
	jmp _MainLoop

.segment "mainloop2"

.segment "mainloop3"

_InterruptMain:
	jsr ProcessMouse
	jsr __ProcessTimers ; process
	jsr __ProcessDelays ; process
	jsr ProcessCursor
	jmp __GetRandom
