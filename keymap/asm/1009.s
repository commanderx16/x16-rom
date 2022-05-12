; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Canadian French
; Locale: en-CA
; KLID:   1009

.segment "KBDMETA"

	.byte "EN-CA", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_1009

.segment "KBDTABLES"

kbtab_1009:
	.incbin "asm/1009.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¢¤¦§¨«¬­¯°±²³´µ¶¸»¼½¾Éé'

; ISO
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '^π'
; graph: '\xa1\xa4\xa5\xa6\xa8\xa9\xaa\xae\xb4\xb7\xb8\xb9\xba\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '^`¤¦¨´¸¼½¾'

