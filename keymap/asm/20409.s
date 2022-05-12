; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   United States-International
; Locale: en-US
; KLID:   20409

.segment "KBDMETA"

	.byte "EN-US/INT", 0, 0, 0, 0, 0
	.word kbtab_20409

.segment "KBDTABLES"

kbtab_20409:
	.incbin "asm/20409.bin.lzsa"

; PETSCII
; ~~~~~~~
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
;   --none--
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
;   '\_{|}~¡¢¤¥¦§¨©«¬®°²³´µ¶¹»¼½¾¿ÁÄÅÆÇÉÍÐÑÓÖ×ØÚÜÞßáäåæçéíðñóö÷øúüþ‘’€'

; ISO
; ~~~
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
;   '¤¦¨´¼½¾‘’'
; ISO-8859-15 characters not reachable by this layout:
;   --none--

