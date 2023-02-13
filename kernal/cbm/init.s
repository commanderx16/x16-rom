;----------------------------------------------------------------------
; Init
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

.import cint, ramtas, ioinit, enter_basic, restor, vera_wait_ready, call_audio_init

.export start

.segment "INIT"
; start - system reset
;
start	ldx #$ff
	sei
	txs

	jsr ioinit           ;go initilize i/o devices
	jsr ramtas           ;go ram test and set
	jsr restor           ;go set up os vectors
;
	jsr cint             ;go initilize screen
	jsr call_audio_init  ;initialize audio API and HW.
	cli                  ;interrupts okay now

	sec
	jmp enter_basic
