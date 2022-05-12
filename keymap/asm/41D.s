; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Swedish
; Locale: sv-SE
; KLID:   41d

.segment "KBDMETA"

	.byte "SV-SE", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_41d

.segment "KBDTABLES"

kbtab_41d:
	.incbin "asm/41D.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¤§¨´µ½ÄÅÖäåö€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¤¨´½'
; ISO-8859-15 characters not reachable by this layout:
; 'ÆÇÐ×ØÞßæçð÷øþ'

