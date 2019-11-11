.include "config.inc"

; X16
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
