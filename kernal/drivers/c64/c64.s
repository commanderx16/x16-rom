;----------------------------------------------------------------------
; Commdore 64 Machine Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.import clklo, entropy_init
.export emulator_get_data, ioinit,iokeys,irq_ack,monitor

.segment "MACHINE"

;---------------------------------------------------------------
; IOINIT - Initialize I/O Devices
;
; Function:  Init all devices.
;            -- This is KERNAL API --
;---------------------------------------------------------------
ioinit:
	; memory banking
	lda #$37
	sta 1
	lda #$2f
	sta 0

	; disable all CIA IRQs and NMIs
	lda #$7f
	sta $dc0d ; disable
	sta $dd0d
	bit $dc0d ; ack
	bit $dd0d

	; disable all VIC IRQs
	lda #0
	sta $d01a ; disble
	lda #$0f
	sta $d019 ; ack

	; SID
	lda #0
	sta $d418       ;mute SID

	jsr entropy_init

	; Serial
	jsr clklo       ;release the clock line
	; XXX this should be "serial_init"
; fallthrough

;---------------------------------------------------------------
; Set up VBLANK IRQ
;
;---------------------------------------------------------------
iokeys:
	lda #250
	sta $d012
	lda $d011    ; screen_init will keep overwriting the MSB
	and #$7f     ; of $d011 with 0, so if the value changes,
	sta $d011    ; it has to be changed there as well!
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


; direct serial without the switch

.import serial_secnd
.import serial_tksa
.import serial_acptr
.import serial_ciout
.import serial_untlk
.import serial_unlsn
.import serial_listn
.import serial_talk
.export secnd
.export tksa
.export acptr
.export ciout
.export untlk
.export unlsn
.export listn
.export talk

secnd = serial_secnd
tksa = serial_tksa
acptr = serial_acptr
ciout = serial_ciout
untlk = serial_untlk
unlsn = serial_unlsn
listn = serial_listn
talk = serial_talk





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
