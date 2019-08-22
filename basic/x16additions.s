.ifdef C64
verareg =$df00
.else
verareg =$9f20
.endif
verahi  =verareg+0
veramid =verareg+1
veralo  =verareg+2
veradat =verareg+3
veradat2=verareg+4
veractl =verareg+5
veraien =verareg+6
veraisr =verareg+7

cint   = $ff81
ioinit = $ff84
ramtas = $ff87
;restor = $ff8a
vector = $ff8d
;setmsg = $ff90
second = $ff93
tksa   = $ff96
memtop = $ff99
membot = $ff9c
scnkey = $ff9f
settmo = $ffa2
iecin  = $ffa5
iecout = $ffa8
untalk = $ffab
unlstn = $ffae
listen = $ffb1
talk   = $ffb4
;readst = $ffb7
setlfs = $ffba
setnam = $ffbd
open   = $ffc0
close  = $ffc3
chkin  = $ffc6
ckout  = $ffc9
clrch  = $ffcc
basin  = $ffcf
bsout  = $ffd2
load   = $ffd5
save   = $ffd8
;settim = $ffdb
;rdtim  = $ffde
;stop   = $ffe1
getin  = $ffe4
clall  = $ffe7
udtim  = $ffea
screen = $ffed
;plot   = $fff0
iobase = $fff3

monitor	jmp $ff00

vpeek	jsr chrget
	jsr chkopn ; open paren
	jsr getbyt ; byte: bank
	stx verahi
	jsr chkcom
	jsr frmnum
	jsr getadr ; word: offset
	sty veralo
	sta veramid
	jsr chkcls ; closing paren
	ldy veradat
	jmp sngflt

vpoke	jsr getbyt ; bank
	stx verahi
	jsr chkcom
	jsr getnum
	lda poker
	sta veralo
	lda poker+1
	sta veramid
	stx veradat
	rts

.if 0
dos	cmp #'"'
	beq dos3 ; dos with a command
dos1	jsr listen_6f_or_error
	jsr unlstn
	jsr command_channel_talk
dos11	jsr iecin
	jsr bsout
	cmp #13
	bne dos11
	jmp untalk

dos2	and #$0f
	sta $ba ; fa
	bne dos3
	jmp snerr

dos3	jsr chrget
	beq dos1
	cmp #$24
	bne dos4

	brk;XXX
;XXX	jmp l8b79

dos4	cmp #'8'
	beq dos2
	cmp #'9'
	beq dos2
	jsr listen_6f_or_error
	ldy #0
	lda (txtptr),y
	ldy #0
dos5	jsr dos9
	beq dos6
	jsr iecout
	iny
	bne dos5
dos6	cmp #'"'
	bne dos7
	iny
dos7	tya
	clc
	adc txtptr
	sta txtptr
	bcc dos8
	inc txtptr + 1
dos8	jmp unlstn

dos9	lda (txtptr),y
	beq dosa
	cmp #'"'
dosa	rts

command_channel_talk:
	lda #$6f
	pha
	jsr set_drive
	jsr talk
	pla
	jmp tksa
.endif
