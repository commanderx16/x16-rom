;----------------------------------------------------------------------
; NMI
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

stop  = $ffe1
.import enter_basic, cint, ioinit, restor, nminv

.export nmi, nnmi, timb

	.segment "NMI"

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
