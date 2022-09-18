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

.import console_init, console_put_char, console_get_char, console_put_image, console_set_paging_message

;Jump table

jmp GRAPH_clear                 ;c000
jmp GRAPH_draw_image            ;c003
jmp GRAPH_draw_line             ;c006
jmp GRAPH_draw_oval             ;c009
jmp GRAPH_draw_rect             ;c00c
jmp GRAPH_init                  ;c00f
jmp GRAPH_move_rect             ;c012
jmp GRAPH_set_colors            ;c015
jmp GRAPH_set_window            ;c018

jmp FB_cursor_next_line         ;c01b
jmp FB_cursor_position          ;c01e
jmp FB_fill_pixels              ;c021
jmp FB_filter_pixels            ;c024
jmp FB_get_info                 ;c027
jmp FB_get_pixel                ;c02a
jmp FB_get_pixels               ;c02d
jmp FB_init                     ;c030
jmp FB_move_pixels              ;c033
jmp FB_set_8_pixels             ;c036
jmp FB_set_8_pixels_opaque      ;c039
jmp FB_set_palette              ;c03c
jmp FB_set_pixel                ;c03f
jmp FB_set_pixels               ;c042

jmp GRAPH_get_char_size         ;c045
jmp GRAPH_put_char              ;c048
jmp GRAPH_set_font              ;c04b
jmp font_init                   ;c04e

jmp console_init                ;c051
jmp console_put_char            ;c054
jmp console_get_char            ;c057
jmp console_put_image           ;c05a
jmp console_set_paging_message  ;c05d

.segment "VECTORS"
banked_irq = $038b

 .byt $ff, $ff, $ff, $ff, <banked_irq, >banked_irq