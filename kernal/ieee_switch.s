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
.export macptr

.export led_update

.segment "KVAR"

_cbdos_flags:  ; bit   7:   =1: CBDOS is listener
	.res 1 ; bit   6:   =1: CBDOS is talker
	       ; bit   5:   =1: error
	       ; bit   4:   =1: active
	       ; bit 3-0:   blink counter
.assert _cbdos_flags = cbdos_flags, error

.segment "IEEESWTCH"

ieeeswitch_init:
	jsr jsrfar
	.word $c000 + 3 * 15 ; cbdos_init
	.byte BANK_CBDOS
	rts

secnd:
	bit cbdos_flags
	bpl :+
	jsr upload_time
	jsr jsrfar
	.word $c000 + 3 * 0
	.byte BANK_CBDOS
	rts
:	jmp serial_secnd

tksa:
	bit cbdos_flags
	bvc :+
	jsr jsrfar
	.word $c000 + 3 * 1
	.byte BANK_CBDOS
	rts
:	jmp serial_tksa

acptr:
	bit cbdos_flags
	bvc :+
	jsr jsrfar
	.word $c000 + 3 * 2
	.byte BANK_CBDOS
	rts
:	jmp serial_acptr

ciout:
	bit cbdos_flags
	bpl :+
	jsr jsrfar
	.word $c000 + 3 * 3
	.byte BANK_CBDOS
	rts
:	jmp serial_ciout

untlk:
	bit cbdos_flags
	bvc :+
	jsr jsrfar
	.word $c000 + 3 * 4
	.byte BANK_CBDOS
	rts
:	jmp serial_untlk

unlsn:
	bit cbdos_flags
	bpl :+
	jsr jsrfar
	.word $c000 + 3 * 5
	.byte BANK_CBDOS
	rts
:	jmp serial_unlsn

listn:
	pha
	phx
	jsr jsrfar
	.word $c000 + 3 * 6
	.byte BANK_CBDOS
	bcs @1 ; no CBDOS device

	lda cbdos_flags
	ora #$80
	sta cbdos_flags
	plx
	pla
	rts

@1:	lda cbdos_flags
	and #$ff-$80
	sta cbdos_flags
	plx
	pla
	jmp serial_listn

talk:
	pha
	phx
	jsr jsrfar
	.word $c000 + 3 * 7
	.byte BANK_CBDOS
	bcs @1 ; no CBDOS device

	lda cbdos_flags
	ora #$40
	sta cbdos_flags
	plx
	pla
	rts

@1:	lda cbdos_flags
	and #$ff-$40
	sta cbdos_flags
	plx
	pla
	jmp serial_talk

macptr:
	bit cbdos_flags
	bvs :+
	sec ; error: unsupported
	rts
:	jsr jsrfar
	.word $c000 + 3 * 17
	.byte BANK_CBDOS
	clc
	rts


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

; Convert the "active" and "error" flags into a solid or
; blinking LED. Board revision 1 doesn't have an LED, so
; we write into a private setting of the emulator for now.
led_update:
	lda cbdos_flags
	bit #$20  ; error?
	beq @no_error

	pha
	and #$f0
	sta cbdos_flags
	pla
	inc       ; increment divider counter
	and #$0f
	ora cbdos_flags
	sta cbdos_flags
	and #$08
	sta $9fbf ; LED on/off for 8 frames each
	rts

@no_error:
	lda cbdos_flags
	and #$10  ; active?
	sta $9fbf ; then LED on
	rts
