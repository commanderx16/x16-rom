; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   United States-International
; Locale: en-US
; KLID:   20409

.segment "KBDMETA"

	.byte "EN-US", 0
	.word kbtab_20409

.segment "KBDTABLES"

kbtab_20409:
	.incbin "asm/20409.bin.lzsa"

; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\x1b\x1c\x1d\_`{|}~¡¢¤¥¦§¨©«¬®°²³´µ¶¹»¼½¾¿ÁÄÅÆÇÉÍÐÑÓÖ×ØÚÜÞßáäåæçéíðñóö÷øúüþ‘’€'

; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa2\xa3\xa6\xa7\xa8\xaa\xad\xaf\xb0\xb1\xb4\xb7\xb8\xb9\xba\xbc\xbd\xbe'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¢£¤¦§¨°´¹¼½¾ÁÄÅÆÇÉÍÐÑÓÖØÚÜÞ÷‘’'

