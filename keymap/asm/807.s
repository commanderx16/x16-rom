; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Swiss German
; Locale: de-CH
; KLID:   807

.segment "KBDMETA"

	.byte "DE-CH", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_807

.segment "KBDTABLES"

kbtab_807:
	.incbin "asm/807.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¢¦§¨¬°´àäçèéöü€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¦¨´'
; Non-reachable ISO-8859-15:
;   ' ¡¥Šš©ª«­®¯±²³Žµ¶·ž¹º»ŒœŸ¿ÅÆÇÐ×ØÞßåæð÷øþ'

