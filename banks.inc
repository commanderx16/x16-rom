; ROM banks
BANK_KERNAL  = 0
BANK_KEYBD   = 1
BANK_CBDOS   = 2
BANK_GEOS    = 3
BANK_BASIC   = 4
BANK_MONITOR = 5
BANK_CHARSET = 6

; RAM banks
; 0:   KVARS
; 1-9: GEOS BG SCREEN (320x200) [not currently enabled]
; 255: CBDOS

.macro KVARS_START
.import kvswitch_tmp1, kvswitch_tmp2
	nop
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
	nop
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
