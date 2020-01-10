.if 0
.import banked_irq
.else
banked_irq = $aaaa; XXX
.endif

.segment "IRQA"
	.word banked_irq
