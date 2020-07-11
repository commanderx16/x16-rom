.include "vera.inc"

.code
.export spi_deselect

spi_deselect:
	stz VERA_SPI_CTRL
	rts

		; select spi device given in A. the method is aware of the current processor state, especially the interrupt flag
		; in:
		;	A = spi device
		; out:
		;   Z = 1 spi for given device could be selected (not busy), Z=0 otherwise
