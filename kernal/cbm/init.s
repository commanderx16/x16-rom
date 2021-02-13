;----------------------------------------------------------------------
; Init
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

.import cint, ramtas, ioinit, enter_basic, restor, vera_wait_ready

.export start

	.segment "INIT"
; start - system reset
;
start	ldx #$ff
	sei
	txs

	jsr ioinit      ;go initilize i/o devices
	jsr ramtas      ;go ram test and set
	jsr restor      ;go set up os vectors
;
	jsr cint        ;go initilize screen
	cli             ;interrupts okay now

	sec
	jmp enter_basic
