.ifndef _VERA_INC_
  _VERA_INC_=1

verareg =$9f20
veralo  =verareg+0
veramid =verareg+1
verahi  =verareg+2
veradat =verareg+3
veradat2=verareg+4
veractl =verareg+5
veraien =verareg+6
veraisr =verareg+7

VERA_SPI  = $F7000

SDCARD_WRITE_PROTECT  = 1<<5
SDCARD_DETECT         = 1<<6

.endif
