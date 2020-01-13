; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Machine initialization: RAM initialization

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "c64.inc"

.import NumTimers
.import _Panic
.import clkBoxTemp
.import _RecoverRectangle

.global InitRamTab

.segment "init4"

InitRamTab:
	.word g_currentMode
	.byte 12
	.byte 0                       ; g_currentMode
	.byte ST_WR_FORE | ST_WR_BACK ; dispBufferOn
	.byte 0                       ; mouseOn
	.word mousePicData            ; msePicPtr (X16: unused)
	.byte 0                       ; g_windowTop
	.byte SC_PIX_HEIGHT-1         ; g_windowBottom
	.word 0                       ; g_leftMargin
	.word SC_PIX_WIDTH-1          ; g_rightMargin
	.byte 0                       ; pressFlag

	.word appMain
	.byte 28
	.word 0                       ; appMain
	.word 0                       ; intTopVector
	.word 0                       ; intBotVector
	.word 0                       ; mouseVector
	.word 0                       ; keyVector
	.word 0                       ; inputVector
	.word 0                       ; mouseFaultVec
	.word 0                       ; otherPressVec
	.word 0                       ; StringFaultVec
	.word 0                       ; alarmTmtVector
	.word _Panic                  ; BRKVector
	.word _RecoverRectangle       ; RecoverVector
	.byte SelectFlashDelay        ; selectionFlash
	.byte 0                       ; alphaFlag
	.byte ST_FLASH                ; iconSelFlg
	.byte 0                       ; faultData

	.word NumTimers
	.byte 2
	.byte 0                       ; NumTimers
	.byte 0                       ; menuNumber

.ifdef bsw128
	.word clkBoxTemp
	.byte 2                       ; clkBoxTemp and L881A
	.word 0
.else
	.word clkBoxTemp
	.byte 1
	.byte 0                       ; clkBoxTemp

	.word IconDescVecH
	.byte 1
	.byte 0                       ; IconDescVecH
.endif

.ifdef wheels_dlgbox_dblclick
	.word   dblDBData
	.byte   1
	.byte   OPEN
.endif

	.word 0
