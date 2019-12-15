.include "../banks.inc"

.import bjsrfar, banked_irq

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
via1	=$9f60                  ;VIA 6522 #1
d1prb	=via1+0
d1pra	=via1+1
.import jsrfar3
.import jmpfr
.importzp imparm
.export mjsrfar
mjsrfar:
.include "../jsrfar.inc"


	.segment "KSUP_VEC2"

	xjsrfar = mjsrfar
	.include "kernsup.inc"

	.byte 0, 0, 0, 0 ; signature

	.word $ffff ; nmi
	.word $ffff ; reset
	.word banked_irq
