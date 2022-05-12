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
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}§°àçèéìòù€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '{}'
; ISO-8859-15 characters not reachable by this layout:
; '`~ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßáâãäåæêëíîïðñóôõö÷øúûüýþ'

