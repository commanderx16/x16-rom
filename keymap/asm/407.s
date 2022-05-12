; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   German
; Locale: de-DE
; KLID:   407

.segment "KBDMETA"

	.byte "DE-DE", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_407

.segment "KBDTABLES"

kbtab_407:
	.incbin "asm/407.bin.lzsa"

; PETSCII
; ~~~~~~~
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
;   --none--
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
;   '\_{|}~§°²³´µÄÖÜßäöüẞ€'

; ISO
; ~~~
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
;   '´ẞ'
; ISO-8859-15 characters not reachable by this layout:
;   'ÃÅÆÇËÏÐÑÕ×ØÞãåæçëïðñõ÷øþ'

