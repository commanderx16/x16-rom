.include "banks.inc"

.import bjsrfar

.macro bridge symbol
	.local address
	.segment "KSUP_VEC"
address = *
	.segment "KSUP_CODE"
symbol:
	jsr bjsrfar
	.word address
	.byte BANK_KERNAL
	rts
	.segment "KSUP_VEC"
	jmp symbol
.endmacro

	.segment "KSUP_VEC"

	xjsrfar = bjsrfar
	.include "kernsup.inc"

	.byte 0, 0, 0, 0 ; signature

	.word banked_nmi ; nmi
	.word $ffff ; reset
	.word banked_irq
