;----------------------------------------------------------------------
; IRQ
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

.import dfltn, dflto, clock_update, cinv, cbinv
.import irq_handler_start, irq_handler_end

.export puls, key

	.segment "IRQ"

.import screen_init
.import joystick_scan
.import mouse_scan
.import kbd_scan
.import cursor_blink
.import irq_ack
.import mouse_update_position
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
	jsr mouse_scan
	jsr mouse_update_position ; (do this first to avoid sprite tearing)
	jsr kbd_scan
	jsr joystick_scan
	jsr clock_update
	jsr cursor_blink

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
