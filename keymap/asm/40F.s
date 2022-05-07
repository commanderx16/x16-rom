; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Icelandic
; Locale: is-IS
; KLID:   40f

.segment "KBDMETA"

	.byte "IS-IS", 0
	.word kbtab_40f

.segment "KBDTABLES"

kbtab_40f:
	.incbin "asm/40F.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '£π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¨°´µÆÐÖÞæðöþ€'

; ISO
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '^'
; graph: '\xa1\xa2\xa3\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb1\xb2\xb3\xb4\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '^`¨´'

