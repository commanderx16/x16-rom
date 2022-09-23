.include "mac.inc"
.include "regs.inc"
.include "banks.inc"
.include "graphics.inc"
.include "fb.inc"

.import jsrfar

.export GRAPH_clear
.export GRAPH_draw_image
.export GRAPH_draw_line
.export GRAPH_draw_oval
.export GRAPH_draw_rect
.export GRAPH_init
.export GRAPH_move_rect
.export GRAPH_set_colors
.export GRAPH_set_window

.export col1,col2,col_bg
.import FB_VERA

.segment "KVAR"
col1:	.res 1
col2:	.res 1
col_bg:	.res 1

.assert col1 = $0267, error, "Update col1 in graphics/graph/graph.s"
.assert col2 = $0268, error, "Update col2 in graphics/graph/graph.s"
.assert col_bg = $0269, error, "Update col_bg in graphics/graph/graph.s"

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

.segment "GRAPH"

GRAPH_clear:
    jsr jsrfar
    .word gr_GRAPH_clear
    .byte BANK_GRAPH
    rts

GRAPH_draw_image:
    jsr jsrfar
    .word gr_GRAPH_draw_image
    .byte BANK_GRAPH
    rts

GRAPH_draw_line:
    jsr jsrfar
    .word gr_GRAPH_draw_line
    .byte BANK_GRAPH
    rts

GRAPH_draw_oval:
    jsr jsrfar
    .word gr_GRAPH_draw_oval
    .byte BANK_GRAPH
    rts

GRAPH_draw_rect:
    jsr jsrfar
    .word gr_GRAPH_draw_rect
    .byte BANK_GRAPH
    rts

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
	lda r0L
	ora r0H
	bne :+
	LoadW r0, FB_VERA
:
	; copy VERA driver vectors
	ldy #<(I_FB_END - I_FB_BASE - 1)
:	lda (r0),y
	sta I_FB_BASE,y
	dey
	bpl :-

	jsr FB_init

	jsr jsrfar
    .word gr_set_window_fullscreen
    .byte BANK_GRAPH

	lda #0  ; primary:    black
	ldx #10 ; secondary:  gray
	ldy #1  ; background: white
	jsr jsrfar
    .word gr_GRAPH_set_colors
    .byte BANK_GRAPH

	jsr jsrfar
    .word gr_GRAPH_clear
    .byte BANK_GRAPH

	jsr jsrfar
    .word gr_font_init
    .byte BANK_GRAPH

    rts

GRAPH_move_rect:
    jsr jsrfar
    .word gr_GRAPH_move_rect
    .byte BANK_GRAPH
    rts

GRAPH_set_colors:
    jsr jsrfar
    .word gr_GRAPH_set_colors
    .byte BANK_GRAPH
    rts

GRAPH_set_window:
    jsr jsrfar
    .word gr_GRAPH_set_window
    .byte BANK_GRAPH
    rts
