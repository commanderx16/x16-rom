;----------------------------------------------------------------------
; VERA 320x240@256c Graphics Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

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

.import grjsrfar

.segment "GRAPH"

FB_init:
	jsr grjsrfar
    .word $fef6
    .byte 0
    rts

FB_get_info:
	jsr grjsrfar
    .word $fef9
    .byte 0
    rts

FB_set_palette:
	jsr grjsrfar
    .word $fefc
    .byte 0
    rts

FB_cursor_position:
	jsr grjsrfar
    .word $feff
    .byte 0
    rts

FB_cursor_next_line:
	jsr grjsrfar
    .word $ff02
    .byte 0
    rts

FB_get_pixel:
	jsr grjsrfar
    .word $ff05
    .byte 0
    rts

FB_get_pixels:
	jsr grjsrfar
    .word $ff08
    .byte 0
    rts

FB_set_pixel:
	jsr grjsrfar
    .word $ff0b
    .byte 0
    rts

FB_set_pixels:
	jsr grjsrfar
    .word $ff0e
    .byte 0
    rts

FB_set_8_pixels:
	jsr grjsrfar
    .word $FF11
    .byte 0
    rts

FB_set_8_pixels_opaque:
	jsr grjsrfar
    .word $ff14
    .byte 0
    rts

FB_fill_pixels:
	jsr grjsrfar
    .word $ff17
    .byte 0
    rts

FB_filter_pixels:
	jsr grjsrfar
    .word $ff1a
    .byte 0
    rts

FB_move_pixels:
	jsr grjsrfar
    .word $ff1d
    .byte 0
    rts