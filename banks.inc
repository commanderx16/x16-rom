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
; 1-9: GEOS BG SCREEN (320x200)
; 255: CBDOS

.macro KVARS_START
	pha
	lda d1pra
	sta save_ram_bank
	stz d1pra
	pla
.endmacro

.macro KVARS_END
	php
	pha
	lda save_ram_bank
	sta d1pra
	pla
	plp
.endmacro
