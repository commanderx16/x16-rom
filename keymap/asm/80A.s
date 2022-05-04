; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Latin American
; Locale: es-MX
; KLID:   80a

.segment "KBDMETA"

	.byte "ES-MX", 0
	.word kbtab_80a

.segment "KBDTABLES"

kbtab_80a:
	.incbin "asm/80A.bin.lzsa"

; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '£π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\x1b\x1c\x1d\_{|}~¡¨¬°´¿Ññ'

; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xad\xae\xaf\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¨´'

