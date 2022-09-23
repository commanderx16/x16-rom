.segment "GRAPH"

.import GRAPH_clear
.import GRAPH_draw_image
.import GRAPH_draw_line
.import GRAPH_draw_oval
.import GRAPH_draw_rect
.import GRAPH_init
.import GRAPH_move_rect
.import GRAPH_set_colors
.import GRAPH_set_window
.import FB_cursor_next_line
.import FB_cursor_position
.import FB_fill_pixels
.import FB_filter_pixels
.import FB_get_info
.import FB_get_pixel
.import FB_get_pixels
.import FB_init
.import FB_move_pixels
.import FB_set_8_pixels
.import FB_set_8_pixels_opaque
.import FB_set_palette
.import FB_set_pixel
.import FB_set_pixels
.import GRAPH_get_char_size
.import GRAPH_put_char
.import GRAPH_set_font
.import font_init
.import set_window_fullscreen

.import console_init, console_put_char, console_get_char, console_put_image, console_set_paging_message

;Jump table

jmp GRAPH_clear                 ;C000
jmp GRAPH_draw_image            ;C003
jmp GRAPH_draw_line             ;C006
jmp GRAPH_draw_oval             ;C009
jmp GRAPH_draw_rect             ;C00C
jmp GRAPH_init                  ;C00F
jmp GRAPH_move_rect             ;C012
jmp GRAPH_set_colors            ;C015
jmp GRAPH_set_window            ;C018

jmp GRAPH_get_char_size         ;C01B
jmp GRAPH_put_char              ;C01E
jmp GRAPH_set_font              ;C021
jmp font_init                   ;C024

jmp console_init                ;C027
jmp console_put_char            ;C02A
jmp console_get_char            ;C02D
jmp console_put_image           ;C030
jmp console_set_paging_message  ;C033

jmp set_window_fullscreen       ;C036

.include "banks.inc"
.segment "VECTORS" 
 .byt $ff, $ff, $ff, $ff, <banked_irq, >banked_irq