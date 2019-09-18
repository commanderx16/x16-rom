.include "vera.inc"

.code
.export spi_select_device

; select spi device given in A. the method is aware of the current processor state, especially the interrupt flag
; in:
;	A = spi device
; out:
;   Z = 1 spi for given device could be selected (not busy), Z=0 otherwise
spi_select_device:
	ldx #>VERA_SPI
	stx veramid
	ldx #VERA_SPI >> 16
	stx verahi
	ldx #1
	stx veralo  ; ctrl reg
	stx veradat ; ss=1
  	rts
