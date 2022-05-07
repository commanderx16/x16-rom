; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Croatian
; Locale: hr-HR
; KLID:   41a

.segment "KBDMETA"

	.byte "HR-HR", 0
	.word kbtab_41a

.segment "KBDTABLES"

kbtab_41a:
	.incbin "asm/41A.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '£π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¤§¨°´¸×ß÷ĆćČčĐđŁłŠšŽžˇ˘˙˛˝€'

; ISO
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '^π'
; graph: '\xa1\xa2\xa3\xa5\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb5\xb6\xb7\xb9\xba\xbb\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '^¤¨°´¸ĆćČčĐđŁłˇ˘˙˛˝'

