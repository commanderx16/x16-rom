; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   German
; Locale: de-DE
; KLID:   407

.segment "KBDMETA"

	.byte "DE", 0, 0, 0, 0
	.word kbtab_407

.segment "KBDTABLES"

kbtab_407:
	.incbin "asm/407.bin.lzsa"

; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_`{|}~§°²³´µÄÖÜßäöüẞ€'

; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa1\xa2\xa3\xa5\xa6\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb1\xb4\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '´ẞ'

