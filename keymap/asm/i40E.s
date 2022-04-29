; Name:   Hungarian
; Locale: hu-HU
; KLID:   40e
;
; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:
; chars: 'π'
; graph: '\xa1\xa2\xa3\xa5\xa6\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf'
; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:
; '¤¨´¸ĐđŁłŐőŰűˇ˘˙˛˝'

.segment "IKBDMETA"

	.byte "HU", 0, 0, 0, 0
	.word ikbtab_40e_1-13
	.word ikbtab_40e_4-13
	.word ikbtab_40e_2-13
	.word ikbtab_40e_6-13
	.word ikbtab_40e_0

.segment "IKBDTABLES"

ikbtab_40e_0: ; Unshifted
	.byte $00,$10,$88,$87,$86,$85,$89,$17
	.byte $00,$15,$8c,$8b,$8a,$09,'0',$00
	.byte $00,$00,$00,$00,$00,'q','1',$00
	.byte $00,$00,'y','s','a','w','2',$00
	.byte $00,'c','x','d','e','4','3',$00
	.byte $00,' ','v','f','t','r','5',$00
	.byte $00,'n','b','h','g','z','6',$00
	.byte $00,$00,'m','j','u','7','8',$00
	.byte $00,',','k','i','o',$f6,'9',$00
	.byte $00,'.','-','l',$e9,'p',$fc,$00
	.byte $00,$00,$e1,$00,$00,$f3,$00,$00
	.byte $00,$00,$0d,$fa,$00,$00,$00,$00
	.byte $00,$ed,$00,$00,$00,$00,$14,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,',',$00,$00,$00,$00,$1b,$00
	.byte $16,$00,$00,$00,$00,$00,$00,$00
ikbtab_40e_1: ; Shft 
	.byte $18,$a7,$00
	.byte $00,$00,$00,$00,$00,'Q',''',$00
	.byte $00,$00,'Y','S','A','W','"',$00
	.byte $00,'C','X','D','E','!','+',$00
	.byte $00,$a0,'V','F','T','R','%',$00
	.byte $00,'N','B','H','G','Z','/',$00
	.byte $00,$00,'M','J','U','=','(',$00
	.byte $00,'?','K','I','O',$d6,')',$00
	.byte $00,':','_','L',$c9,'P',$dc,$00
	.byte $00,$00,$c1,$00,$00,$d3,$00,$00
	.byte $00,$00,$8d,$da,$00,$00,$00,$00
	.byte $00,$cd,$00,$00,$00,$00,$94,$00
ikbtab_40e_2: ; Ctrl 
	.byte $18,$00,$00
	.byte $00,$00,$00,$00,$00,$11,$90,$00
	.byte $00,$00,$19,$13,$01,$17,$05,$00
	.byte $00,$03,$18,$04,$05,$9f,$1c,$00
	.byte $00,$a0,$16,$06,$14,$12,$9c,$00
	.byte $00,$0e,$02,$08,$07,$1a,$1e,$00
	.byte $00,$00,$0d,$0a,$15,$1f,$9e,$00
	.byte $00,$00,$0b,$09,$0f,$92,$12,$00
	.byte $00,$00,$00,$0c,$00,$10,$00,$00
	.byte $00,$00,$00,$00,$1b,$00,$00,$00
	.byte $00,$00,$8d,$1d,$00,$1c,$00,$00
	.byte $00,$1c,$00,$00,$00,$00,$94,$00
ikbtab_40e_4: ; Alt 
	.byte $18,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$81,$00
	.byte $00,$00,$00,$00,$00,$00,$95,$00
	.byte $00,$00,$00,$00,$00,$97,$96,$00
	.byte $00,$a0,$00,$00,$00,$00,$98,$00
	.byte $00,$00,$00,$00,$00,$00,$99,$00
	.byte $00,$00,$00,$00,$00,$9a,$9b,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$8d,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$94,$00
ikbtab_40e_6: ; AltGr 
	.byte $18,$00,$00
	.byte $00,$00,$00,$00,$00,'\','~',$00
	.byte $00,$00,'>',$00,$e4,'|',$00,$00
	.byte $00,'&','#',$00,$c4,$00,'^',$00
	.byte $00,$a0,'@','[',$00,$00,$b0,$00
	.byte $00,'}','{',$00,']',$00,$00,$00
	.byte $00,$00,'<',$ed,$a4,'`',$00,$00
	.byte $00,';',$00,$cd,$00,$00,$00,$00
	.byte $00,'>','*',$00,'$',$00,$00,$00
	.byte $00,$00,$df,$00,$f7,$00,$00,$00
	.byte $00,$00,$8d,$d7,$00,$00,$00,$00
	.byte $00,'<',$00,$00,$00,$00,$94,$00
