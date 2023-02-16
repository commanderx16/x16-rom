.include "banks.inc"

.import bjsrfar

.macro bridge symbol
	.local address
	.segment "KSUP_VEC2"
address = *
	.segment "KSUP_CODE2"
symbol:
	jsr mjsrfar
	.word address
	.byte BANK_KERNAL
	rts
	.segment "KSUP_VEC2"
	jmp symbol
.endmacro

.setcpu "65c02"

.segment "KSUP_CODE2"

; BASIC's entry into jsrfar
.setcpu "65c02"
ram_bank = 0
rom_bank = 1
.export mjsrfar
mjsrfar:
.include "jsrfar.inc"


	.segment "KSUP_VEC2"

	xjsrfar = mjsrfar
	.include "kernsup.inc"

	.byte 0, 0, 0, 0 ; signature

	.word banked_nmi ; nmi
	.word $ffff ; reset
	.word banked_irq
