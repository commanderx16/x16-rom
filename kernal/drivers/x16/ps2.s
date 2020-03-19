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

ps2bits  = $9000
ps2byte  = $9001
ps2parity= $9002
ps2c     = $90ff
ps2q     = $9100

.segment "KVARSB0"

_ps2byte:
	.res 1           ;    bit input

.segment "PS2"

; inhibit PS/2 communication on both ports
ps2_init:
	ldx #0
:	lda ramcode,x
	sta $9200,x
	inx
	cpx #ramcode_end - ramcode
	bne :-

	lda #$ff
	sta ps2bits
	lda #0
	sta ps2parity

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

ramcode:
; NMI
	sei ; necessary?
	pha
.if 0
	lda d2ifr
	bit #$02
	beq @n_kbd

; Port 0: keyboard
	lda port_data
	; XXX TODO
	pla
	rti

@n_kbd:
	bit #$10
	beq @n_mouse
.endif
; Port 1: mouse
	lda port_data
	and #bit_data
	phx
	ldx ps2bits
	cpx #8
	bcs @n_data_bit

; *** 0-7: data bit
	and #bit_data
	cmp #bit_data
	bcc :+
	inc ps2parity
:	ror ps2byte
@inc_rti:
	inc ps2bits
	plx
	pla
	rti

@n_data_bit:
	bne @n_parity_bit

; *** 8: parity bit
	ldx ps2parity
	cmp #bit_data
	bcc :+
	inx
:	txa
	ror
	bcs @inc_rti

	brk ; XXX

@n_parity_bit:
	bpl @n_start ; not -1

; *** -1: start bit
	cmp #bit_data
	bcc @inc_rti ; clear = OK
	brk ; XXX error

@n_start:
; *** 9: stop bit
	cmp #bit_data
	bcs @byte_complete ; set = OK
	brk ; XXX error

@byte_complete:
	; byte complete
	lda ps2byte
	sta debug_port
	ldx ps2c
	sta ps2q,x
	inc ps2c

	lda #0
	sta ps2parity
	ldx #$ff
:	stx ps2bits
	plx
	pla
	rti

@n_mouse:
	; NMI button
	pla
	rti

ramcode_end:

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
	lda ps2c
	beq @1
	php
	sei
	ldy ps2q
	ldx #0
:	lda ps2q+1,x
	sta ps2q,x
	inx
	cpx ps2c
	bne :-
	dec ps2c
	plp
	tya
@1:	clc
	rts

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
	sta debug_port
	ldy #1 ; Z=0
	rts

lc08c:	clc
	lda #0 ; Z=1
	rts
