; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Japanese
; Locale: ja-JP
; KLID:   411

.segment "KBDMETA"

	.byte "JA-JP", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_411

.segment "KBDTABLES"

kbtab_411:
	.incbin "asm/411.bin.lzsa"

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

