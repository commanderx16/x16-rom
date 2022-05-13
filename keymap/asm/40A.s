; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Spanish
; Locale: es-ES
; KLID:   40a

.segment "KBDMETA"

	.byte "ES-ES", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_40a

.segment "KBDTABLES"

kbtab_40a:
	.incbin "asm/40A.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¡¨ª¬´·º¿ÇÑçñ€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¨´'
; Non-reachable ISO-8859-15:
;   ' ¢£¥Š§š©«­®¯°±²³Žµ¶ž¹»ŒœŸÅÆÐ×ØÞßåæð÷øþ'

