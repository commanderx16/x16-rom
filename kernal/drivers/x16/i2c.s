;----------------------------------------------------------------------
; I2C Driver
;----------------------------------------------------------------------
; (C)2015,2021 Dieter Hauer, Michael Steil, License: 2-clause BSD

.include "io.inc"

pr  = d1prb
ddr = d1ddrb
SDA = (1 << 0)
SCL = (1 << 1)

.segment "ZPKERNAL" : zeropage
i2c_delay_loops:	.res 1

.segment "I2C"

.export i2c_read_byte, i2c_write_byte

;---------------------------------------------------------------
; i2c_read_byte
;
; Function:
;
; Read sequence:
;   Start condition
;     > 7 bits of device address, MSb first
;     > 1 bit = 0 (write indicator bit)
;     < Read ACK/NAK from device
;     > 8 bits of register offset
;   Stop condition
;   Start condition
;     > 7 bits of device address, MSb first
;     > 1 bit = 1 (read indicator bit)
;     < Read ACK/NAK from device (this is not done by the kernel!!)
;     < Read 8 bits from device
;     > NAK to indicate end of requested bytes from device
;   Stop condition
;
; Pass:      x    device
;            y    offset
;
; Return:    a    value
;            x    device (preserved)
;            y    offset (preserved)
;            c    1 on error (NAK)
;---------------------------------------------------------------
i2c_read_byte:
	php
	sei
	phx
	phy

	jsr i2c_init
	jsr i2c_start                        ; SDA -> LOW, (wait 5 us), SCL -> LOW, (no wait)
	txa                ; device
	asl
	pha                ; device * 2
	jsr i2c_write
	bcs @error
	plx                ; device * 2
	tya                ; offset
	phx                ; device * 2
	jsr i2c_write
	jsr i2c_stop
	jsr i2c_start
	pla                ; device * 2
	inc
	jsr i2c_write

	; DELAY to give time to process the register offset
	phx
	ldx i2c_delay_loops
	inx
	bra @2
@1:	jsr sleep_a_bit
	dex
@2:	bne @1
	plx

	jsr i2c_read
	pha
	jsr i2c_nack
	jsr i2c_stop
	pla

	ply
	plx
	plp
	ora #0             ; set flags
	clc
	rts

@error:
	jsr i2c_stop
	pla                ; device * 2
	ply
	plx
	plp
	lda #$ee
	sec
	rts

;---------------------------------------------------------------
; i2c_write_byte
;
; Function:
;
; Pass:      a    value
;            x    device
;            y    offset
;
; Return:    x    device (preserved)
;            y    offset (preserved)
;---------------------------------------------------------------
i2c_write_byte:
	php
	sei
	phx
	phy

	pha                ; value
	jsr i2c_init
	jsr i2c_start
	txa                ; device
	asl
	jsr i2c_write
	bcs @error
	tya                ; offset
	jsr i2c_write
	pla                ; value
	jsr i2c_write
	jsr i2c_stop

	ply
	plx
	plp
	clc
	rts

@error:
	pla                ; value
	ply
	plx
	plp
	sec
	rts

;---------------------------------------------------------------
; Copyright (c) 2015, Dieter Hauer
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
; ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;---------------------------------------------------------------
; i2c_write
;
; Function: Writes a single byte over I2C
;
; Pass:      a    byte to write
;
; Return:    C    1 if ACK, 0 if NAK
;---------------------------------------------------------------
i2c_write:
	ldx #8
@loop:	rol
	pha
	jsr send_bit
	jsr sleep_a_bit
	pla
	dex
	bne @loop
	bra rec_bit     ; C = 0: success

;---------------------------------------------------------------
; i2c_read
;
; Function: Reads a single from a device over I2C
;
; Pass:      None
;
; Return:    a    value from device
;---------------------------------------------------------------
i2c_read:
	ldx #8
@loop:	pha
	jsr rec_bit
	jsr sleep_a_bit
	pla
	rol
	dex
	bne @loop
	rts

;---------------------------------------------------------------

i2c_nack:
	sec
; fallthrough

;---------------------------------------------------------------
; send_bit
;
; Function: Send a single bit over I2C
;
; Pass:      C    bit value to send.
;
; Return:    None
;---------------------------------------------------------------
send_bit:
	bcs @1
	jsr sda_low
	bra @2
@1:	jsr sda_high
@2:	jsr scl_high
	jsr sleep_a_bit
	jsr scl_low
	rts

;---------------------------------------------------------------
; rec_bit
;
; Function: Clock in a single bit from a device over I2C
;
; Pass:      None
;
; Return:    C    bit value received
;---------------------------------------------------------------
rec_bit:
	jsr sda_high
	jsr scl_high
	jsr sleep_a_bit	; Give pull-ups a chance to overcome the I2C wire capacitance
	lda pr
	.assert SDA = (1 << 0), error, "update the shift instructions if SDA is not bit #0"
	lsr             ; bit -> C
	jsr scl_low
; fallthrough

;---------------------------------------------------------------
; sda_low
;
; Function: Actively drive the SDA signal low
;
; Pass:      None
;
; Return:    None
;---------------------------------------------------------------
sda_low:
	lda #SDA
	tsb ddr
	rts

;---------------------------------------------------------------
; i2c_stop
;
; Function: Signal an I2C stop condition
;
; Pass:      None
;
; Return:    None
;---------------------------------------------------------------
i2c_stop:
	jsr sda_low
	jsr sleep_a_bit
	jsr scl_high
	jsr sleep_a_bit
	jsr sda_high
	jsr sleep_a_bit
	rts

;---------------------------------------------------------------
; sda_high
;
; Function: Release SDA signal and let pull up resistors return
;           it to logic 1 level
;
; Pass:      None
;
; Return:    None
;---------------------------------------------------------------
sda_high:
	lda #SDA
	trb ddr
	rts

;---------------------------------------------------------------
; i2c_start
;
; Function: Signal an I2C start condition. The start condition
;           drives the SDA signal low prior to driving SCL low.
;           Both SDA and SCL will be in the LOW state at the end
;           of this function.
;
; Pass:      None
;
; Return:    None
;---------------------------------------------------------------
i2c_start:
	jsr sda_low
	jsr sleep_a_bit
; fallthrough

;---------------------------------------------------------------
; scl_low
;
; Function: Actively drive I2C clock low
;
; Pass:      None
;
; Return:    None
;---------------------------------------------------------------
scl_low:
	lda #SCL
	tsb ddr
	rts

;---------------------------------------------------------------
; i2c_init
;
; Function: Configure VIA for being an I2C controller
;
; Pass:      None
;
; Return:    None
;---------------------------------------------------------------
i2c_init:
	lda #SDA | SCL
	trb pr
	jsr sda_high
; fallthrough

;---------------------------------------------------------------
; scl_high
;
; Function: Release I2C clock signal and let pullups float it to
;           logic 1 level.
;
; Pass:      None
;
; Return:    None
;---------------------------------------------------------------
scl_high:
	lda #SCL
	trb ddr
	rts

;---------------------------------------------------------------
; sleep_a_bit
;
; Function: delay CPU execution to give I2C signals a chance to
;           settle and devices to respond.
;
; Pass:      None
;
; Return:    None
;---------------------------------------------------------------
sleep_a_bit:
	pha
	pla
	pha
	pla
	rts