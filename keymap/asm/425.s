; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Estonian
; Locale: et-EE
; KLID:   425

.segment "KBDMETA"

	.byte "ET-EE", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_425

.segment "KBDTABLES"

kbtab_425:
	.incbin "asm/425.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   chars: 'π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¤§´½ÄÕÖÜäõöüŠšŽžˇ€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¤´½ˇ'
; Non-reachable ISO-8859-15:
;   ' ¡¢¥©ª«¬­®¯°±²³µ¶·¹º»ŒœŸ¿ÁÃÅÆÇËÌÍÏÐÑÔ×ØÚÝÞßáãåæçëìíïðñô÷øúýþ'

