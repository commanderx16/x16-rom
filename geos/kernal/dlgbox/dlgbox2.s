; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Dialog box: OK, CANCEL icons

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "c64.inc"

.global DBIcPicCANCEL
.global DBIcPicOK

.segment "dlgbox2"

DBIcPicCANCEL:
	.byte 5, %11111111, $80+2, %11111110
	.byte %10000000, 4, %00000000, $80+2, %00000011
	.byte %10000000, 4, %00000000, $80+(9*6)+2, %00000011
	     ;%11111111, %11111111, %11111111, %11111111, %11111111, %11111110
	     ;%10000000, %00000000, %00000000, %00000000, %00000000, %00000011
	     ;%10000000, %00000000, %00000000, %00000000, %00000000, %00000011
	.byte %10000111, %11000000, %00000000, %00000000, %00000000, %11100011 ;1
	.byte %10001100, %01100000, %00000000, %00000000, %00000000, %01100011 ;2
	.byte %10001100, %00000111, %10011111, %00011110, %00111100, %01100011 ;3
	.byte %10001100, %00001100, %11011101, %10110011, %01100110, %01100011 ;4
	.byte %10001100, %00000111, %11011001, %10110000, %01100110, %01100011 ;5
	.byte %10001100, %00001100, %11011001, %10110000, %01111110, %01100011 ;6
	.byte %10001100, %00001100, %11011001, %10110000, %01100000, %01100011 ;7
	.byte %10001100, %01101100, %11011001, %10110011, %01100110, %01100011 ;8
	.byte %10000111, %11000111, %11011001, %10011110, %00111100, %01100011 ;9
	     ;%10000000, %00000000, %00000000, %00000000, %00000000, %00000011
	     ;%10000000, %00000000, %00000000, %00000000, %00000000, %00000011
	     ;%11111111, %11111111, %11111111, %11111111, %11111111, %11111111
	     ;%01111111, %11111111, %11111111, %11111111, %11111111, %11111111
	.byte %10000000, 4, %00000000, $80+2, %00000011
	.byte %10000000, 4, %00000000, $80+1, %00000011
	.byte 6, %11111111, $80+1, %01111111
.ifndef bsw128 ; save 2 bytes
	.byte 5, %11111111
.endif

DBIcPicOK:
	.byte 5, %11111111, $80+2, %11111110
	.byte %10000000, 4, %00000000, $80+2, %00000011
	.byte %10000000, 4, %00000000, $80+(9*6)+2, %00000011
	     ;%11111111, %11111111, %11111111, %11111111, %11111111, %11111110
	     ;%10000000, %00000000, %00000000, %00000000, %00000000, %00000011
	     ;%10000000, %00000000, %00000000, %00000000, %00000000, %00000011
	.byte %10000000, %00000000, %11111000, %11000110, %00000000, %00000011 ;1
	.byte %10000000, %00000001, %10001100, %11001100, %00000000, %00000011 ;2
	.byte %10000000, %00000001, %10001100, %11011000, %00000000, %00000011 ;3
	.byte %10000000, %00000001, %10001100, %11110000, %00000000, %00000011 ;4
	.byte %10000000, %00000001, %10001100, %11100000, %00000000, %00000011 ;5
	.byte %10000000, %00000001, %10001100, %11110000, %00000000, %00000011 ;6
	.byte %10000000, %00000001, %10001100, %11011000, %00000000, %00000011 ;7
	.byte %10000000, %00000001, %10001100, %11001100, %00000000, %00000011 ;8
	.byte %10000000, %00000000, %11111000, %11000110, %00000000, %00000011 ;9
	     ;%10000000, %00000000, %00000000, %00000000, %00000000, %00000011
	     ;%10000000, %00000000, %00000000, %00000000, %00000000, %00000011
	     ;%11111111, %11111111, %11111111, %11111111, %11111111, %11111111
	     ;%01111111, %11111111, %11111111, %11111111, %11111111, %11111111
	.byte %10000000, 4, %00000000, $80+2, %00000011
	.byte %10000000, 4, %00000000, $80+1, %00000011
	.byte 6, %11111111, $80+1, %01111111, 5, %11111111
