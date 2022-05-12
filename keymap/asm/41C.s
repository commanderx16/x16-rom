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
; ~~~~~~~
; C64 keyboard regressions:
;   chars: '£π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¤§¨°´¸ÇË×ßçë÷ĐđŁłˇ˘˙˛˝'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤¨´¸ĐđŁłˇ˘˙˛˝'
; Non-reachable ISO-8859-15:
;   'ÀÃÅÆÈÊÌÏÐÑÒÕØÙÛÞàãåæèêìïðñòõøùûþ'

