;----------------------------------------------------------------------
; Generic PS/2 Port Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "io.inc"

; data
.importzp mhz ; [declare]

.export ps2_init
.export ps2ena, ps2dis
.export ps2_get_byte, ps2_send_byte

port_ddr  =d1ddrb ; offset 0!
port_data =d1prb  ; offset 0!
bit_data=1              ; 6522 IO port data bit mask  (PA0/PB0)
bit_clk =2              ; 6522 IO port clock bit mask (PA1/PB1)

ps2bits  = $9000 ; 2 bytes: bit counter
ps2byte  = $9002 ; 2 bytes: sent/received byte
ps2parity= $9004 ; 2 bytes: parity
ps2r     = $9006 ; 2 bytes: buffer pointer for reading
ps2w     = $9008 ; 2 bytes: buffer pointer for writing

sending  = $900a ; 2 bytes: whether we are sending or receiving (bit #7)

ps2q0    = $9800 ; input queue #0
ps2q1    = $9900 ; input queue #1
ps2err0  = $9a00 ; error queue #0
ps2err1  = $9b00 ; error queue #0

VIA_IFR_CA1 = %00000010
VIA_IFR_CA2 = %00000001

VIA_IFR_MOUSE = VIA_IFR_CA1
VIA_IFR_KEYBD = VIA_IFR_CA2

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

	; queue r/w pointers
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
	lda #$80 + VIA_IFR_MOUSE
	bra @2
@1:	lda #$80 + VIA_IFR_KEYBD
@2:	sta d1ier

	lda port_ddr,x ; set CLK and DATA as input
	and #$ff - bit_clk - bit_data
	sta port_ddr,x ; -> bus is idle, device can start sending

	stz sending,x
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
	lda #VIA_IFR_MOUSE
	bra @2
@1:	lda #VIA_IFR_KEYBD
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

;****************************************
; NMI
;****************************************
ramcode:
	pha
	phx
	lda d1ifr
@again:	ldx #1 ; 1 = offset of PA
	bit #VIA_IFR_KEYBD
	beq @1
	lda #VIA_IFR_KEYBD
	sta d1ifr
	bra @cont
@1:	dex    ; 0 = offset of PB
	bit #VIA_IFR_MOUSE
	beq @2
	lda #VIA_IFR_MOUSE
	sta d1ifr
	bra @cont
	; else: NMI button
@2:	plx
	pla
	; TODO
	rti

@cont:
	bit sending,x
	bpl @reading
;****************************************
; SEND
;****************************************
	lda ps2bits,x
	cmp #8
	bcs @send_n_data_bit

; *********************
; SEND: 0-7: data bit
; *********************
	lsr ps2byte,x
	bcc @send_bit
	inc ps2parity,x
@send_bit:
	.assert bit_data = 1, error, ""
	lda port_data,x
	php
	lsr
	plp
	rol
	sta port_data,x

;	jsr debug2

	inc ps2bits,x
	bra @rti

@send_n_data_bit:
	bne @send_n_parity_bit

; *********************
; SEND: 8: parity bit
; *********************
	lda ps2parity,x
	inc
	lsr
	bra @send_bit

@send_n_parity_bit:
; *********************
; SEND: 9: stop bit
; *********************
	cmp #9
	beq @send_bit ; C=1
; *********************
; SEND: 10: ACK in
; *********************
	; set DATA input
	lda port_ddr,x
	and #$ff - bit_data
	sta port_ddr,x

	lda port_data,x
	sta $99ff
	; DATA should be 0
	jsr new_byte_read
	jsr ps2ena
	bra @rti

;****************************************
; RECEIVE
;****************************************
@reading:
	lda port_data,x
	and #bit_data
	phy
	ldy ps2bits,x
	cpy #8
	bcs @receive_n_data_bit

; *********************
; RECEIVE: 0-7: data bit
; *********************
	cmp #1
	bcc :+
	inc ps2parity,x
:	ror ps2byte,x
@inc_rti:
	inc ps2bits,x
@pull_rti:
	ply
@rti:
	lda d1ifr
	and #VIA_IFR_MOUSE | VIA_IFR_KEYBD ; XXX
	beq :+
	jmp @again
:
	jsr debug

	plx
	pla
	rti

@receive_n_data_bit:
	bne @receive_n_parity_bit

; *********************
; RECEIVE: 8: parity bit
; *********************
	ldy ps2parity,x
	cmp #1
	bcc :+
	iny
:	tya
	ror
	bcs @inc_rti
	lda #1
	bra @error

@receive_n_parity_bit:
	bpl @n_start ; not -1

; *********************
; RECEIVE: -1: start bit
; *********************
	cmp #1
	bcc @inc_rti ; clear = OK
	lda #2
	bra @error

@n_start:
; *********************
; RECEIVE: 9: stop bit
; *********************
	cmp #1
	bcc @error3 ; set = OK
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

	jsr new_byte_read
	bra @pull_rti

@error3:
	lda #3
@error:
	; put error into queue
	ldy ps2w,x
	cpx #0
	bne @p1a
	sta ps2err0,y
	bra @cont3
@p1a:	sta ps2err1,y
@cont3:	inc ps2w,x

	; inhibit for 100 µs
	jsr ps2dis

	jsr new_byte_read

	php
	cli

	jsr delay_100us

	plp

	jsr ps2ena
	jmp @pull_rti

ramcode_end:

; XXX this needs to be in RAM!!
delay_100us:
	ldy #100/5*mhz - 2
:	dey
	bne :- ; 5 clocks
	rts

new_byte_read:
	stz ps2parity,x
	lda #$ff
	sta ps2bits,x
	rts

new_byte_write:
	stz ps2parity,x
	stz ps2bits,x
	rts

debug2:
	phy
	lda port_ddr,x
	pha
	and #$ff - bit_data
	sta port_ddr,x
	lda ps2bits,x
	tay
	lda port_data,x
	sta $9980,y
	pla
	sta port_ddr,x
	ply
	rts

debug:
;	lda #'.'
;	jmp $ffd2

	lda VERA_CTRL
	pha
	and #$FE
	sta VERA_CTRL
	lda VERA_ADDR_L
	pha
        lda VERA_ADDR_M
        pha
        lda VERA_ADDR_H
        pha
	stz VERA_ADDR_L
        stz VERA_ADDR_M
        stz VERA_ADDR_H
        inc VERA_DATA0
        pla
        sta VERA_ADDR_H
	pla
        sta VERA_ADDR_M
        pla
	sta VERA_ADDR_L
	pla
	sta VERA_CTRL
	rts

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

ps2_send_byte:
	pha

	; *** host request-to-send
	; bring the CLK line low for at least 100 microseconds
	ldx #1
	jsr ps2dis
	jsr delay_100us
	; bring the DATA line low
	lda port_data,x
	and #$ff - bit_data
	sta port_data,x

	lda #$80
	sta sending,x
	lda #0
	sta ps2bits,x
	pla
	sta ps2byte,x
	jsr new_byte_write

	; enable CLK positive edge NMI
	; VIA#1 CA2 IRQ: independent interrupt input-negative edge
;	lda d1pcr
;	and #%11110000
;	ora #%00000010
;	sta d1pcr

.if 0
	lda #$80 + VIA_IFR_KEYBD
	sta d1ier

	; release the Clock line
	lda port_ddr,x
	and #$ff - bit_clk
	sta port_ddr,x

:	bit sending,x
	bmi :-
	lda #bit_clk
:	bit port_data,x
	beq :-
	rts
.else

	; release the Clock line
	lda port_ddr,x
	and #$ff - bit_clk
	sta port_ddr,x

	lda #0
	sta 2
	lda #$ee
	sta 3

	ldy #0
@loop:
	lda #bit_clk
:	bit port_data,x
	bne :-

	cpy #8
	bcs @1

	lsr 3
	bra @2

@1:	bne @3
	; 8: parity
	sec
	bra @2

@3:	cpy #9
	bne @4
	; 9: stop
	sec
	bra @2

@4:	; 10: ack
	bra @end


@2:
	lda port_data,x
	php
	lsr
	plp
	rol
	sta port_data,x
	sta $99c0,y

	lda #bit_clk
:	bit port_data,x
	beq :-

	iny
	bra @loop

@end:
	lda port_ddr,x
	and #$ff - bit_clk - bit_data
	sta port_ddr,x
	lda port_data,x
	sta $99e0


	ldx #1
	jsr ps2ena
	rts



.endif
