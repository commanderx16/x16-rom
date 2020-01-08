.export emulator_get_data, ioinit,iokeys,irq_ack,restore_basic,ramtas,jsrfar,indfet,cmpare,stash,screen_clear_line,screen_copy_line,screen_get_char,screen_get_char_color,screen_get_color,screen_init,screen_restore_state,screen_save_state,screen_set_char,screen_set_char_color,screen_set_charset,screen_set_color,screen_set_mode,screen_set_position,kbd_clear,kbd_config,kbd_get,kbd_get_modifiers,kbd_get_stop,kbd_put,kbd_scan,clock_get_date_time,clock_get_timer,clock_set_date_time,clock_set_timer,clock_update,bsi232,bso232,cki232,cko232,cls232,opn232,joystick_get,joystick_scan,monitor,mouse_config,mouse_get,mouse_scan,sprite_set_image,sprite_set_position,GRAPH_clear,GRAPH_draw_image,GRAPH_draw_line,GRAPH_draw_oval,GRAPH_draw_rect,GRAPH_get_char_size,GRAPH_init,GRAPH_move_rect,GRAPH_put_char,GRAPH_set_colors,GRAPH_set_font,GRAPH_set_window,console_get_char,console_init,console_put_char,console_put_image,console_set_paging_message

.segment "MACHINE"

; system driver
emulator_get_data:
ioinit:
iokeys:
irq_ack:
restore_basic:
	brk

; monitor
monitor:
	brk

.segment "MEMDRV"

; memory
ramtas:
jsrfar:
indfet:
cmpare:
stash:
	brk

.segment "SCREEN"

; screen
screen_clear_line:
screen_copy_line:
screen_get_char:
screen_get_char_color:
screen_get_color:
screen_init:
screen_restore_state:
screen_save_state:
screen_set_char:
screen_set_char_color:
screen_set_charset:
screen_set_color:
screen_set_mode:
screen_set_position:
	brk

.segment "PS2KBD" ; XXX rename

; keyboard
kbd_clear:
kbd_config:
kbd_get:
kbd_get_modifiers:
kbd_get_stop:
kbd_put:
kbd_scan:
	brk

.segment "TIME" ; XXX rename

; clock
clock_get_date_time:
clock_get_timer:
clock_set_date_time:
clock_set_timer:
clock_update:
	brk

.segment "RS232"

; rs232
bsi232:
bso232:
cki232:
cko232:
cls232:
opn232:
	brk

.segment "JOYSTICK"

; joystick
joystick_get:
joystick_scan:
	brk

.segment "PS2MOUSE" ; XXX rename

; mouse
mouse_config:
mouse_get:
mouse_scan:
	brk

.segment "SPRITES"

; sprites
sprite_set_image:
sprite_set_position:
	brk

.segment "GRAPH"

; graph
GRAPH_clear:
GRAPH_draw_image:
GRAPH_draw_line:
GRAPH_draw_oval:
GRAPH_draw_rect:
GRAPH_get_char_size:
GRAPH_init:
GRAPH_move_rect:
GRAPH_put_char:
GRAPH_set_colors:
GRAPH_set_font:
GRAPH_set_window:
	brk

.segment "CONSOLE"

; console
console_get_char:
console_init:
console_put_char:
console_put_image:
console_set_paging_message:
	brk
