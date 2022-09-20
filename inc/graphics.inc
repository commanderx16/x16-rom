;---------------------------------------------------------------
; This file contains calling address for functions exposed in
; the graphics ROM bank.
;---------------------------------------------------------------

gr_GRAPH_clear                 = $C000
gr_GRAPH_draw_image            = $C003
gr_GRAPH_draw_line             = $C006
gr_GRAPH_draw_oval             = $C009
gr_GRAPH_draw_rect             = $C00C
gr_GRAPH_init                  = $C00F
gr_GRAPH_move_rect             = $C012
gr_GRAPH_set_colors            = $C015
gr_GRAPH_set_window            = $C018

gr_GRAPH_get_char_size         = $C01B
gr_GRAPH_put_char              = $C01E
gr_GRAPH_set_font              = $C021
gr_font_init                   = $C024

gr_console_init                = $C027
gr_console_put_char            = $C02A
gr_console_get_char            = $C02D
gr_console_put_image           = $C030
gr_console_set_paging_message  = $C033