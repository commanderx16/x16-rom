;----------------------------------------------------------------------
; C64 Entropy Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.export entropy_init, entropy_get

.segment "ENTROPY"

;---------------------------------------------------------------
; entropy_init
;
; Function:  Initialize entropy generator
;
;---------------------------------------------------------------
entropy_init:
	rts

;---------------------------------------------------------------
; entropy_get
;
; Function:  Return 24 random bits
;
; Return:    a    random value
;            x    random value
;            y    random value
;---------------------------------------------------------------
; XXX TODO This is pretty weak. We should set up a timer line on
; XXX TODO the X16.
entropy_get:
	lda $d012
	tax
	tay
	rts
