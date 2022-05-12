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
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¤§¨°²µàçèéù€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¤¨'
; ISO-8859-15 characters not reachable by this layout:
; 'ÁÅÆÇÉÍÐÓ×ØÚÝÞßáåæíðó÷øúýþ'

