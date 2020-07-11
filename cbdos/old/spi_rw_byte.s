.include "vera.inc"

.code
.export spi_rw_byte, spi_r_byte

;----------------------------------------------------------------------------------------------
; Receive byte VIA SPI
; Received byte in A at exit, Z, N flags set accordingly to A
; Destructive: A,X
;----------------------------------------------------------------------------------------------
spi_r_byte:
	lda #$ff
;----------------------------------------------------------------------------------------------
; Transmit byte VIA SPI
; Byte to transmit in A, received byte in A at exit
; Destructive: A,X
;----------------------------------------------------------------------------------------------
spi_rw_byte:
	sta VERA_SPI_DATA
:	bit VERA_SPI_CTRL
	bmi :-
	lda VERA_SPI_DATA ; get data
	rts
