; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Spanish
; Locale: es-ES
; KLID:   40a

.segment "KBDMETA"

	.byte "ES", 0, 0, 0, 0
	.word kbtab_40a

.segment "KBDTABLES"

kbtab_40a:
	.incbin "asm/40A.bin"

; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\x1b\x1c\x1d\_{|}~¡¨ª¬´·º¿ÇÑçñ€'

; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa2\xa3\xa5\xa6\xa7\xa8\xa9\xab\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb8\xb9\xbb\xbc\xbd\xbe'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¨´'

