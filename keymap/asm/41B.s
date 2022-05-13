; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Slovak
; Locale: sk-SK
; KLID:   41b

.segment "KBDMETA"

	.byte "SK-SK", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_41b

.segment "KBDTABLES"

kbtab_41b:
	.incbin "asm/41B.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   chars: '£π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¤§¨°´¸×ßáäéíô÷úýčĐđľŁłňšťžˇ˘˙˛˝€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤¨´¸čĐđľŁłňťˇ˘˙˛˝'
; Non-reachable ISO-8859-15:
;   ' ¡¢£¥©ª«¬­®¯±²³µ¶¹º»ŒœŸ¿ÀÃÅÆÈÊËÌÏÐÑÒÕØÙÛÞàãåæèêëìïðñòõøùûþ'

