.export GRAPH_get_char_size
.export GRAPH_put_char
.export GRAPH_set_font
.export font_init
.export leftMargin
.export rightMargin
.export windowBottom
.export windowTop
.export currentMode

.import jsrfar

.include "banks.inc"
.include "graphics.inc"

.segment "ZPFONTS"
curIndexTable:	.res 2

.segment "VARFONTS"
; GEOS public
baselineOffset:	.res 1
curSetWidth:	.res 2
curHeight:		.res 1
cardDataPntr:	.res 2

currentMode:	.res 1
windowTop:	    .res 2
windowBottom:	.res 2
leftMargin:	    .res 2
rightMargin:	.res 2

; GEOS private
fontTemp1:	    .res 8
fontTemp2:	    .res 9
PrvCharWidth:	.res 1
FontTVar1:	    .res 1
FontTVar2:	    .res 2
FontTVar3:	    .res 1
FontTVar4:	    .res 1

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

.assert fontTemp1 = k_fontTemp1, error, "update font_internal.inc!"
.assert fontTemp2 = k_fontTemp2, error, "update font_internal.inc!"
.assert PrvCharWidth = k_PrvCharWidth, error, "update font_internal.inc!"
.assert FontTVar1 = k_FontTVar1, error, "update font_internal.inc!"
.assert FontTVar2 = k_FontTVar2, error, "update font_internal.inc!"
.assert FontTVar3 = k_FontTVar3, error, "update font_internal.inc!"
.assert FontTVar4 = k_FontTVar4, error, "update font_internal.inc!"


.segment "GRAPH"

GRAPH_get_char_size:
    jsr jsrfar
    .word gr_GRAPH_get_char_size
    .byte BANK_GRAPH
    rts
GRAPH_put_char:
    jsr jsrfar
    .word gr_GRAPH_put_char
    .byte BANK_GRAPH
    rts
GRAPH_set_font:
    jsr jsrfar
    .word gr_GRAPH_set_font
    .byte BANK_GRAPH
    rts
font_init:
    jsr jsrfar
    .word gr_font_init
    .byte BANK_GRAPH
    rts