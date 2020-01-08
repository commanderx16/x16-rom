;----------------------------------------------------------------------
; Commdore 64 Machine Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.import clklo
.export emulator_get_data, ioinit,iokeys,irq_ack,monitor

.segment "MACHINE"

;---------------------------------------------------------------
; IOINIT - Initialize I/O Devices
;
; Function:  Init all devices.
;            -- This is KERNAL API --
;---------------------------------------------------------------
ioinit:
	lda #$37
	sta 1
	lda #$2f
	sta 0
	stz $d418       ;mute SID
	jsr clklo       ;release the clock line
; fallthrough

;---------------------------------------------------------------
; Set up VBLANK IRQ
;
;---------------------------------------------------------------
iokeys:
	lda #250
	sta $d012
	lda $d011
	and #$7f
	sta $d011
	lda #1
	sta $d01a
	rts

;---------------------------------------------------------------
; ACK VBLANK IRQ
;
;---------------------------------------------------------------
irq_ack:
	lda #1
	sta $d019
	rts

;---------------------------------------------------------------
; Get some data from the emulator
;
; Function:  Detect an emulator and get config information.
;---------------------------------------------------------------
emulator_get_data:
	lda #0
	rts

; misc
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
