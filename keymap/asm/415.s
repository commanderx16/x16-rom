; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Polish (Programmers)
; Locale: pl-PL
; KLID:   415

.segment "KBDMETA"

	.byte "PL-PL", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_415

.segment "KBDTABLES"

kbtab_415:
	.incbin "asm/415.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~ÓóĄąĆćĘęŁłŃńŚśŹźŻż€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; 'ĄąĆćĘęŁłŃńŚśŹźŻż'
; ISO-8859-15 characters not reachable by this layout:
; 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòôõö÷øùúûüýþ'

