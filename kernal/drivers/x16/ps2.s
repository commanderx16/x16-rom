;----------------------------------------------------------------------
; Generic PS/2 Port Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD
; (based on "AT-Keyboard" by İlker Fıçıcılar)

.include "io.inc"

; data
.importzp mhz ; [declare]

.export ps2_init
.export ps2ena, ps2dis

port_ddr  =d2ddrb
port_data =d2prb
bit_data=1              ; 6522 IO port data bit mask  (PA0/PB0)
bit_clk =2              ; 6522 IO port clock bit mask (PA1/PB1)

ps2bits  = $9000 ; 2 bytes
ps2byte  = $9002 ; 2 bytes
ps2parity= $9004 ; 2 bytes
ps2r     = $9006 ; 2 bytes
ps2w     = $9008 ; 2 bytes

ps2tmp   = $900a

ps2q     = $9800
ps2err   = $9a00

.segment "KVARSB0"


.segment "PS2"

; inhibit PS/2 communication on both ports
ps2_init:
	ldx #0
:	lda ramcode,x
	sta $9200,x
	inx
	cpx #ramcode_end - ramcode
	bne :-

	lda #0
	sta ps2r
	sta ps2r+1
	sta ps2w
	sta ps2w+1

	lda #$ff
	sta ps2bits
	sta ps2bits+1
	lda #0
	sta ps2parity
	sta ps2parity+1

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

VIA_IFR_CA1 = 2
VIA_IFR_CB1 = 16

ramcode:
; NMI
	pha
	phx
	lda d2ifr
	ldx #1 ; 1 = offset of PA
	bit #VIA_IFR_CA1
	bne @cont
	dex    ; 0 = offset of PB
	bit #VIA_IFR_CB1
	bne @cont
	; else: NMI button
	plx
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
	txa
	clc
	adc #>ps2q
	sta @ps2qp+1
	txa
	clc
	adc #>ps2err
	sta @ps2errp+1

	lda ps2byte,x
	sta debug_port
	ldy ps2w,x
@ps2qp = *+1
	sta ps2q,y
	lda #0
@ps2errp = *+1
	sta ps2err,y
	inc ps2w,x

	lda #0
	sta ps2parity,x
	dec
	sta ps2bits,x
	jmp @pull_rti

@error:
	; inhibit for 100 µs
	lda port_ddr,x
	ora #bit_clk+bit_data
	sta port_ddr,x ; set CLK and DATA as output
	lda port_data,x
	and #$ff - bit_clk ; CLK=0
	ora #bit_data ; DATA=1
	sta port_data,x

	; put error into queue
	ldy ps2w,x
	lda #1
	sta ps2err,y
	inc ps2w,x

	; start with new byte
	lda #0
	sta ps2parity,x
	dec
	sta ps2bits,x

	php
	cli

	ldy #100/5*mhz
:	dey
	bne :- ; 5 clocks

	plp

	lda port_ddr,x ; set CLK and DATA as input
	and #$ff-bit_clk-bit_data
	sta port_ddr,x ; -> bus is idle, device can start sending
	jmp @pull_rti

ramcode_end:

.export ps2_peek_byte, ps2_remove_bytes
;****************************************
; RECEIVE BYTE
; out: A: byte (0 if none available)
;      Z: byte available
;           0: yes
;           1: no
;      C:   0: byte OK
;           1: byte error
;****************************************

ps2_peek_byte:
	lda ps2w,x
	sec
	sbc ps2r,x
	sta ps2tmp
	cpy ps2tmp
	bcc @1
	lda #0
	clc
	rts ; Z=1, C=0 -> no data, no error

@1:
	txa
	clc
	adc #>ps2q
	sta @ps2qp+1
	txa
	clc
	adc #>ps2err
	sta @ps2errp+1

	tya
	clc
	adc ps2r,x
	tay
@ps2errp = *+1
	lda ps2err,y
	ror       ; C=error flag
@ps2qp = *+1
	lda ps2q,y; A=byte
	sta debug_port
	ldx #1    ; Z=0
	rts

ps2_remove_bytes:
@loop:
	tya
	clc
	adc ps2r,x
	sta ps2r,x
	rts

