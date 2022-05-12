; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Slovenian
; Locale: sl-SI
; KLID:   424

.segment "KBDMETA"

	.byte "SL-SI", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_424

.segment "KBDTABLES"

kbtab_424:
	.incbin "asm/424.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '£π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~¤§¨°´¸×ß÷ĆćČčĐđŁłŠšŽžˇ˘˙˛˝€'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '^¤¨°´¸ĆćČčĐđŁłˇ˘˙˛˝'
; ISO-8859-15 characters not reachable by this layout:
; 'ÀÃÅÆÈÊÌÏÐÑÒÕØÙÛÞàãåæèêìïðñòõøùûþ'

