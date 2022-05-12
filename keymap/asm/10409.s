; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   United States-Dvorak
; Locale: en-US
; KLID:   10409

.segment "KBDMETA"

	.byte "EN-US/DVO", 0, 0, 0, 0, 0
	.word kbtab_10409

.segment "KBDTABLES"

kbtab_10409:
	.incbin "asm/10409.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '£π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~'

; ISO
; ISO-8859-15 characters not reachable by this layout:
; 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþ'

