; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Portuguese
; Locale: pt-PT
; KLID:   816

.segment "KBDMETA"

	.byte "PT-PT", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_816

.segment "KBDTABLES"

kbtab_816:
	.incbin "asm/816.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   chars: 'π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~§¨ª«´º»Çç€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¨´'
; Non-reachable ISO-8859-15:
;   ' ¡¢¥Šš©¬­®¯°±²³Žµ¶·ž¹ŒœŸ¿ÅÆÐ×ØÞßåæð÷øþ'

