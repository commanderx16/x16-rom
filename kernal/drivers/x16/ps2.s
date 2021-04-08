;----------------------------------------------------------------------
; Generic PS/2 Port Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "io.inc"

; data
.importzp mhz ; [declare]

.export ps2_init
.export ps2ena, ps2dis

port_ddr  =d1ddrb ; offset 0!
port_data =d1prb  ; offset 0!
bit_data=1              ; 6522 IO port data bit mask  (PA0/PB0)
bit_clk =2              ; 6522 IO port clock bit mask (PA1/PB1)

ps2bits  = $9000 ; 2 bytes
ps2byte  = $9002 ; 2 bytes
ps2parity= $9004 ; 2 bytes
ps2r     = $9006 ; 2 bytes
ps2w     = $9008 ; 2 bytes

writing  = $900a ; 2 bytes

ps2q0    = $9800
ps2q1    = $9900
ps2err0  = $9a00
ps2err1  = $9b00

VIA_IFR_CA1 = %00000010 ; 0: mouse
VIA_IFR_CA2 = %00000001 ; 1: keyboard

.segment "KVARSB0"


.segment "PS2"

; inhibit PS/2 communication on both ports
ps2_init:
	jsr ps2reset_all

	ldx #0
:	lda ramcode,x
	sta $9200,x
	inx
	cpx #ramcode_end - ramcode
	bne :-

	stz ps2r
	stz ps2r+1
	stz ps2w
	stz ps2w+1

	lda #$ff
	sta ps2bits
	sta ps2bits+1
	stz ps2parity
	stz ps2parity+1

	jsr ps2dis_all

.if 0
	; *** host request-to-send
	; bring the CLK line low for at least 100 microseconds
	ldx #1
	jsr ps2dis
	jsr delay_100us
	; bring the DATA line low
	lda port_data + 1
	and #$ff - bit_data
	sta port_data + 1

	lda #$80
	sta writing + 1

	; enable CLK positive edge NMI
	; VIA#1 CA2 IRQ: independent interrupt input-negative edge
	lda d1pcr
	and #%11110000
	ora #%00000010
	sta d1pcr
	lda #$80 + VIA_IFR_CA2 ; 1: keyboard
	sta d1ier

	; release the Clock line
	lda port_ddr + 1
	and #$ff - bit_clk
	sta port_ddr + 1

.if 0
	ldy #$4d

@loop:
	; wait for the device to bring the Clock line low
	lda #bit_clk
:	bit port_data + 1
	bne :-

	; set/reset the Data line to send the first data bit
	tya
	lsr
	tay
	php
	lda port_data + 1
	lsr
	plp
	rol
	sta port_data + 1

	; wait for the device to bring Clock high
	lda #bit_clk
:	bit port_data + 1
	beq :-

	jmp @loop
.endif

	jmp *

;------
.endif

	; VIA#1 CA1 IRQ: interrupt input-negative edge
	; VIA#1 CA2 IRQ: independent interrupt input-negative edge
	lda d1pcr
	and #%11110000
	ora #%00000010
	sta d1pcr

	; enable keyboard
	ldx #1 ; keyboard
	jmp ps2ena
	; keep mouse disabled by default

;****************************************
ps2ena_all:
	ldx #1 ; PA: keyboard
	jsr ps2ena
	dex    ; PB: mouse
ps2ena:
	; enable NMI
	txa
	bne @1
	lda #$80 + VIA_IFR_CA1 ; 0: mouse
	bra @2
@1:	lda #$80 + VIA_IFR_CA2 ; 1: keyboard
@2:	sta d1ier

	lda port_ddr,x ; set CLK and DATA as input
	and #$ff - bit_clk - bit_data
	sta port_ddr,x ; -> bus is idle, device can start sending
	rts

;****************************************
ps2dis_all:
	ldx #1 ; PA: keyboard
	jsr ps2dis
	dex    ; PB: mouse
ps2dis:
	; disable NMI
	txa
	bne @1
	lda #VIA_IFR_CA1 ; 0: mouse
	bra @2
@1:	lda #VIA_IFR_CA2 ; 1: keyboard
@2:	sta d1ier

	lda port_data,x
	and #$ff - bit_clk ; CLK=0
	ora #bit_data      ; DATA=1
	sta port_data,x
	lda port_ddr,x
	ora #bit_clk + bit_data
	sta port_ddr,x ; set CLK and DATA as output
	rts

