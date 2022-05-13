; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Belgian French
; Locale: fr-BE
; KLID:   80c

.segment "KBDMETA"

	.byte "FR-BE", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_80c

.segment "KBDTABLES"

kbtab_80c:
	.incbin "asm/80C.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~§¨°²³´µàçèéù€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¨´'
; Non-reachable ISO-8859-15:
;   ' ¡¢¥Šš©ª«¬­®¯±Ž¶·ž¹º»ŒœŸ¿ÅÆÇÐ×ØÞßåæð÷øþ'

