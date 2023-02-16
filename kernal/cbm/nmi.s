;----------------------------------------------------------------------
; NMI
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

rom_bank = 1
monitor = $fecc
.import enter_basic, cint, ioinit, restor, nminv
.import call_audio_init

.export nmi, nnmi, timb

	.segment "NMI"

; sets up the stack just like the RAM trampoline does
nmi	pha
	lda rom_bank
	pha
	jmp (nminv)

; warm reset, ctrl+alt+restore, default value for (nminv)
nnmi	jsr ioinit           ;go initilize i/o devices
	jsr restor           ;go set up os vectors
;
	jsr cint             ;go initilize screen
	jsr call_audio_init  ;initialize audio API and HW.

	clc
	jmp enter_basic

;
; timb - where system goes on a brk instruction
;
timb	jsr restor      ;restore system indirects
	jsr ioinit      ;restore i/o for basic
	jsr cint        ;restore screen for basic
	jsr call_audio_init  ;initialize audio API and HW.
	clc
	jmp monitor

