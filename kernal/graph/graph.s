;----------------------------------------------------------------------
; Commander X16 KERNAL: Graphics library
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD
; (Bresenham code based on GEOS by Berkeley Softworks)

.include "mac.inc"
.include "regs.inc"
.include "fb.inc"

.import leftMargin, windowTop, rightMargin, windowBottom
.import FB_VERA

.import font_init

.export GRAPH_init
.export GRAPH_clear
.export GRAPH_set_window
.export GRAPH_set_colors
.export GRAPH_draw_line
.export GRAPH_draw_rect
.export GRAPH_draw_image
.export GRAPH_move_rect
.export GRAPH_draw_oval

.segment "GDRVVEC"

.export I_FB_init, I_FB_get_info, I_FB_set_palette, I_FB_cursor_position, I_FB_cursor_next_line, I_FB_get_pixel, I_FB_get_pixels, I_FB_set_pixel, I_FB_set_pixels, I_FB_set_8_pixels, I_FB_set_8_pixels_opaque, I_FB_fill_pixels, I_FB_filter_pixels, I_FB_move_pixels; [vectors]

I_FB_BASE:
I_FB_init:
	.res 2
I_FB_get_info:
	.res 2
I_FB_set_palette:
	.res 2
I_FB_cursor_position:
	.res 2
I_FB_cursor_next_line:
	.res 2
I_FB_get_pixel:
	.res 2
I_FB_get_pixels:
	.res 2
I_FB_set_pixel:
	.res 2
I_FB_set_pixels:
	.res 2
I_FB_set_8_pixels:
	.res 2
I_FB_set_8_pixels_opaque:
	.res 2
I_FB_fill_pixels:
	.res 2
I_FB_filter_pixels:
	.res 2
I_FB_move_pixels:
	.res 2
I_FB_END:


.segment "KVAR"

.export col1, col2, col_bg
col1:	.res 1
col2:	.res 1
col_bg:	.res 1

.segment "GRAPH"

;---------------------------------------------------------------
; GRAPH_init
;
; Function:  Enable a given low-level graphics mode driver,
;            and switch to this mode.
;
; Pass:      r0     pointer to FB_* driver vectors
;                   If 0, this enables the default driver
;                   (320x240@256c).
;---------------------------------------------------------------
GRAPH_init:
GRAPH_clear:
set_window_fullscreen:
GRAPH_set_window:
GRAPH_set_colors:
GRAPH_draw_line:
HorizontalLine:
VerticalLine:
GRAPH_draw_rect:
GRAPH_draw_image:
GRAPH_move_rect:
GRAPH_draw_oval:
	rts