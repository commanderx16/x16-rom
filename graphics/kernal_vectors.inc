;---------------------------------------------------------------
; This file contains vectors in the Kernal ROM bank used by
; the graphic and fonts library
;---------------------------------------------------------------

;Framebuffer
k_FB_init                   = $FEF6
k_FB_get_info               = $FEF9
k_FB_set_palette            = $FEFC
k_FB_cursor_position        = $FEFF
k_FB_cursor_next_line       = $FF02
k_FB_get_pixel              = $FF05
k_FB_get_pixels             = $FF08
k_FB_set_pixel              = $FF0B
k_FB_set_pixels             = $FF0E
k_FB_set_8_pixels           = $FF11
k_FB_set_8_pixels_opaque    = $FF14
k_FB_fill_pixels            = $FF17
k_FB_filter_pixels          = $FF1A
k_FB_move_pixels            = $FF1D

;Misc
k_bsout                     = $FFD2