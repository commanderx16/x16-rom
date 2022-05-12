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
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
;   chars: '£π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
;   '\_{|}~¤§¨°´¸×ßáäéíô÷úýčĐđľŁłňšťžˇ˘˙˛˝€'

; ISO
; ~~~
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
;   '¤¨´¸čĐđľŁłňťˇ˘˙˛˝'
; ISO-8859-15 characters not reachable by this layout:
;   'ÀÃÅÆÈÊËÌÏÐÑÒÕØÙÛÞàãåæèêëìïðñòõøùûþ'

