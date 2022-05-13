; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   German
; Locale: de-DE
; KLID:   407

.segment "KBDMETA"

	.byte "DE-DE", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_407

.segment "KBDTABLES"

kbtab_407:
	.incbin "asm/407.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   --none--
; Keys outside of PETSCII:
;   '\_{|}~§°²³´µÄÖÜßäöüẞ€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '´ẞ'
; Non-reachable ISO-8859-15:
;   ' ¡¢£¥Šš©ª«¬­®¯±Ž¶·ž¹º»ŒœŸ¿ÃÅÆÇËÏÐÑÕ×ØÞãåæçëïðñõ÷øþ'

