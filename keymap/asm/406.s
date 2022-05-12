; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Danish
; Locale: da-DK
; KLID:   406

.segment "KBDMETA"

	.byte "DA-DK", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_406

.segment "KBDTABLES"

kbtab_406:
	.incbin "asm/406.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¤§¨´µ½ÅÆØåæø€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '^`~¤¨´½'
; ISO-8859-15 characters not reachable by this layout:
; 'ÇÐ×Þßçð÷þ'

