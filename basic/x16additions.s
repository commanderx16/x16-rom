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
st = $90
la = $b8
sa = $b9
fa = $ba

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

dos	cmp #'"'
	beq dos3 ; dos with a command
; no argument: print status
dos1	jsr listen_cmd
	jsr unlstn
	jsr getdev
	jsr talk
	lda #$6f
	jsr tksa
dos11	jsr iecin
	jsr bsout
	cmp #13
	bne dos11
	jmp untalk

; string argument
dos3	jsr chrget
	beq dos1
	cmp #'$'
	beq disk_dir
; switch default drive
	cmp #'8'
	beq dos2
	cmp #'9'
	bne dos2b
dos2	and #$0f
	sta fa
	bne dos3
; command
dos2b	jsr listen_cmd
	ldy #0
dos9	lda (txtptr),y
	beq dos7
	cmp #'"'
	beq dos6
	jsr iecout
	iny
	bne dos9 ; "always"
dos6	iny
dos7	tya
	clc
	adc txtptr
	sta txtptr
	bcc dos8
	inc txtptr + 1
dos8	jmp unlstn


listen_cmd:
	jsr getdev
	jsr listen
	lda #$6F
	jsr second
	lda st
	bmi device_not_present
	rts

device_not_present:
	ldx #5 ; "DEVICE NOT PRESENT"
	jmp error

getdev:
	lda #8
	cmp fa
	bcs :+
	lda fa
:	rts


;  read & display the disk directory

disk_dir
	brk
.if 0
	ldy #$ff	;determine directory string length
	ldx txtptr
	dex

10$	iny
	inx
	lda buf,x	;get a character
	bne 10$		;...loop until eol

	tya		;length
	ldx txtptr	;fnadr low
	ldy #>buf	;fnadr high
	jsr setnam
	lda #0		;la
	ldx t0		;fa
	ldy #$60	;sa
	jsr setlfs
	jsr open	;open directory channel
	bcs disk_done	;...branch on error
	ldx #0
	jsr chkin	;make it an input channel

	jsr crlf

	ldy #3		;first pass only- trash first two bytes read

20$	sty t1		;loop counter
25$	jsr basin
	sta t0		;get # blocks low
	lda status
	bne disk_done	;...branch if error
	jsr basin
	sta t0+1	;get # blocks high
	lda status
	bne disk_done	;...branch if error
	dec t1
	bne 25$		;...loop until done

	jsr bindec	;convert # blocks to decimal
	lda #0		;no leading zeros
	ldx #8		;max digits
	ldy #3		;required # shifts for decimal value
	jsr unpack	;print # blocks
	lda #' '
	jsr bsout	;print space  (to match loaded directory display)

30$	jsr basin	;read & print filename & filetype
	beq 40$		;...branch if eol
	ldx status
	bne disk_done	;...branch if error
	jsr bsout
	bcc 30$		;...loop always

40$	jsr crlf	;start a new line
	jsr stop
	beq disk_done	;...branch if user hit STOP
	ldy #2
	bne 20$		;...loop always

.endif
