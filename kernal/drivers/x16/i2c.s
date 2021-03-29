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


.setcpu		"6502"

.export _i2cStart
.export _i2cStop
.export _i2cAck
.export _i2cNack
.export _i2cWrite
.export _i2cRead

VIA1_BASE   = $8100
PRA  = VIA1_BASE+1
DDRA = VIA1_BASE+3

SDA = (1 << 0)
SCL = (1 << 1)

.segment "CODE"


_i2cWrite:
	ldx #0
	stx PRA
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


_i2cRead:
	lda #0
	sta PRA
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


send_bit:
	cmp #1                  ; bit in accu
	beq @set_sda
@clear_sda:
	jsr sda_low
	jmp @clock_out
@set_sda:
	jsr sda_high
	jmp	@clock_out
@clock_out:
	jsr scl_high
	jsr scl_low
	jsr sda_low
	rts


rec_bit:
	jsr sda_high
	jsr scl_high
	lda PRA
	and #SDA
	bne @is_one
	lda #0
	jmp @end
@is_one:
	lda #1
@end:	jsr scl_low
	jsr sda_low
	rts


_i2cStart:
	jsr sda_low
	jsr scl_low
	rts


_i2cStop:
	jsr scl_high
	jsr sda_high
	rts


_i2cAck:
	pha
	lda #0
	jsr send_bit
	pla
	rts


_i2cNack:
	pha
	lda #1
	jsr send_bit
	pla
	rts


sda_low:
	pha
	lda DDRA
	ora #SDA
	sta DDRA
	pla
	rts


sda_high:
	pha
	lda #SDA
	eor #$FF
	and DDRA
	sta DDRA
	pla
	rts


scl_low:
	pha
	lda DDRA
	ora #SCL
	sta DDRA
	pla
	rts


scl_high:
	pha
	lda #SCL
	eor #$FF
	and DDRA
	sta DDRA
	pla
	rts

