	.segment "IRQFILE"
; simirq - simulate an irq (for cassette read)
;  enter by a jsr simirq
;
simirq	php
	pla             ;fix the break flag
	and #$ef
	pha
; puls - checks for real irq's or breaks
;
puls	pha
	txa
	pha
	tya
	pha
	tsx
	lda $104,x      ;get old p status
	and #$10        ;break flag?
	beq puls1       ;...no
	jmp (cbinv)     ;...yes...break instr
puls1	jmp (cinv)      ;...irq
