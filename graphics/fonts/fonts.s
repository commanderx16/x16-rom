; Commander X16 KERNAL
;
; Font library

.include "regs.inc"
.include "mac.inc"
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
.import col1, col2, col_bg          ;Set during link stage, read from Kernal.sym

.export curIndexTable, baselineOffset, curSetWidth, curHeight, cardDataPntr, currentMode, windowTop, windowBottom, leftMargin, rightMargin

.include "font_internal.inc"

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

; GEOS private
fontTemp1       = k_fontTemp1
fontTemp2       = k_fontTemp2
PrvCharWidth    = k_PrvCharWidth
FontTVar1       = k_FontTVar1
FontTVar2       = k_FontTVar2
FontTVar3       = k_FontTVar3
FontTVar4       = k_FontTVar4

.segment "GRAPH"

.include "fonts2.s"
.include "fonts3.s"
.include "fonts4.s"
.include "fonts4b.s"
.include "conio1.s"
.include "conio3b.s"
.include "sysfont.s"

