; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Colemak
; KLID:   colemak

.segment "KBDMETA"

	.byte "EN!US", 0
	.word kbtab_colemak

.segment "KBDTABLES"

kbtab_colemak:
	.incbin "asm/Colemak.bin.lzsa"

; PETSCII
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: '£π←'
; graph: '\xa4\xa6\xa8\xa9\xba'
; *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\_{|}~ ¡¢£¥¨ª«¯²³´¸¹º»¿ÁÃÄÅÆÇÉÍÐÑÓÕÖ×ØÚÜÞßáãäåæçéíðñóõö÷øúüþĐđĦħŁłŒœˇ˘˙˚˛˝–—‘’“”‹›€'

; ISO
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa3\xa5\xa6\xa7\xa8\xa9\xac\xad\xae\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xbc\xbe'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '£¥¨²³´¸¹ÁÃÄÅÆÇÉÍÐÑÓÕÖØÚÜÞ÷ĐđĦħŁłŒˇ˘˙˚˛˝–—‘’“”‹›'

