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
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¤¨°´¸ĐđŁłˇ˘˙˛˝'
; ISO-8859-15 characters not reachable by this layout:
; 'ÀÃÅÆÈÊÌÏÐÑÒÕØÙÛÞàãåæèêìïðñòõøùûþ'

