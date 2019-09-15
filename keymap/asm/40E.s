; Name:   Hungarian
; Locale: hu-HU
; KLID:   40e
;
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; graph: '\xa4\xa6\xa8\xa9\xba'
; Unicode characters reachable with this layout on Windows but not covered by PETSCII:
; '\x1b\x1c\x1d\_{|}~¤§¨°´¸ÁÄÉÍÓÖ×ÚÜßáäéíóö÷úüĐđŁłŐőŰűˇ˘˙˛˝€'

.segment "KBDMETA"

	.byte "HU", 0, 0, 0, 0
	.word kbtab_40e_1-13
	.word kbtab_40e_4-13
	.word kbtab_40e_2-13
	.word kbtab_40e_6-13
	.word kbtab_40e_0

.segment "KBDTABLES"

kbtab_40e_0: ; Unshifted
	.byte $00,$10,$88,$87,$86,$85,$89,$17
	.byte $00,$15,$8c,$8b,$8a,$09,'0',$00
	.byte $00,$00,$00,$00,$00,'Q','1',$00
	.byte $00,$00,'Y','S','A','W','2',$00
	.byte $00,'C','X','D','E','4','3',$00
	.byte $00,' ','V','F','T','R','5',$00
	.byte $00,'N','B','H','G','Z','6',$00
	.byte $00,$00,'M','J','U','7','8',$00
	.byte $00,',','K','I','O',$00,'9',$00
	.byte $00,'.','-','L',$00,'P',$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$0d,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$14,$00
	.byte $00,'1',$00,'4','7',$00,$00,$00
	.byte '0',',','2','5','6','8',$00,$00
	.byte $16,'+','3','-','*','9',$00,$00
kbtab_40e_1: ; Shft 
	.byte $18,'\',$00
	.byte $00,$00,$00,$00,$00,$d1,''',$00
	.byte $00,$00,$d9,$d3,$c1,$d7,'"',$00
	.byte $00,$c3,$d8,$c4,$c5,'!','+',$00
	.byte $00,$a0,$d6,$c6,$d4,$d2,'%',$00
	.byte $00,$ce,$c2,$c8,$c7,$da,'/',$00
	.byte $00,$00,$cd,$ca,$d5,'=','(',$00
	.byte $00,'?',$cb,$c9,$cf,$00,')',$00
	.byte $00,':',$00,$cc,$00,$d0,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$8d,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$94,$00
kbtab_40e_2: ; Ctrl 
	.byte $18,$00,$00
	.byte $00,$00,$00,$00,$00,$11,$90,$00
	.byte $00,$00,$19,$13,$01,$17,$05,$00
	.byte $00,$03,$18,$04,$05,$9f,$1c,$00
	.byte $00,$a0,$16,$06,$14,$12,$9c,$00
	.byte $00,$0e,$02,$08,$07,$1a,$1e,$00
	.byte $00,$00,$0d,$0a,$15,$1f,$9e,$00
	.byte $00,$00,$0b,$09,$0f,$92,$12,$00
	.byte $00,$00,$00,$0c,$00,$10,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$8d,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$94,$00
kbtab_40e_4: ; Alt 
	.byte $18,$00,$00
	.byte $00,$00,$00,$00,$00,$ab,$81,$00
	.byte $00,$00,$ad,$ae,$b0,$b3,$95,$00
	.byte $00,$bc,$bd,$ac,$b1,$97,$96,$00
	.byte $00,$a0,$be,$bb,$a3,$b2,$98,$00
	.byte $00,$aa,$bf,$b4,$a5,$b7,$99,$00
	.byte $00,$00,$a7,$b5,$b8,$9a,$9b,$00
	.byte $00,$00,$a1,$a2,$b9,$00,$00,$00
	.byte $00,$00,$00,$b6,$00,$af,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$8d,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$94,$00
kbtab_40e_6: ; AltGr 
	.byte $18,$00,$00
	.byte $00,$00,$00,$00,$00,'_',$00,$00
	.byte $00,$00,'>',$00,$00,$de,$00,$00
	.byte $00,'&','#',$00,$00,$00,'^',$00
	.byte $00,$a0,'@','[',$00,$00,$00,$00
	.byte $00,$00,$00,$00,']',$00,$00,$00
	.byte $00,$00,'<',$00,$00,'`',$00,$00
	.byte $00,';',$00,$00,$00,$00,$00,$00
	.byte $00,'>','*',$00,'$',$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$8d,$00,$00,$00,$00,$00
	.byte $00,'<',$00,$00,$00,$00,$94,$00
