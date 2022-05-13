; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   United States-Dvorak
; Locale: en-US
; KLID:   10409

.segment "KBDMETA"

	.byte "EN-US/DVO", 0, 0, 0, 0, 0
	.word kbtab_10409

.segment "KBDTABLES"

kbtab_10409:
	.incbin "asm/10409.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   chars: '£π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   --none--
; Non-reachable ISO-8859-15:
;   ' ¡¢£€¥Š§š©ª«¬­®¯°±²³Žµ¶·ž¹º»ŒœŸ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþ'

