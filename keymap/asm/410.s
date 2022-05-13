; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Italian
; Locale: it-IT
; KLID:   410

.segment "KBDMETA"

	.byte "IT-IT", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_410

.segment "KBDTABLES"

kbtab_410:
	.incbin "asm/410.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}§°àçèéìòù€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   --none--
; Non-reachable ISO-8859-15:
;   '`~ ¡¢¥Šš©ª«¬­®¯±²³Žµ¶·ž¹º»ŒœŸ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßáâãäåæêëíîïðñóôõö÷øúûüýþ'

