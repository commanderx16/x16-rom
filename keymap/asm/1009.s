; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Canadian French
; Locale: en-CA
; KLID:   1009

.segment "KBDMETA"

	.byte "EN-CA", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_1009

.segment "KBDTABLES"

kbtab_1009:
	.incbin "asm/1009.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   chars: 'π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¢¤¦§¨«¬­¯°±²³´µ¶¸»¼½¾Éé'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤¦¨´¸¼½¾'
; Non-reachable ISO-8859-15:
;   ' ¡€¥Šš©ª®Ž·ž¹ºŒœŸ¿ÃÅÆÐÑÕ×ØÞßãåæðñõ÷øþ'

