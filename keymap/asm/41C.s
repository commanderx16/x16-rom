; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Albanian
; Locale: sq-AL
; KLID:   41c

.segment "KBDMETA"

	.byte "SQ-AL", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_41c

.segment "KBDTABLES"

kbtab_41c:
	.incbin "asm/41C.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '£π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¤§¨°´¸ÇË×ßçë÷ĐđŁłˇ˘˙˛˝'

; ISO
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa1\xa2\xa3\xa4\xa5\xa6\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¤¨°´¸ĐđŁłˇ˘˙˛˝'
; ISO-8859-15 characters not reachable by this layout:
; 'ÀÃÅÆÈÊÌÏÐÑÒÕØÙÛÞàãåæèêìïðñòõøùûþ'

