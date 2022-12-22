; Code by Barry Yost (a.k.a. ZeroByte), MooingLemur, and Jestin
; - 2022

; Make memory reservations in this file.

.exportzp azp0, azp0L, azp0H, azptmp

; declare 3 bytes of ZP space for audio routines
.segment "ZPAUDIO"
	azp0:   .res 2  ; 16bit pointer (in the style of r0, r0L, r0H in ABI)
	azp0L   := azp0
	azp0H   := azp0+1

	azptmp: .res 1  ; single-byte TMP  (TODO: if we don't need this, remove it)

; YM2151 is write-only. The library will keep a RAM shadow of writes in order
; to facilitate functionalities like modifying the active values of the chip.
.segment "SHADOW"
	ymshadow: .res $ff
