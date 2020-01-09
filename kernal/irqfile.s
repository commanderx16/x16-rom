	.segment "IRQFILE"

.import screen_init
.import mouse_scan
.import joystick_scan
.import cursor_blink
.import irq_ack
.export panic

; puls - checks for real irq's or breaks
;
puls	pha
.ifp02
	txa
	pha
	tya
	pha
	cld
.else
	phx
	phy
.endif
	tsx
	lda $104,x      ;get old p status
	and #$10        ;break flag?
	beq puls1       ;...no
	jmp (cbinv)     ;...yes...break instr
puls1	jmp (cinv)      ;...irq

; VBLANK IRQ handler
;
key
	jsr mouse_scan  ;scan mouse (do this first to avoid sprite tearing)
	jsr joystick_scan
	jsr clock_update
	jsr cursor_blink
	jsr kbd_scan

	jsr irq_ack
.ifp02
	pla
	tay
	pla
	tax
.else
	ply
	plx
.endif
	pla
	rti             ;exit from irq routines

;panic nmi entry
;
panic	lda #3          ;reset default i/o
	sta dflto
	lda #0
	sta dfltn
	jmp screen_init
