.include "vera.inc"

.code
.export spi_deselect

spi_deselect:
	pha
	ldx #>VERA_SPI
	stx veramid
	ldx #VERA_SPI >> 16
	stx verahi
	ldx #1
	stx veralo  ; ctrl reg
	dex
	stx veradat ; ss=0
	pla
	rts

		; select spi device given in A. the method is aware of the current processor state, especially the interrupt flag
		; in:
		;	A = spi device
		; out:
		;   Z = 1 spi for given device could be selected (not busy), Z=0 otherwise
