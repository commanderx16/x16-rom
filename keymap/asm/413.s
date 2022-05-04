; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Dutch
; Locale: nl-NL
; KLID:   413

.segment "KBDMETA"

	.byte "NL-NL", 0
	.word kbtab_413

.segment "KBDTABLES"

kbtab_413:
	.incbin "asm/413.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¢¦§¨«¬°±²³´µ¶·¸¹»¼½¾ß€'

; ISO
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '^π'
; graph: '\xa1\xa5\xa6\xa8\xa9\xaa\xad\xae\xaf\xb4\xb8\xba\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '^`~¦¨´¸¼½¾'

