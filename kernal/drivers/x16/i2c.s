;----------------------------------------------------------------------
; I2C Driver
;----------------------------------------------------------------------
; (C)2015,2021 Dieter Hauer, Michael Steil, License: 2-clause BSD

.include "io.inc"

pr  = d1prb
ddr = d1ddrb
pcr = d1pcr
SDA = (1 << 2)

.segment "I2C"

.export i2c_read_byte, i2c_write_byte

;---------------------------------------------------------------
; i2c_read_byte
;
; Function:
;
; Pass:      x    device
;            y    offset
;
; Return:    a    value
;            x    device (preserved)
;            y    offset (preserved)
;---------------------------------------------------------------
i2c_read_byte:
	php
	sei
	phy
	phx

	jsr i2c_send_addr_offset
	bcs i2c_error
	jsr i2c_stop

	jsr i2c_start
@xxx:	plx
	phx
	txa
	sec
	rol                ; device * 2 + 1
	jsr i2c_write
	jsr i2c_read
	pha
	jsr i2c_nack
	jsr i2c_stop
	pla

	plx
	ply
	plp
	ora #0             ; set flags
	clc
	rts

i2c_error2:
	pla                ; value
i2c_error:
	jsr i2c_stop
	plx
	ply
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
	phy
	phx

	pha                ; value
	jsr i2c_send_addr_offset
	bcs i2c_error2
	pla                ; value
	jsr i2c_write
	jsr i2c_stop

	plx
	ply
	plp
	clc
	rts

i2c_send_addr_offset:
	jsr i2c_init
	jsr i2c_start
	txa                ; device
	asl
	jsr i2c_write
	bcc @ok
	rts
@ok:	tya                ; offset
	jmp i2c_write
; XXX fallthrough


i2c_write:
	ldx #8
@loop:	rol
	pha
	jsr send_bit
	pla
	dex
	bne @loop
	bra rec_bit     ; C = 0: success
; XXX fallthrough

i2c_read:
	ldx #8
@loop:	pha
	jsr rec_bit
	pla
	rol
        dex
	bne @loop
	rts

;---------------------------------------------------------------

i2c_nack:
	sec
; fallthrough

send_bit:
	bcs @1
	jsr sda_low
	bra @2
@1:	jsr sda_high
@2:	jsr scl_high
	jsr scl_low
        bra sda_low

rec_bit:
	jsr sda_high
	jsr scl_high
	lda pr
	.assert SDA = 4, error, "update the shift instructions if SDA is not bit #2"
	lsr
	lsr
	lsr             ; bit -> C
	jsr scl_low
; fallthrough

sda_low:
	lda #SDA
	tsb ddr
	rts

i2c_stop:
	jsr scl_high
sda_high:
	lda #SDA
	trb ddr
	rts

i2c_start:
	jsr sda_low
; fallthrough

scl_low:
	lda pcr
	and #%00011111
	ora #%11000000
	sta pcr
	rts

i2c_init:
	lda #SDA
	trb pr
	bra scl_high
; fallthrough

scl_high:
	lda #%11100000
	tsb pcr
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
