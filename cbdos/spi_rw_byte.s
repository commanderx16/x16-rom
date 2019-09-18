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
	ldx #>VERA_SPI
	stx veramid
	ldx #VERA_SPI >> 16
	stx verahi
	ldx #0
	stx veralo  ; data reg
	sta veradat ; send data
	inx
	stx veralo  ; ctrl reg
:	bit veradat
	bmi :-
	dex
	stx veralo  ; data reg
	lda veradat ; get data
	rts
