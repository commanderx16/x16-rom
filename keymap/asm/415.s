; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Polish (Programmers)
; Locale: pl-PL
; KLID:   415

.segment "KBDMETA"

	.byte "PL-PL", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_415

.segment "KBDTABLES"

kbtab_415:
	.incbin "asm/415.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~ÓóĄąĆćĘęŁłŃńŚśŹźŻż€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   'ĄąĆćĘęŁłŃńŚśŹźŻż'
; Non-reachable ISO-8859-15:
;   ' ¡¢£¥Š§š©ª«¬­®¯°±²³Žµ¶·ž¹º»ŒœŸ¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòôõö÷øùúûüýþ'

