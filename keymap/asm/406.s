; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Danish
; Locale: da-DK
; KLID:   406

.segment "KBDMETA"

	.byte "DA-DK", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_406

.segment "KBDTABLES"

kbtab_406:
	.incbin "asm/406.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¤§¨´µ½ÅÆØåæø€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤¨´½'
; Non-reachable ISO-8859-15:
;   ' ¡¢¥Šš©ª«¬­®¯°±²³Ž¶·ž¹º»ŒœŸ¿ÇÐ×Þßçð÷þ'

