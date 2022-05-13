; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   United States-Extended
; Locale: en-US
; KLID:   us_ext

.segment "KBDMETA"

	.byte "EN-US", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_us_ext

.segment "KBDTABLES"

kbtab_us_ext:
	.incbin "asm/99409.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   --none--
; Keys outside of PETSCII:
;   '\_{|}~¡¢¥§¨©ª«¬®¯°±´µ¶·¸º»¿ÆÐØÞßæð÷øþŒœƒʔʼˀˆˇˍ˘˙˚˜˝̵̧̨̛̣̦̰̱̀́̂̃̄̆̇̉̊̋̌̏̑–—‘’‚“”„†‡•…‰‸‹›⁄€№™≠≤≥'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¨´¸ƒʔʼˀˆˇˍ˘˙˚˜˝̵̧̨̛̣̦̰̱̀́̂̃̄̆̇̉̊̋̌̏̑–—‘’‚“”„†‡•…‰‸‹›⁄№™≠≤≥'
; Non-reachable ISO-8859-15:
;   '­²³¹'

