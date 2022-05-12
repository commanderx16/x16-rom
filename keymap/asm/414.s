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
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '^π'
; graph: '\xa1\xa2\xa5\xa6\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '^`~¤¨´'
; ISO-8859-15 characters not reachable by this layout:
; 'ÇÐ×Þßçð÷þ'

