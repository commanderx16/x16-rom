;----------------------------------------------------------------------
; I2C Driver
;----------------------------------------------------------------------
; (C)2015,2021 Dieter Hauer, Michael Steil, License: 2-clause BSD

.include "io.inc"

gpio = d2prb
ddr  = d2ddrb
SCL = (1 << 0)
SDA = (1 << 1)

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
	phx
	phy

	phy                ; offset
	phx                ; device
	jsr i2c_start
	pla                ; device
	asl
	pha                ; device * 2
	jsr i2c_write
	plx                ; device * 2
	pla                ; offset
	phx                ; device * 2
	jsr i2c_write
	jsr i2c_stop
	jsr i2c_start
	pla                ; device * 2
	inc
	jsr i2c_write
	jsr i2c_read
	pha
	jsr i2c_nack
	jsr i2c_stop
	pla

	ply
	plx
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
	phx
	phy

	pha                ; value
	phy                ; offset
	phx                ; device
	jsr i2c_start
	pla                ; device
	asl
	jsr i2c_write
	pla                ; offset
	jsr i2c_write
	pla                ; value
	jsr i2c_write
	jsr i2c_stop

	ply
	plx
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

i2c_write:
	ldx #0
	stx gpio
	ldx #9
@loop:	dex
	beq @ack
	rol
	bcc @send_zero
	pha
	lda #1
	jsr send_bit
	pla
	jmp @loop
@send_zero:
	pha
	lda #0
	jsr send_bit
	pla
	jmp @loop
@ack:
	; ldx #0                ; x should be zero already
	jsr rec_bit             ; ack in accu 0 = success
	eor #1                  ; return 1 on success, 0 on fail
@end:	rts


i2c_read:
	lda #0
	sta gpio
	pha
	ldx #9
@loop:	dex
	beq @end
	jsr rec_bit
	ror
	pla
	rol
	pha
	jmp @loop
@end:
	; ldx #0                ; x should be zero already
	pla
	rts

;---------------------------------------------------------------

send_bit:
	cmp #1                  ; bit in accu
	beq @set_sda
@clear_sda:
	jsr sda_low
	jmp @clock_out
@set_sda:
	jsr sda_high
	jmp @clock_out
@clock_out:
	jsr scl_high
	jsr scl_low
	jsr sda_low
	rts


rec_bit:
	jsr sda_high
	jsr scl_high
	lda gpio
	and #SDA
	bne @is_one
	lda #0
	jmp @end
@is_one:
	lda #1
@end:	jsr scl_low
	jsr sda_low
	rts

;---------------------------------------------------------------

i2c_start:
	jsr sda_low
	jsr scl_low
	rts


i2c_stop:
	jsr scl_high
	jsr sda_high
	rts

;---------------------------------------------------------------

.if 0 ; unused - necessary for reading multiple bytes
i2c_ack:
	pha
	lda #0
	jsr send_bit
	pla
	rts
.endif

i2c_nack:
	pha
	lda #1
	jsr send_bit
	pla
	rts

;---------------------------------------------------------------

sda_low:
	pha
	lda ddr
	ora #SDA
	sta ddr
	pla
	rts

sda_high:
	pha
	lda #SDA
	eor #$FF
	and ddr
	sta ddr
	pla
	rts

scl_low:
	pha
	lda ddr
	ora #SCL
	sta ddr
	pla
	rts

scl_high:
	pha
	lda #SCL
	eor #$FF
	and ddr
	sta ddr
	pla
	rts

