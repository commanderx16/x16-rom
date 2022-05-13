; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Swedish
; Locale: sv-SE
; KLID:   41d

.segment "KBDMETA"

	.byte "SV-SE", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_41d

.segment "KBDTABLES"

kbtab_41d:
	.incbin "asm/41D.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¤§¨´µ½ÄÅÖäåö€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤¨´½'
; Non-reachable ISO-8859-15:
;   ' ¡¢¥Šš©ª«¬­®¯°±²³Ž¶·ž¹º»ŒœŸ¿ÆÇÐ×ØÞßæçð÷øþ'

