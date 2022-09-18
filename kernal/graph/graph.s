.include "mac.inc"
.include "regs.inc"

.export GRAPH_clear
.export GRAPH_draw_image
.export GRAPH_draw_line
.export GRAPH_draw_oval
.export GRAPH_draw_rect
.export GRAPH_init
.export GRAPH_move_rect
.export GRAPH_set_colors
.export GRAPH_set_window
.export console_get_char
.export console_init
.export console_put_char
.export console_put_image
.export console_set_paging_message
.export col1,col2,col_bg
.import FB_VERA

.segment "KVAR"
col1:	.res 1
col2:	.res 1
col_bg:	.res 1

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
    jsr $ff6e
    .word $c000
    .byte 8
    rts

GRAPH_draw_image:
    jsr $ff6e
    .word $c003
    .byte 8
    rts

GRAPH_draw_line:
    jsr $ff6e
    .word $c006
    .byte 8
    rts

GRAPH_draw_oval:
    jsr $ff6e
    .word $c009
    .byte 8
    rts

GRAPH_draw_rect:
    jsr $ff6e
    .word $c00c
    .byte 8
    rts

GRAPH_init:
	lda r0L
	ora r0H
	bne :+
	LoadW r0, FB_VERA

	; copy VERA driver vectors
	ldy #<(I_FB_END - I_FB_BASE - 1)
:	lda (r0),y
	sta I_FB_BASE,y
	dey
	bpl :-

    jsr $ff6e
    .word $c00f
    .byte 8
    rts

GRAPH_move_rect:
    jsr $ff6e
    .word $c012
    .byte 8
    rts

GRAPH_set_colors:
    jsr $ff6e
    .word $c015
    .byte 8
    rts

GRAPH_set_window:
    jsr $ff6e
    .word $c018
    .byte 8
    rts
 
console_get_char:
    jsr $ff6e
    .word $c057
    .byte 8
    rts
  
console_init:
    jsr $ff6e
    .word $c051
    .byte 8
    rts
  
console_put_char:
    jsr $ff6e
    .word $c054
    .byte 8
    rts
  
console_put_image:
    jsr $ff6e
    .word $c05a
    .byte 8
    rts
  
console_set_paging_message:
    jsr $ff6e
    .word $c05d
    .byte 8
    rts