; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Spanish
; Locale: es-ES
; KLID:   40a

.segment "KBDMETA"

	.byte "ES-ES", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_40a

.segment "KBDTABLES"

kbtab_40a:
	.incbin "asm/40A.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¡¨ª¬´·º¿ÇÑçñ€'

; ISO
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '^π'
; graph: '\xa2\xa3\xa5\xa6\xa7\xa8\xa9\xab\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb8\xb9\xbb\xbc\xbd\xbe'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '^`~¨´'
; ISO-8859-15 characters not reachable by this layout:
; 'ÅÆÐ×ØÞßåæð÷øþ'

