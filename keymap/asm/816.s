; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Portuguese
; Locale: pt-PT
; KLID:   816

.segment "KBDMETA"

	.byte "PT-PT", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_816

.segment "KBDTABLES"

kbtab_816:
	.incbin "asm/816.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~§¨ª«´º»Çç€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '^`~¨´'
; ISO-8859-15 characters not reachable by this layout:
; 'ÅÆÐ×ØÞßåæð÷øþ'

