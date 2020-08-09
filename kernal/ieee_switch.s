;----------------------------------------------------------------------
; IEEE Switch
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "banks.inc"

.import jsrfar
.import clock_get_date_time

.import cbdos_secnd
.import cbdos_tksa
.import cbdos_acptr
.import cbdos_ciout
.import cbdos_untlk
.import cbdos_unlsn
.import cbdos_listn
.import cbdos_talk

.import serial_secnd
.import serial_tksa
.import serial_acptr
.import serial_ciout
.import serial_untlk
.import serial_unlsn
.import serial_listn
.import serial_talk

.export ieeeswitch_init
.export secnd
.export tksa
.export acptr
.export ciout
.export untlk
.export unlsn
.export listn
.export talk

.segment "KVAR"

cbdos_unit:
	.res 1

.segment "IEEESWTCH"

ieeeswitch_init:
	lda #8
	sta cbdos_unit
	jsr jsrfar
	.word $c000 + 3 * 15 ; cbdos_init
	.byte BANK_CBDOS
	rts

secnd:
	bit cbdos_unit
	bpl :+
	jmp serial_secnd
:	jsr upload_time
	jsr jsrfar
	.word $c000 + 3 * 0
	.byte BANK_CBDOS
	rts

tksa:
	bit cbdos_unit
	bpl :+
	jmp serial_tksa
:	jsr jsrfar
	.word $c000 + 3 * 1
	.byte BANK_CBDOS
	rts

acptr:
	bit cbdos_unit
	bpl :+
	jmp serial_acptr
:	jsr jsrfar
	.word $c000 + 3 * 2
	.byte BANK_CBDOS
	rts

ciout:
	bit cbdos_unit
	bpl :+
	jmp serial_ciout
:	jsr jsrfar
	.word $c000 + 3 * 3
	.byte BANK_CBDOS
	rts

untlk:
	bit cbdos_unit
	bpl :+
	jmp serial_untlk
:	jsr jsrfar
	.word $c000 + 3 * 4
	.byte BANK_CBDOS
	rts

unlsn:
	bit cbdos_unit
	bpl :+
	jmp serial_unlsn
:	jsr jsrfar
	.word $c000 + 3 * 5
	.byte BANK_CBDOS
	rts

listn:
	asl
	asl cbdos_unit
	cmp cbdos_unit
	php
	lsr
	lsr cbdos_unit
	plp
	bne @1
	jsr jsrfar
	.word $c000 + 3 * 6
	.byte BANK_CBDOS
	lda cbdos_unit
	php
	asl
	plp
	ror
	sta cbdos_unit
	bpl @2
@1:	jmp serial_listn
@2:	rts

talk:
	asl
	asl cbdos_unit
	cmp cbdos_unit
	php
	lsr
	lsr cbdos_unit
	plp
	bne @1
	jsr jsrfar
	.word $c000 + 3 * 7
	.byte BANK_CBDOS
	lda cbdos_unit
	php
	asl
	plp
	ror
	sta cbdos_unit
	bpl @2
@1:	jmp serial_talk
@2:	rts

; Called by SECOND: If it's a CLOSE command, upload the curent time.
upload_time:
	pha
	and #$f0
	cmp #$e0 ; CLOSE
	beq @0
	pla
	rts
@0:
	ldx #2
@1:	lda 0,x
	pha
	inx
	cpx #9
	bne @1

	jsr clock_get_date_time

	; convert from 1900 to 1980
	; 1900 -> no time information (255)
	lda 2
	bne @2
	dec
	bra @3
@2:	sec
	sbc #80
@3:	sta 2

	jsr jsrfar
	.word $c000 + 3 * 16
	.byte BANK_CBDOS

	ldx #8
@4:	pla
	sta 0,x
	dex
	cpx #1
	bne @4

	pla
	rts
