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
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa1\xa2\xa5\xa6\xa7\xa8\xa9\xaa\xab\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¦ÁÉÍÓÚ'

