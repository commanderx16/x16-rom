; Name:   Hungarian
; Locale: hu-HU
; KLID:   40e
;
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; codes: LIGHT_RED LIGHT_BLUE 
; graph: '\xa4\xa5\xa6\xa7\xa8\xa9\xab\xad\xb3\xba\xbb\xbc\xbd\xbe\xc0\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe'
; ASCII characters reachable with this layout on Windows but not covered by PETSCII:
; '\x1b\x1c\x1d\_{|}~¤§¨°´¸ÁÄÉÍÓÖ×ÚÜßáäéíóö÷úüĐđŁłŐőŰűˇ˘˙˛˝€'

.segment "KBDMETA"

	.byte "HU", 0, 0, 0, 0, 0, 0
	.word kbtab_40e_1-13
	.word kbtab_40e_4-13
	.word kbtab_40e_2-13
	.word kbtab_40e_0

.segment "KBDTABLES"

kbtab_40e_0: ; Unshifted
	.byte $00,$00,$88,$87,$86,$85,$89,$00
	.byte $00,$00,$8c,$8b,$8a,$09,'0',$00
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
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,',',$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
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
	.byte $00,$00,$00,$00,$00,'_',$81,$00
	.byte $00,$00,'>',$ae,$b0,$de,$95,$00
	.byte $00,'&','#',$ac,$b1,$97,'^',$00
	.byte $00,$a0,'@','[',$a3,$b2,$98,$00
	.byte $00,$aa,$bf,$b4,']',$b7,$99,$00
	.byte $00,$00,'<',$b5,$b8,'`',$9b,$00
	.byte $00,';',$a1,$a2,$b9,$00,$00,$00
	.byte $00,'>','*',$b6,'$',$af,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$8d,$00,$00,$00,$00,$00
	.byte $00,'<',$00,$00,$00,$00,$94,$00
