.import jsrfar, banked_irq

.macro bridge symbol
	.local address
	.segment "KERNSUPV"
address = *
	.segment "KERNSUP"
symbol:
	jsr jsrfar
	.word address
	.byte 7
	rts
	.segment "KERNSUPV"
	jmp symbol
.endmacro

.segment "KERNSUP"
monitor:
	jsr jsrfar
	.word $ff00
	.byte 7
	rts

.segment "KERNSUPV"

	.byte $ff       ;

	bridge cint
	bridge ioinit
	bridge ramtas

	bridge restor
	bridge vector

	bridge setmsg
	bridge secnd
	bridge tksa
	bridge memtop
	bridge membot
	bridge scnkey
	bridge settmo
	bridge acptr
	bridge ciout
	bridge untlk
	bridge unlsn
	bridge listn
	bridge talk
	bridge readst
	bridge setlfs
	bridge setnam
	bridge open
	bridge close
	bridge chkin
	bridge ckout
	bridge clrch
	bridge basin
	bridge bsout
	bridge loadsp
	bridge savesp
	bridge settim
	bridge rdtim
	bridge stop
	bridge getin
	bridge clall
	bridge udtim
	bridge scrorg
	bridge plot
	bridge iobase

	;private
	jmp monitor
	.byte 0

	.word $ffff ; nmi
	.word $ffff ; reset
	.word banked_irq

