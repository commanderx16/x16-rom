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
; '\_{|}~¡¢¥§¨©ª«®¯°±´¶·¸º»¿ÆÐØÞßæð÷øþŒœƒʔʼˀˆˇˍ˘˙˚˛˜˝̵̧̨̛̣̦̰̱̀́̂̃̄̆̇̉̊̋̌̏̑–—‘’‚“”„†‡•…‰‸‹›⁄€№™≠≤≥'

; ISO
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¨´¸ƒʔʼˀˆˇˍ˘˙˚˛˜˝̵̧̨̛̣̦̰̱̀́̂̃̄̆̇̉̊̋̌̏̑–—‘’‚“”„†‡•…‰‸‹›⁄№™≠≤≥'

