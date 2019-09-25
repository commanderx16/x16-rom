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

.segment "KERNSUPV"

	.byte $ff       ;

	.byte 0, 0, 0   ;cint
	.byte 0, 0, 0   ;ioinit
	.byte 0, 0, 0   ;ramtas

	.byte 0, 0, 0   ;restor
	.byte 0, 0, 0   ;vector

	bridge setmsg
	.byte 0, 0, 0   ;secnd
	.byte 0, 0, 0   ;tksa
	bridge memtop
	bridge membot
	.byte 0, 0, 0   ;scnkey
	.byte 0, 0, 0   ;settmo
	.byte 0, 0, 0   ;acptr
	.byte 0, 0, 0   ;ciout
	.byte 0, 0, 0   ;untlk
	.byte 0, 0, 0   ;unlsn
	.byte 0, 0, 0   ;listn
	.byte 0, 0, 0   ;talk
	.byte 0, 0, 0   ;readst
	.byte 0, 0, 0   ;setlfs
	.byte 0, 0, 0   ;setnam
	.byte 0, 0, 0   ;open
	.byte 0, 0, 0   ;close
	.byte 0, 0, 0   ;chkin
	.byte 0, 0, 0   ;ckout
	bridge clrch
	bridge basin
	bridge bsout
	.byte 0, 0, 0   ;loadsp
	.byte 0, 0, 0   ;savesp
	.byte 0, 0, 0   ;settim
	.byte 0, 0, 0   ;rdtim
	.byte 0, 0, 0   ;stop
	.byte 0, 0, 0   ;getin
	bridge clall
	.byte 0, 0, 0   ;udtim
	.byte 0, 0, 0   ;scrorg
	.byte 0, 0, 0   ;plot
	.byte 0, 0, 0   ;iobase

	;signature
	.byte "MIST"

	.word $ffff ; nmi
	.word $ffff ; reset
	.word banked_irq

