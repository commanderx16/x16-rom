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
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¤§¨°´¸ÁÄÉÍÓÖ×ÚÜßáäéíóö÷úüĐđŁłŐőŰűˇ˘˙˛˝€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤¨´¸ĐđŁłŐőŰűˇ˘˙˛˝'
; Non-reachable ISO-8859-15:
;   ' ¡¢£¥©ª«¬­®¯±²³µ¶·¹º»ŒœŸ¿ÀÃÅÆÈÊÌÏÐÑÒÕØÙÛÞàãåæèêìïðñòõøùûþ'

