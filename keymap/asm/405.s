; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Czech
; Locale: cs-CZ
; KLID:   405

.segment "KBDMETA"

	.byte "CS-CZ", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_405

.segment "KBDTABLES"

kbtab_405:
	.incbin "asm/405.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   chars: '£π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¤§¨°´¸×ßáéí÷úýčĐđěŁłřšůžˇ˘˙˛˝€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤¨´¸čĐđěŁłřůˇ˘˙˛˝'
; Non-reachable ISO-8859-15:
;   ' ¡¢£¥©ª«¬­®¯±²³µ¶¹º»Œœ¿ÃÆÐÑÕØÞãæðñõøþ'

