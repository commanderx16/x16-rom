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

.export I_FB_BASE
.export I_FB_init
.export I_FB_get_info
.export I_FB_set_palette
.export I_FB_cursor_position
.export I_FB_cursor_next_line
.export I_FB_get_pixel
.export I_FB_get_pixels
.export I_FB_set_pixel
.export I_FB_set_pixels
.export I_FB_set_8_pixels
.export I_FB_set_8_pixels_opaque
.export I_FB_fill_pixels
.export I_FB_filter_pixels
.export I_FB_move_pixels
.export I_FB_END

.segment "GDRVVEC"
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

FB_init:
	jmp (I_FB_init)
FB_get_info:
	jmp (I_FB_get_info)
FB_set_palette:
	jmp (I_FB_set_palette)
FB_cursor_position:
	jmp (I_FB_cursor_position)
FB_cursor_next_line:
	jmp (I_FB_cursor_next_line)
FB_get_pixel:
	jmp (I_FB_get_pixel)
FB_get_pixels:
	jmp (I_FB_get_pixels)
FB_set_pixel:
	jmp (I_FB_set_pixel)
FB_set_pixels:
	jmp (I_FB_set_pixels)
FB_set_8_pixels:
	jmp (I_FB_set_8_pixels)
FB_set_8_pixels_opaque:
	jmp (I_FB_set_8_pixels_opaque)
FB_fill_pixels:
	jmp (I_FB_fill_pixels)
FB_filter_pixels:
	jmp (I_FB_filter_pixels)
FB_move_pixels:
	jmp (I_FB_move_pixels)