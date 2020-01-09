	.segment "RS232NMI"
nmi	sei             ;no irq's allowed...
	jmp (nminv)     ;...could mess up cassettes
nnmi	pha
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
;
; check for stop key down
;
	jsr stop        ;no .y
	bne prend       ;no stop key...
;
; timb - where system goes on a brk instruction
;
timb	jsr restor      ;restore system indirects
	jsr ioinit      ;restore i/o for basic
	jsr cint        ;restore screen for basic
	clc
	jmp enter_basic

prend
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
	rti
