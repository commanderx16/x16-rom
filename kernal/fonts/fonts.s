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


.segment "VARFONTS"
; GEOS public
baselineOffset:	.res 1
curSetWidth:	.res 2
curHeight:	    .res 1
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

;.include "font_internal.inc"

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