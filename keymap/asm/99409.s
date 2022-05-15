; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   ABC - Extended (X16)
; Locale: en-US
; KLID:   us_ext

.segment "KBDMETA"

	.byte "ABC/X16", 0, 0, 0, 0, 0, 0, 0
	.word kbtab_us_ext

.segment "KBDTABLES"

kbtab_us_ext:
	.incbin "asm/99409.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   --none--
; Keys outside of PETSCII:
;   '\_{|}~¡¢¥§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¿ÆÐØÞßæð÷øþŒœƒʔʼˀˆˇˍ˘˙˚˜˝̵̨̛̣̦̰̱̀́̂̃̇̉̋̌̏̑–‘’‚“”„†‡•…‰‸‹›⁄€№™≠≤≥'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¨´¸ƒʔʼˀˆˇˍ˘˙˚˜˝̵̨̛̣̦̰̱̀́̂̃̇̉̋̌̏̑–‘’‚“”„†‡•…‰‸‹›⁄№™≠≤≥'
; Non-reachable ISO-8859-15:
;   --none--

