	.segment "RS232NMI"
nmi	sei             ;no irq's allowed...
	jmp (nminv)     ;...could mess up cassettes
nnmi	pha
	phx
	phy
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
	jsr jsrfar
	.word $c000 + 3 ;basic warm start
	.byte BANK_BASIC
	;not reached

prend	ply             ;because of missing screen editor
	plx
	pla
	rti
