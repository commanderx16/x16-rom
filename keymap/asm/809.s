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
; ~~~~~~~
; C64 keyboard regressions:
;   --none--
; Keys outside of PETSCII:
;   '\_{|}~¦¬ÁÉÍÓÚáéíóú€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¦'
; Non-reachable ISO-8859-15:
;   ' ¡¢¥Š§š©ª«­®¯°±²³Žµ¶·ž¹º»ŒœŸ¿ÀÂÃÄÅÆÇÈÊËÌÎÏÐÑÒÔÕÖ×ØÙÛÜÝÞßàâãäåæçèêëìîïðñòôõö÷øùûüýþ'

