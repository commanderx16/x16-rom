.include "../banks.inc"

.import jsrfar

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

.export secnd
.export tksa
.export acptr
.export ciout
.export untlk
.export unlsn
.export listn
.export talk

.segment "KVAR"

cbdos_enabled:
	.res 1

.segment "IEEESWTCH"

secnd:
	bit cbdos_enabled
	bmi :+
	jmp serial_secnd
:	jsr jsrfar
	.word cbdos_secnd
	.byte BANK_CBDOS
	rts

tksa:
	bit cbdos_enabled
	bmi :+
	jmp serial_tksa
:	jsr jsrfar
	.word cbdos_tksa
	.byte BANK_CBDOS
	rts

acptr:
	bit cbdos_enabled
	bmi :+
	jmp serial_acptr
:	jsr jsrfar
	.word cbdos_acptr
	.byte BANK_CBDOS
	rts

ciout:
	bit cbdos_enabled
	bmi :+
	jmp serial_ciout
:	jsr jsrfar
	.word cbdos_ciout
	.byte BANK_CBDOS
	rts

untlk:
	bit cbdos_enabled
	bmi :+
	jmp serial_untlk
:	jsr jsrfar
	.word cbdos_untlk
	.byte BANK_CBDOS
	rts

unlsn:
	bit cbdos_enabled
	bmi :+
	jmp serial_unlsn
:	jsr jsrfar
	.word cbdos_unlsn
	.byte BANK_CBDOS
	rts

listn:
	jsr cbdos_detect
	bit cbdos_enabled
	bmi :+
	jmp serial_listn
:	jsr jsrfar
	.word cbdos_listn
	.byte BANK_CBDOS
	rts

talk:
	bit cbdos_enabled
	bmi :+
	jmp serial_talk
:	jsr jsrfar
	.word cbdos_talk
	.byte BANK_CBDOS
	rts

cbdos_detect:
	pha
	lda #$80
	sta cbdos_enabled
	pla
	rts
