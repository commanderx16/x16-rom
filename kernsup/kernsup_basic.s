.include "../banks.inc"

.import bjsrfar
.if 0
.import banked_irq
.else
banked_irq = $aaaa ; XXX
.endif

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

	.word $ffff ; nmi
	.word $ffff ; reset
	.word banked_irq
