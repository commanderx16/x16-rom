; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Estonian
; Locale: et-EE
; KLID:   425

.segment "KBDMETA"

	.byte "ET-EE", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_425

.segment "KBDTABLES"

kbtab_425:
	.incbin "asm/425.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¤§´½ÄÕÖÜäõöüŠšŽžˇ€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¤´½ˇ'
; ISO-8859-15 characters not reachable by this layout:
; 'ÁÃÅÆÇËÌÍÏÐÑÔ×ØÚÝÞßáãåæçëìíïðñô÷øúýþ'

