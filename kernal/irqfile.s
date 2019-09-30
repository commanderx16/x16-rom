	.segment "IRQFILE"
; puls - checks for real irq's or breaks
;
puls	pha
	phx
	phy
	tsx
	lda $104,x      ;get old p status
	and #$10        ;break flag?
	beq puls1       ;...no
	jmp (cbinv)     ;...yes...break instr
puls1	jmp (cinv)      ;...irq
