; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Portuguese (Brazil ABNT)
; Locale: pt-BR
; KLID:   416

.segment "KBDMETA"

	.byte "PT-BR", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_416

.segment "KBDTABLES"

kbtab_416:
	.incbin "asm/416.bin.lzsa"

; PETSCII
; ~~~~~~~
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
;   '\_{|}~¢§¨ª¬°²³´¹ºÇç₢'

; ISO
; ~~~
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
;   '¨´₢'
; ISO-8859-15 characters not reachable by this layout:
;   'ÅÆÐ×ØÞßåæð÷øþ'