;****************************************
; only call this while PS/2 NMI is disabled,
; otherwise it could cause an NMI!
ps2reset_all:
	ldx #1 ; PA: keyboard
	jsr ps2reset
	dex    ; PB: mouse
ps2reset:
	lda port_ddr,x
	ora #bit_clk + bit_data
	sta port_ddr,x ; set CLK and DATA as output
	lda port_data,x
	and #$ff - bit_clk - bit_data ; CLK=0, DATA=0
	sta port_data,x
	rts

ramcode:
; NMI
	pha
	phx
	lda d1ifr
@again:	ldx #1 ; 1 = offset of PA
	bit #VIA_IFR_CA2 ; 1: keyboard
	beq @1
	lda #VIA_IFR_CA2 ; 1: keyboard
	sta d1ifr
	bra @cont
@1:	dex    ; 0 = offset of PB
	bit #VIA_IFR_CA1 ; 0: mouse
	beq @2
	lda #VIA_IFR_CA1 ; 0: mouse
	sta d1ifr
	bra @cont
	; else: NMI button
@2:	plx
	pla
	; TODO
	rti

@cont:
	lda port_data,x
	and #bit_data
	phy
	ldy ps2bits,x
	cpy #8
	bcs @n_data_bit

; *********************
; 0-7: data bit
; *********************
	cmp #1
	bcc :+
	inc ps2parity,x
:	ror ps2byte,x
@inc_rti:
	inc ps2bits,x
@pull_rti:
	ply
	lda d1ifr
	bne @again
	plx
	pla
	rti

@n_data_bit:
	bne @n_parity_bit

; *********************
; 8: parity bit
; *********************
	ldy ps2parity,x
	cmp #1
	bcc :+
	iny
:	tya
	ror
	bcs @inc_rti
	bra @error

@n_parity_bit:
	bpl @n_start ; not -1

; *********************
; -1: start bit
; *********************
	cmp #1
	bcc @inc_rti ; clear = OK
	bra @error

@n_start:
; *********************
; 9: stop bit
; *********************
	cmp #1
	bcc @error ; set = OK
	; If the stop bit is incorrect, inhibiting communication
	; at this late point won't cause a re-send from the
	; device, so effectively, we will only ignore the
	; byte and clear the queue.

	; byte complete
	lda ps2byte,x ; value
	ldy ps2w,x    ; target offset in queue

	cpx #0
	bne @p1
	sta ps2q0,y
	lda #0
	sta ps2err0,y
	bra @cont2
@p1:	sta ps2q1,y
	lda #0
	sta ps2err1,y
@cont2:

	inc ps2w,x

	lda #0
	sta ps2parity,x
	dec
	sta ps2bits,x
	bra @pull_rti

@error:
	; inhibit for 100 µs
	jsr ps2dis

	; put error into queue
	ldy ps2w,x
	lda #1
	cpx #0
	bne @p1a
	sta ps2err0,y
	bra @cont3
@p1a:	sta ps2err1,y
@cont3:	inc ps2w,x

	; start with new byte
	lda #0
	sta ps2parity,x
	dec
	sta ps2bits,x

	php
	cli

	jsr delay_100us

	plp

	jsr ps2ena
	jmp @pull_rti

ramcode_end:

delay_100us:
	ldy #100/5*mhz - 2
:	dey
	bne :- ; 5 clocks
	rts

.export ps2_get_byte
;****************************************
; RECEIVE BYTE
; out: A: byte (0 if none available)
;      Z: byte available
;           0: yes
;           1: no
;      C:   0: byte OK
;           1: byte error
;****************************************
ps2_get_byte:
	lda ps2w,x
	cmp ps2r,x
	bne @1
	lda #0
	clc
	rts ; Z=1, C=0 -> no data, no error

@1:	ldy ps2r,x ; offset

	cpx #0
	bne @p1

	lda ps2err0,y
	ror        ; C=error flag
	lda ps2q0,y; A=byte
	bra @cont

@p1:	lda ps2err1,y
	ror        ; C=error flag
	lda ps2q1,y; A=byte

@cont:

	inc ps2r,x
	ldx #1    ; Z=0
	rts
