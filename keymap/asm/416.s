; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Portuguese (Brazil ABNT)
; Locale: pt-BR
; KLID:   416

.segment "KBDMETA"

	.byte "PT-BR", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_416

.segment "KBDTABLES"

kbtab_416:
	.incbin "asm/416.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¢§¨ª¬°²³´¹ºÇç₢'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¨´₢'
; Non-reachable ISO-8859-15:
;   ' ¡€¥Šš©«­®¯±Žµ¶·ž»ŒœŸ¿ÅÆÐ×ØÞßåæð÷øþ'

