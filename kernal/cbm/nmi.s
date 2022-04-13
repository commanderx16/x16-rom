;----------------------------------------------------------------------
; NMI
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

monitor = $fecc
.import enter_basic, cint, ioinit, restor, nminv

.export nmi, nnmi, timb

	.segment "NMI"

nmi	jmp (nminv)
nnmi
;
; timb - where system goes on a brk instruction
;
timb	jsr restor      ;restore system indirects
	jsr ioinit      ;restore i/o for basic
	jsr cint        ;restore screen for basic
	clc
	jmp monitor

