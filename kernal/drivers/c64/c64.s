;----------------------------------------------------------------------
; Commdore 64 Machine Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.export emulator_get_data, ioinit,iokeys,irq_ack,restore_basic, monitor

.segment "MACHINE"

; system driver
;---------------------------------------------------------------
; IOINIT - Initialize I/O Devices
;
; Function:  Init all devices.
;            -- This is KERNAL API --
;---------------------------------------------------------------
ioinit:

;---------------------------------------------------------------
; Set up VBLANK IRQ
;
;---------------------------------------------------------------
iokeys:

;---------------------------------------------------------------
; ACK VBLANK IRQ
;
;---------------------------------------------------------------
irq_ack:

;---------------------------------------------------------------
; Get some data from the emulator
;
; Function:  Detect an emulator and get config information.
;            For now, this is the keyboard layout.
;---------------------------------------------------------------
emulator_get_data:

; misc
restore_basic:
	brk

; monitor
monitor:
	brk




.export GRAPH_clear,GRAPH_draw_image,GRAPH_draw_line,GRAPH_draw_oval,GRAPH_draw_rect,GRAPH_get_char_size,GRAPH_init,GRAPH_move_rect,GRAPH_put_char,GRAPH_set_colors,GRAPH_set_font,GRAPH_set_window,console_get_char,console_init,console_put_char,console_put_image,console_set_paging_message

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
