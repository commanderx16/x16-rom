; Commander X16 PETSCII/ISO Keyboard Table
; ***this file is auto-generated!***
;
; Name:   Latvian
; Locale: lv-LV
; KLID:   426

.segment "KBDMETA"

	.byte "LV-LV", 0, 0, 0, 0, 0, 0, 0, 0, 0
	.word kbtab_426

.segment "KBDTABLES"

kbtab_426:
	.incbin "asm/426.bin.lzsa"

; PETSCII
; ~~~~~~~
; C64 keyboard regressions:
;   chars: "#'@^£π←"
;   codes: CURSOR_DOWN 
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Keys outside of PETSCII:
;   '\_{|}~¨«­°±´»Õ×õĀāČčĒēĢģĪīĶķĻļŅņŖŗŠšŪūŽž–—’€'

; ISO
; ~~~
; Keys outside of ISO-8859-15:
;   '¨´ĀāČčĒēĢģĪīĶķĻļŅņŖŗŪū–—’'
; Non-reachable ISO-8859-15:
;   ''*+` ¡¢£¥§©ª¬®¯²³µ¶·¹ºŒœŸ¿ÀÁÂÃÆÇÈÊËÌÍÎÏÐÑÒÔØÙÚÛÝÞßàáâãæçèêëìíîïðñòô÷øùúûýþ'

