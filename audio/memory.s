; Code by Barry Yost (a.k.a. ZeroByte), MooingLemur, and Jestin
; - 2022

; Make memory reservations in this file.

.exportzp azp0, azp0L, azp0H, azptmp

.export ymshadow, returnbank, _PMD
.export psgfreqtmp

; declare 3 bytes of ZP space for audio routines
.segment "ZPAUDIO": zeropage
	azp0:   .res 2  ; 16bit pointer (in the style of r0, r0L, r0H in ABI)
	azp0L   := azp0
	azp0H   := azp0+1

	azptmp: .res 1  ; single-byte TMP  (TODO: if we don't need this, remove it)

.segment "AUDIOBSS"
	psgfreqtmp: .res 2 ; needed temp space for calculating frequencies during some
	                   ; note conversions

; YM2151 is write-only. The library will keep a RAM shadow of writes in order
; to facilitate functionalities like modifying the active values of the chip.
.segment "YMSHADOW"
	ymshadow: .res $100

; define some unused YM registers as extra storage space in the AUDIO page...
; do these need to be symbols, or just a .include file? I'm thinking the latter..
	returnbank := ymshadow + $00 ; for RAM bank-swap return
	_PMD       := ymshadow + $1A ;
