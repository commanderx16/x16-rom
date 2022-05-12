; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Norwegian
; Locale: nb-NO
; KLID:   414

.segment "KBDMETA"

	.byte "NB-NO", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_414

.segment "KBDTABLES"

kbtab_414:
	.incbin "asm/414.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¤§¨´µÅÆØåæø€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '^`~¤¨´'
; ISO-8859-15 characters not reachable by this layout:
; 'ÇÐ×Þßçð÷þ'

