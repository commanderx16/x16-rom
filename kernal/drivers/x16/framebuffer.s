;----------------------------------------------------------------------
; VERA 320x240@256c Graphics Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "mac.inc"
.include "regs.inc"
.include "io.inc"
.include "banks.inc"
.include "graphics.inc"

.export ptr_fg

.export FB_init
.export FB_get_info
.export FB_set_palette
.export FB_cursor_position
.export FB_cursor_next_line
.export FB_get_pixel
.export FB_get_pixels
.export FB_set_pixel
.export FB_set_pixels
.export FB_set_8_pixels
.export FB_set_8_pixels_opaque
.export FB_fill_pixels
.export FB_filter_pixels
.export FB_move_pixels

.import jsrfar

.macro graph_call addr
    jsr jsrfar
    .word addr
    .byte BANK_GRAPH
.endmacro

.segment "KVAR"
ptr_fg:	.res 3

.segment "VERA_DRV"

FB_init:
    graph_call gr_FB_init
    rts

FB_get_info:
    graph_call gr_FB_get_info
    rts

FB_set_palette:
    graph_call gr_FB_set_palette
    rts

FB_cursor_position:
    graph_call gr_FB_cursor_position
    rts

FB_cursor_next_line:
    graph_call gr_FB_cursor_next_line
    rts

FB_get_pixel:
    graph_call gr_FB_get_pixel
    rts

FB_get_pixels:
    graph_call gr_FB_get_pixels
    rts

FB_set_pixel:
    graph_call gr_FB_set_pixel
    rts

FB_set_pixels:
    graph_call gr_FB_set_pixels
    rts

FB_set_8_pixels:
    graph_call gr_FB_set_8_pixels
    rts

FB_set_8_pixels_opaque:
    graph_call gr_FB_set_8_pixels_opaque
    rts

FB_fill_pixels:
    graph_call gr_FB_fill_pixels
    rts

FB_filter_pixels:
    graph_call gr_FB_filter_pixels
    rts

FB_move_pixels:
    graph_call gr_FB_move_pixels
    rts