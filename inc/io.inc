verareg =$9f20
veralo  =verareg+0
veramid =verareg+1
verahi  =verareg+2
veradat =verareg+3
veradat2=verareg+4
veractl =verareg+5
veraien =verareg+6
veraisr =verareg+7

via1	=$9f60                  ;VIA 6522 #1
d1prb	=via1+0
d1pra	=via1+1
d1ddrb	=via1+2
d1ddra	=via1+3
d1t1l	=via1+4
d1t1h	=via1+5
d1t1ll	=via1+6
d1t1lh	=via1+7
d1t2l	=via1+8
d1t2h	=via1+9
d1sr	=via1+10
d1acr	=via1+11
d1pcr	=via1+12
d1ifr	=via1+13
d1ier	=via1+14
d1ora	=via1+15

via2	=$9f70                  ;VIA 6522 #2
d2prb	=via2+0
d2pra	=via2+1
d2ddrb	=via2+2
d2ddra	=via2+3
d2t1l	=via2+4
d2t1h	=via2+5
d2t1ll	=via2+6
d2t1lh	=via2+7
d2t2l	=via2+8
d2t2h	=via2+9
d2sr	=via2+10
d2acr	=via2+11
d2pcr	=via2+12
d2ifr	=via2+13
d2ier	=via2+14
d2ora	=via2+15

;
; VERA Video RAM Layout
;
; $0:0000 - $0:3BFF  Text Mode
; $0:3C00 - $0:77FF  -- unused --
; $0:7800 - $0:F7FF  Sprites
;                    $0:7800  Sprite #0
;                    $0:8800  Sprite #1
;                    $0:9800  Sprite #2
;                    $0:A800  Sprite #3
;                    $0:B800  Sprite #4
;                    $0:C800  Sprite #5
;                    $0:D800  Sprite #6
;                    $0:E800  Sprite #7
; $0:F800 - $0:FFFF  Charset
; $1:0000 - $1:F9FF  320x200@256c Bitmap
; $1:FA00 - $1:FFFF  -- unused --

sprite_addr = $07800
tilbas      = $0f800
