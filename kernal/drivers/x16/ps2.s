;----------------------------------------------------------------------
; Generic PS/2 Port Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD
; (based on "AT-Keyboard" by İlker Fıçıcılar)

.include "io.inc"

; data
.importzp mhz ; [declare]

.export ps2_init, ps2_receive_byte
.export ps2ena, ps2dis

port_ddr  =d2ddrb
port_data =d2prb
bit_data=1              ; 6522 IO port data bit mask  (PA0/PB0)
bit_clk =2              ; 6522 IO port clock bit mask (PA1/PB1)

.segment "KVARSB0"

ps2byte:
.res 1           ;    bit input

.segment "PS2"

; inhibit PS/2 communication on both ports
ps2_init:
	; VIA#2 CA1/CB1 IRQ: trigger on negative edge
	lda d2pcr
	and #%11101110
	sta d2pcr
	; VIA#2 CA1/CB1 IRQ: enable
	lda #%10010010
	sta d2ier

	ldx #1 ; keyboard
	jsr ps2ena
	ldx #0 ; mouse
	jmp ps2dis

;****************************************
ps2ena_all:
	ldx #1 ; PA: keyboard
	jsr ps2ena
	dex    ; PB: mouse
ps2ena:	lda port_ddr,x ; set CLK and DATA as input
	and #$ff-bit_clk-bit_data
	sta port_ddr,x ; -> bus is idle, device can start sending
	rts

;****************************************
ps2dis_all:
	ldx #1 ; PA: keyboard
	jsr ps2dis
	dex    ; PB: mouse
ps2dis:	lda port_ddr,x
	ora #bit_clk+bit_data
	sta port_ddr,x ; set CLK and DATA as output
	lda port_data,x
	and #$ff - bit_clk ; CLK=0
	ora #bit_data ; DATA=1
	sta port_data,x
	rts

.export irq_handler_start, irq_handler_end
.import kbd_scan, mouse_scan

irq_handler_start:
	lda d2ifr
	tax
	and #2
	bne @kbd
	txa
	and #$10
	bne @mouse
	lda #1 ; Z=0: not handled
	rts
@mouse:	jsr mouse_scan
	bra @end
@kbd:	jsr kbd_scan
@end:	lda #0 ; Z=1: handled
	rts

irq_handler_end:
	rts

;****************************************
; RECEIVE BYTE
; out: A: byte (0 = none)
;      Z: byte available
;           0: yes
;           1: no
;      C:   0: parity OK
;           1: parity error
;****************************************
ps2_receive_byte:
; set input, bus idle
	lda port_ddr,x ; set CLK and DATA as input
	and #$ff-bit_clk-bit_data
	sta port_ddr,x ; -> bus is idle, keyboard can start sending

	lda #bit_clk+bit_data
	ldy #10 * mhz
:	dey
	beq lc08c
	bit port_data,x
	bne :- ; wait for CLK=0 and DATA=0 (start bit)

	lda #bit_clk
lc044:	bit port_data,x ; wait for CLK=1 (not ready)
	beq lc044
	ldy #9 ; 9 bits including parity
lc04a:	bit port_data,x
	bne lc04a ; wait for CLK=0 (ready)
	lda port_data,x
	and #bit_data
	cmp #bit_data
	ror ps2byte ; save bit
	lda #bit_clk
lc058:	bit port_data,x
	beq lc058 ; wait for CLK=1 (not ready)
	dey
	bne lc04a
	rol ps2byte ; get parity bit into C
lc061:	bit port_data,x
	bne lc061 ; wait for CLK=0 (ready)
lc065:	bit port_data,x
	beq lc065 ; wait for CLK=1 (not ready)
lc069:	lda ps2byte
	php ; save parity
lc07c:	lsr a ; calculate parity
	bcc lc080
	iny
lc080:	cmp #0
	bne lc07c
	tya
	plp ; transmitted parity
	adc #1
	lsr a ; C=0: parity OK
	lda ps2byte
	ldy #1 ; Z=0
	rts

lc08c:	clc
	lda #0 ; Z=1
	rts
