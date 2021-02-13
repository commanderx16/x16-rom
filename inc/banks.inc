; ROM banks
BANK_KERNAL  = 0
BANK_KEYBD   = 1
BANK_CBDOS   = 2
BANK_GEOS    = 3
BANK_BASIC   = 4
BANK_MONITOR = 5
BANK_CHARSET = 6

; XXX these constant RAM addresses are KERNAL
; XXX implementation details and need to go away!
.ifdef MACHINE_X16
cbdos_flags= $0267
status     = $0286 ; channel: status byte
jsrfar3    = $02c4 ; jsrfar: RAM part
jmpfr      = $02e1 ; jsrfar: core jmp instruction
imparm     = $82   ; jsrfar: temporary byte
stavec     = $03b7 ; stash: argument
banked_irq = $038b ; irq handler: RAM part
.elseif .defined(MACHINE_C64)
status     = $029F
;fa         = $029F
imparm     = $E2
.endif

; RAM banks
; 0:   KVARS
; 1-9: GEOS BG SCREEN (320x200) [not currently enabled]
; 255: CBDOS

.ifdef MACHINE_X16

.macro KVARS_START
.import kvswitch_tmp1, kvswitch_tmp2
	php
	sei
	sta kvswitch_tmp1
	pla
	sta kvswitch_tmp2
	lda d1pra
	pha
	stz d1pra
	lda kvswitch_tmp2
	pha
	lda kvswitch_tmp1
	plp
.endmacro

.macro KVARS_END
	php
	sei
	sta kvswitch_tmp1
	pla
	sta kvswitch_tmp2
	pla
	sta d1pra
	lda kvswitch_tmp2
	pha
	lda kvswitch_tmp1
	plp
.endmacro

.else ; C64

.macro KVARS_START
.endmacro

.macro KVARS_END
.endmacro

.endif
