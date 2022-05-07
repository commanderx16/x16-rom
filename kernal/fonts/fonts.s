; Commander X16 KERNAL
;
; Font library

.include "regs.inc"
.include "mac.inc"
.include "fb.inc"
.include "fonts.inc"

.import col1, col2, col_bg

.export curIndexTable, baselineOffset, curSetWidth, curHeight, cardDataPntr, currentMode, windowTop, windowBottom, leftMargin, rightMargin

.segment "ZPFONTS" : zp
; GEOS public ZP
curIndexTable:	.res 2

.segment "VARFONTS"
; GEOS public
baselineOffset:	.res 1
curSetWidth:	.res 2
curHeight:	.res 1
cardDataPntr:	.res 2

currentMode:	.res 1
windowTop:	.res 2
windowBottom:	.res 2
leftMargin:	.res 2
rightMargin:	.res 2

; GEOS private
fontTemp1:	.res 8
fontTemp2:	.res 9
PrvCharWidth:	.res 1
FontTVar1:	.res 1
FontTVar2:	.res 2
FontTVar3:	.res 1
FontTVar4:	.res 1

.include "font_internal.inc"

.assert curIndexTable = k_curIndexTable, error, "update font_internal.inc!"
.assert baselineOffset = k_baselineOffset, error, "update font_internal.inc!"
.assert curSetWidth = k_curSetWidth, error, "update font_internal.inc!"
.assert curHeight = k_curHeight, error, "update font_internal.inc!"
.assert cardDataPntr = k_cardDataPntr, error, "update font_internal.inc!"
.assert currentMode = k_currentMode, error, "update font_internal.inc!"
.assert windowTop = k_windowTop, error, "update font_internal.inc!"
.assert windowBottom = k_windowBottom, error, "update font_internal.inc!"
.assert leftMargin = k_leftMargin, error, "update font_internal.inc!"
.assert rightMargin = k_rightMargin, error, "update font_internal.inc!"

.segment "GRAPH"

.include "fonts2.s"
.include "fonts3.s"
.include "fonts4.s"
.include "fonts4b.s"
.include "conio1.s"
.include "conio3b.s"
.include "sysfont.s"

