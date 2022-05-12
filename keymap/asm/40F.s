; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Icelandic
; Locale: is-IS
; KLID:   40f

.segment "KBDMETA"

	.byte "IS-IS", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_40f

.segment "KBDTABLES"

kbtab_40f:
	.incbin "asm/40F.bin.lzsa"

; PETSCII
; ~~~~~~~
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
;   chars: '£π←'
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
;   '\_{|}~¨°´µÆÐÖÞæðöþ€'

; ISO
; ~~~
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
;   '¨´'
; ISO-8859-15 characters not reachable by this layout:
;   'ÃÇÑÕ×Øßãçñõ÷ø'

