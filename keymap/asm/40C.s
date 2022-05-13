; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   French
; Locale: fr-FR
; KLID:   40c

.segment "KBDMETA"

	.byte "FR-FR", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_40c

.segment "KBDTABLES"

kbtab_40c:
	.incbin "asm/40C.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¤§¨°²µàçèéù€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤¨'
; Non-reachable ISO-8859-15:
;   ' ¡¢¥Šš©ª«¬­®¯±³Ž¶·ž¹º»ŒœŸ¿ÁÅÆÇÉÍÐÓ×ØÚÝÞßáåæíðó÷øúýþ'

