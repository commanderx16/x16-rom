;----------------------------------------------------------------------
; Generic PS/2 Port Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD
; (based on "AT-Keyboard" by İlker Fıçıcılar)

.include "io.inc"

; data
.importzp mhz ; [declare]

.export ps2_init, ps2_receive_byte
.import i2c_read_byte

port_ddr  =d1ddrb
port_data =d1prb
bit_data=1              ; 6522 IO port data bit mask  (PA0/PB0)
bit_clk =2              ; 6522 IO port clock bit mask (PA1/PB1)

smc_address = $42

.segment "KVARSB0"

ps2byte:
.res 1           ;    bit input

.segment "PS2"

; inhibit PS/2 communication on both ports
ps2_init:
	ldx #1 ; PA: keyboard
	jsr ps2dis
	dex    ; PB: mouse
ps2dis:	lda port_ddr,x
	ora #bit_clk ; set CLK as output
	and #$ff - bit_data ; DATA as input
	sta port_ddr,x
	lda port_data,x
	and #$ff - bit_clk ; CLK=0
	ora #bit_data ; DATA=1
	sta port_data,x
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
    txa
    pha
    
    ldx #smc_address
    ldy #$07            ; SMC register that returns the next available keycode
    
    jsr i2c_read_byte
    
    beq ps2_no_byte_received
    cmp #$ee
    beq ps2_no_byte_received
    
    sta ps2byte
    
    pla
    tax

    lda ps2byte
    
    clc
    ldy #1 ; Z=0
    rts
    
ps2_no_byte_received:
    pla
    tax
    
    clc
    lda #0 ; Z=1
    rts