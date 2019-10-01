.import banked_irq
.segment "IRQA"
	.word banked_irq
.segment "IRQB"
	.word banked_irq
