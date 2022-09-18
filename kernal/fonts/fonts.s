.export GRAPH_get_char_size
.export GRAPH_put_char
.export GRAPH_set_font
.export font_init
.export leftMargin
.export rightMargin
.export windowBottom
.export windowTop
.export currentMode

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
    jsr $ff6e
    .word $c045
    .byte 8
    rts
GRAPH_put_char:
    jsr $ff6e
    .word $c048
    .byte 8
    rts
GRAPH_set_font:
    jsr $ff6e
    .word $c04b
    .byte 8
    rts
font_init:
    jsr $ff6e
    .word $c04e
    .byte 8
    rts