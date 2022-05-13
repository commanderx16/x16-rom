; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Icelandic
; Locale: is-IS
; KLID:   40f

.segment "KBDMETA"

	.byte "IS-IS", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_40f

.segment "KBDTABLES"

kbtab_40f:
	.incbin "asm/40F.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   chars: '£π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¨°´µÆÐÖÞæðöþ€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¨´'
; Non-reachable ISO-8859-15:
;   ' ¡¢£¥Š§š©ª«¬­®¯±²³Ž¶·ž¹º»ŒœŸ¿ÃÇÑÕ×Øßãçñõ÷ø'

