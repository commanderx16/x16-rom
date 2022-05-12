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
; ~~~~~~~
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
;   '\_{|}~¡¨ª¬´·º¿ÇÑçñ€'

; ISO
; ~~~
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
;   '¨´'
; ISO-8859-15 characters not reachable by this layout:
;   'ÅÆÐ×ØÞßåæð÷øþ'

