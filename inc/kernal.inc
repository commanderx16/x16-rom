.include "fb.inc"

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
stop                         = $ffe1
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
screen_mode                  = $ff5f ; old name: swapper
screen_set_charset           = $ff62 ; old name: dlchr
pfkey                        = $ff65 ; NYI
jsrfar                       = $ff6e
fetch                        = $ff74
stash                        = $ff77
cmpare                       = $ff7a
primm                        = $ff7d

;
; X16 additions
;
macptr                       = $ff44
enter_basic                  = $ff47
;                            = $ff15
mouse_config                 = $ff68
mouse_get                    = $ff6b
mouse_scan                   = $ff71
;
joystick_scan                = $ff53
joystick_get                 = $ff56
;
clock_set_date_time          = $ff4d
clock_get_date_time          = $ff50

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

.if 0
;
; framebuffer API
;
FB_init                      = $fef6
FB_get_info                  = $fef9
FB_set_palette               = $fefc
FB_cursor_position           = $feff
FB_cursor_next_line          = $ff02
FB_get_pixel                 = $ff05
FB_get_pixels                = $ff08
FB_set_pixel                 = $ff0b
FB_set_pixels                = $ff0e
FB_set_8_pixels              = $ff11
FB_set_8_pixels_opaque       = $ff14
FB_fill_pixels               = $ff17
FB_filter_pixels             = $ff1a
FB_move_pixels               = $ff1d
.endif

sprite_set_image             = $fef0
sprite_set_position          = $fef3

memory_fill                  = $fee4
memory_copy                  = $fee7
memory_crc                   = $feea
memory_decompress            = $feed

console_init                 = $fedb
console_put_char             = $fede
console_get_char             = $fee1
console_put_image            = $fed8
console_set_paging_message   = $fed5

keymap                       = $fed2

entropy_get                  = $fecf

;monitor                      = $fecc

i2c_read_byte                = $fec6
i2c_write_byte               = $fec9

kbdbuf_peek                  = $febd
kbdbuf_get_modifiers         = $fec0
kbdbuf_put                   = $fec3
