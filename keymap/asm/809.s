; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   United Kingdom
; Locale: en-GB
; KLID:   809

.segment "KBDMETA"

	.byte "EN-GB", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_809

.segment "KBDTABLES"

kbtab_809:
	.incbin "asm/809.bin.lzsa"

; PETSCII
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_`{|}~¦¬ÁÉÍÓÚáéíóú€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¦ÁÉÍÓÚ'
; ISO-8859-15 characters not reachable by this layout:
; 'ÀÂÃÄÅÆÇÈÊËÌÎÏÐÑÒÔÕÖ×ØÙÛÜÝÞßàâãäåæçèêëìîïðñòôõö÷øùûüýþ'

