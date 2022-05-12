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
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
;   chars: "#'@^£π←"
;   codes: CURSOR_DOWN 
;   graph: '\xa4\xa6\xa8\xa9\xba' <--- *** THIS IS BAD! ***
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
;   '\_{|}~¨«­°±´»Õ×õĀāČčĒēĢģĪīĶķĻļŅņŖŗŠšŪūŽž–—’€'

; ISO
; ~~~
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
;   '¨´ĀāČčĒēĢģĪīĶķĻļŅņŖŗŪū–—’'
; ISO-8859-15 characters not reachable by this layout:
;   ''*+`ÀÁÂÃÆÇÈÊËÌÍÎÏÐÑÒÔØÙÚÛÝÞßàáâãæçèêëìíîïðñòô÷øùúûýþ'

