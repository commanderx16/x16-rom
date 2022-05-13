; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Croatian
; Locale: hr-HR
; KLID:   41a

.segment "KBDMETA"

	.byte "HR-HR", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_41a

.segment "KBDTABLES"

kbtab_41a:
	.incbin "asm/41A.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   chars: '£π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¤§¨°´¸×ß÷ĆćČčĐđŁłŠšŽžˇ˘˙˛˝€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤¨´¸ĆćČčĐđŁłˇ˘˙˛˝'
; Non-reachable ISO-8859-15:
;   ' ¡¢£¥©ª«¬­®¯±²³µ¶·¹º»ŒœŸ¿ÀÃÅÆÈÊÌÏÐÑÒÕØÙÛÞàãåæèêìïðñòõøùûþ'

