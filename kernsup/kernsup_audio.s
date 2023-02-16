.include "banks.inc"

.macro bridge symbol
	.local address
	.segment "KSUP_VEC10"
address = *
	.segment "KSUP_CODE10"
symbol:
	jsr ajsrfar
	.word address
	.byte BANK_KERNAL
	rts
	.segment "KSUP_VEC10"
	jmp symbol
.endmacro

.setcpu "65c02"

.segment "KSUP_CODE10"

; Audio bank's entry into jsrfar
.setcpu "65c02"
	ram_bank = 0
	rom_bank = 1
.export ajsrfar
ajsrfar:
.include "jsrfar.inc"


.segment "KSUP_VEC10"

	xjsrfar = ajsrfar
.include "kernsup.inc"

	.byte 0, 0, 0, 0 ; signature

	.word banked_nmi ; nmi
	.word $ffff ; reset
	.word banked_irq
