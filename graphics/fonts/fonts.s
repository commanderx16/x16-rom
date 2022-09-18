; Commander X16 KERNAL
;
; Font library

.include "regs.inc"
.include "mac.inc"
;.include "fb.inc"
.include "fonts.inc"

.import FB_init
.import FB_get_info
.import FB_set_palette
.import FB_cursor_position
.import FB_cursor_next_line
.import FB_get_pixel
.import FB_get_pixels
.import FB_set_pixel
.import FB_set_pixels
.import FB_set_8_pixels
.import FB_set_8_pixels_opaque
.import FB_fill_pixels
.import FB_filter_pixels
.import FB_move_pixels
.import col1, col2, col_bg

.export curIndexTable, baselineOffset, curSetWidth, curHeight, cardDataPntr, currentMode, windowTop, windowBottom, leftMargin, rightMargin

curIndexTable = k_curIndexTable
baselineOffset = k_baselineOffset
curSetWidth = k_curSetWidth
curHeight = k_curHeight
cardDataPntr = k_cardDataPntr
currentMode = k_currentMode
windowTop = k_windowTop
windowBottom = k_windowBottom
leftMargin = k_leftMargin
rightMargin = k_rightMargin

;.segment "ZPFONTS" : zp
; ; GEOS public ZP
; curIndexTable:	.res 2

.segment "VARFONTS"
; ; GEOS public
; baselineOffset:	.res 1
; curSetWidth:	.res 2
; curHeight:	.res 1
; cardDataPntr:	.res 2

; currentMode:	.res 1
; windowTop:	.res 2
; windowBottom:	.res 2
; leftMargin:	.res 2
; rightMargin:	.res 2

unused: .res 15
; GEOS private
fontTemp1:	.res 8
fontTemp2:	.res 9
PrvCharWidth:	.res 1
FontTVar1:	.res 1
FontTVar2:	.res 2
FontTVar3:	.res 1
FontTVar4:	.res 1

.include "font_internal.inc"

.segment "GRAPH"

.include "fonts2.s"
.include "fonts3.s"
.include "fonts4.s"
.include "fonts4b.s"
.include "conio1.s"
.include "conio3b.s"
.include "sysfont.s"

