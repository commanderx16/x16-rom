; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Lithuanian IBM
; Locale: lt-LT
; KLID:   427

.segment "KBDMETA"

	.byte "LT-LT", 0
	.word kbtab_427

.segment "KBDTABLES"

kbtab_427:
	.incbin "asm/427.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: "#$%&'<>@QQWWXX^£π←"
; codes: CURSOR_DOWN 
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~ĄąČčĖėĘęĮįŠšŪūŲųŽž“”€'

; ISO
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: "#$%&'<>@QQWWXX^π"
; codes: CURSOR_DOWN 
; graph: '\xa1\xa2\xa3\xa5\xa7\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb5\xb6\xb7\xb9\xba\xbb\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; 'ĄąČčĖėĘęĮįŪūŲų“”'

