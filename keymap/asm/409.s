; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   US
; Locale: en-US
; KLID:   409

.segment "KBDMETA"

	.byte "EN-US", 0
	.word kbtab_409

.segment "KBDTABLES"

kbtab_409:
	.incbin "asm/409.bin.lzsa"

; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\x1b\x1c\x1d\_`{|}~'

; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf'

