; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   United States-Extended
; Locale: en-US
; KLID:   us_ext

.segment "KBDMETA"

	.byte "EN-US/MAC", 0, 0, 0, 0, 0
	.word kbtab_us_ext

.segment "KBDTABLES"

kbtab_us_ext:
	.incbin "asm/99409.bin.lzsa"

; PETSCII
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\x1d\_`{|}~¡¢¥§¨©ª«®¯°±´¶·¸º»¿ÆÐØÞßæð÷øþŒœƒʔʼˀˆˇˍ˘˙˚˛˜˝̵̧̨̛̣̦̰̱̀́̂̃̄̆̇̉̊̋̌̏̑–—‘’‚“”„†‡•…‰‸‹›⁄€№™≠≤≥'

; ISO
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa4\xa6\xa8\xac\xad\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb7\xb8\xb9\xbb\xbc\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¨¯°±´·¸»¿ÆÐØÞŒƒʔʼˀˆˇˍ˘˙˚˛˜˝̵̧̨̛̣̦̰̱̀́̂̃̄̆̇̉̊̋̌̏̑–—‘’‚“”„†‡•…‰‸‹›⁄€№™≠≤≥'

