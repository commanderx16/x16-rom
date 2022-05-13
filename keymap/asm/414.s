; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Norwegian
; Locale: nb-NO
; KLID:   414

.segment "KBDMETA"

	.byte "NB-NO", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_414

.segment "KBDTABLES"

kbtab_414:
	.incbin "asm/414.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¤§¨´µÅÆØåæø€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤¨´'
; Non-reachable ISO-8859-15:
;   ' ¡¢¥Šš©ª«¬­®¯°±²³Ž¶·ž¹º»ŒœŸ¿ÇÐ×Þßçð÷þ'

