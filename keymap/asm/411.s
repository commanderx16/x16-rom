; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Japanese
; Locale: ja-JP
; KLID:   411

.segment "KBDMETA"

	.byte "JA-JP", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_411

.segment "KBDTABLES"

kbtab_411:
	.incbin "asm/411.bin.lzsa"

; PETSCII
; ~~~~~~~
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
;   chars: '£π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
;   '\_{|}~'

; ISO
; ~~~
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
;   --none--
; ISO-8859-15 characters not reachable by this layout:
;   'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþ'

