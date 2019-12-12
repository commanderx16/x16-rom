;
; C64 KERNAL API
;
cint                         = $ff81
ioinit                       = $ff84
ramtas                       = $ff87
;restor                       = $ff8a
vector                       = $ff8d
;setmsg                       = $ff90
second                       = $ff93
tksa                         = $ff96
memtop                       = $ff99
membot                       = $ff9c
scnkey                       = $ff9f
settmo                       = $ffa2
iecin                        = $ffa5
iecout                       = $ffa8
untalk                       = $ffab
unlstn                       = $ffae
listen                       = $ffb1
talk                         = $ffb4
;readst                       = $ffb7
setlfs                       = $ffba
setnam                       = $ffbd
open                         = $ffc0
close                        = $ffc3
chkin                        = $ffc6
ckout                        = $ffc9
clrch                        = $ffcc
basin                        = $ffcf
bsout                        = $ffd2
load                         = $ffd5
save                         = $ffd8
settim                       = $ffdb
rdtim                        = $ffde
;stop                         = $ffe1
getin                        = $ffe4
clall                        = $ffe7
udtim                        = $ffea
screen                       = $ffed
;plot                         = $fff0
iobase                       = $fff3

;
; supported C128 additions
;
close_all                    = $ff4a
lkupla                       = $ff59
lkupsa                       = $ff5c
scrmod                       = $ff5f
dlchr                        = $ff62 ; NYI
pfkey                        = $ff65 ; NYI
jsrfar                       = $ff6e
;fetch                        = $ff74
stash                        = $ff77
cmpare                       = $ff7a
primm                        = $ff7d

;
; X16 additions
;
;monitor                      = $ff44
restore_basic                = $ff47
;                            = $ff15
mouse_config                 = $ff68
mouse_get                    = $ff6b
;
joystick_scan                = $ff53
joystick_get                 = $ff56
;
clock_set_date_time          = $ff4d
clock_get_date_time          = $ff50

;
; low level graphics
;
GRAPH_LL_init                = $fef9
GRAPH_LL_get_info            = $fefc
GRAPH_LL_cursor_position     = $feff
GRAPH_LL_cursor_next_line    = $ff02
GRAPH_LL_get_pixel           = $ff05
GRAPH_LL_get_pixels          = $ff08
GRAPH_LL_set_pixel           = $ff0b
GRAPH_LL_set_pixels          = $ff0e
GRAPH_LL_set_8_pixels        = $ff11
GRAPH_LL_set_8_pixels_opaque = $ff14
GRAPH_LL_fill_pixels         = $ff17
GRAPH_LL_filter_pixels       = $ff1a
GRAPH_LL_move_pixels         = $ff1d

;
; high level graphics & fonts
;
GRAPH_init                   = $ff20
GRAPH_clear                  = $ff23
GRAPH_set_window             = $ff26
GRAPH_set_colors             = $ff29
GRAPH_draw_line              = $ff2c
GRAPH_draw_rect              = $ff2f
GRAPH_move_rect              = $ff32
GRAPH_draw_oval              = $ff35
GRAPH_draw_image             = $ff38
GRAPH_set_font               = $ff3b
GRAPH_get_char_size          = $ff3e
GRAPH_put_char               = $ff41
