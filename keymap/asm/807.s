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
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¢¦§¨¬°´àäçèéöü€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¦¨´'
; ISO-8859-15 characters not reachable by this layout:
; 'ÅÆÇÐ×ØÞßåæð÷øþ'

