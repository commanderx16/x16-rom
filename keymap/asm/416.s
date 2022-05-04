; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Portuguese (Brazil ABNT)
; Locale: pt-BR
; KLID:   416

.segment "KBDMETA"

	.byte "PT-BR", 0
	.word kbtab_416

.segment "KBDTABLES"

kbtab_416:
	.incbin "asm/416.bin.lzsa"

; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¢§¨ª¬°²³´¹ºÇç₢'

; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa1\xa4\xa5\xa6\xa8\xa9\xab\xad\xae\xaf\xb1\xb4\xb5\xb6\xb7\xb8\xbb\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¨´₢'

