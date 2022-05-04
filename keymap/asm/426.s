; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Latvian
; Locale: lv-LV
; KLID:   426

.segment "KBDMETA"

	.byte "LV-LV", 0
	.word kbtab_426

.segment "KBDTABLES"

kbtab_426:
	.incbin "asm/426.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: "#'@^£π←"
; codes: CURSOR_DOWN 
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '#@QWXY\^_{|}~¨«­°±´»Õ×õĀāČčĒēĢģĪīĶķĻļŅņŖŗŠšŪūŽž–—’€'

; ISO
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: "#'@QQWWXXYY^π"
; codes: CURSOR_DOWN 
; graph: '\xa1\xa2\xa3\xa5\xa7\xa9\xaa\xac\xae\xaf\xb0\xb1\xb2\xb3\xb5\xb6\xb7\xb9\xba\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '#@QWXY^{|}~¨°±´ÕĀāČčĒēĢģĪīĶķĻļŅņŖŗŪū–—’'

