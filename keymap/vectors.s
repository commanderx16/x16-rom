.include "banks.inc"

.segment "VECTORS"
	.word banked_nmi
	.word $ffff
	.word banked_irq
