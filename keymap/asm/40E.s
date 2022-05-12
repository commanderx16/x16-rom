; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Hungarian
; Locale: hu-HU
; KLID:   40e

.segment "KBDMETA"

	.byte "HU-HU", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_40e

.segment "KBDTABLES"

kbtab_40e:
	.incbin "asm/40E.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¤§¨°´¸ÁÄÉÍÓÖ×ÚÜßáäéíóö÷úüĐđŁłŐőŰűˇ˘˙˛˝€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¤¨´¸ĐđŁłŐőŰűˇ˘˙˛˝'
; ISO-8859-15 characters not reachable by this layout:
; 'ÀÃÅÆÈÊÌÏÐÑÒÕØÙÛÞàãåæèêìïðñòõøùûþ'

