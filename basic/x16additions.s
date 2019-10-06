verareg =$9f20
veralo  =verareg+0
veramid =verareg+1
verahi  =verareg+2
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
fnlen = $b7
la = $b8
sa = $b9
fa = $ba

;***************
monitor	jmp $fff6

;***************
vpeek	jsr chrget
	jsr chkopn ; open paren
	jsr getbyt ; byte: bank
	stx verahi
	jsr chkcom
	lda poker
	pha
	lda poker + 1
	pha
	jsr frmadr ; word: offset
	sty veralo
	sta veramid
	pla
	sta poker + 1
	pla
	sta poker
	jsr chkcls ; closing paren
	ldy veradat
	jmp sngflt

;***************
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

;***************
vload	jsr plsv   ;parse the parameters
	bcc vld1   ;require bank/addr
	jmp snerr
vld1	lda andmsk ;bank number
	adc #2
	jmp cld10  ;jump to load command

;***************
old	beq old1
	jmp snerr
old1	lda txttab+1
	ldy #1
	sta (txttab),y
	jsr lnkprg
	clc
	lda index
	adc #2
	sta vartab
	lda index+1
	adc #0
	sta vartab+1
	jmp init2

;***************
.import _ResetHandle, jsrfar
geos	jsr jsrfar
	.word _ResetHandle
	.byte BANK_GEOS

;***************
.import geos_init_vera, color
.import swpp1
r2              =       $06
r2L             =       $06
r2H             =       $07
r3L             =       $08
r3H             =       $09
r4L             =       $0a
r4H             =       $0b
r11L            =       $18
r11H            =       $19
dispBufferOn            =       $2f
cscreen	lda #$0e ; light gray
	sta color
	jsr jsrfar
	.word swpp1
	.byte BANK_KERNAL

	sei

	jsr jsrfar
	.word geos_init_vera
	.byte BANK_GEOS

	lda #$80
	sta dispBufferOn
	lda #1
	jsr jsrfar
	.word SetPattern
	.byte BANK_GEOS

	ldx #32
	ldy #0
	sty 2
	lda #$a0
	sta 3
	tya
:	sta (2),y
	iny
	bne :-
	inc 3
	dex
	bne :-

	jsr jsrfar
	.word convert_vic_to_vera2
	.byte BANK_GEOS
	cli
	rts

;***************
.import _DrawLine, convert_vic_to_vera2
.import SetPattern
line	sei
.if 1
	lda #0
	sta r3L
	sta r3H
	sta r11L
	lda #<319
	sta r4L
	lda #>319
	sta r4H
	lda #199
	sta r11H
	lda #0
	sec
	jsr jsrfar
	.word _DrawLine
	.byte BANK_GEOS

	lda #<319
	sta r3L
	lda #>319
	sta r3H
	lda #0
	sta r11L
	lda #0
	sta r4L
	sta r4H
	lda #199
	sta r11H
	lda #0
	sec
	jsr jsrfar
	.word _DrawLine
	.byte BANK_GEOS

	lda #0
	sta r3L
	sta r3H
	sta r11L
	lda #100
	sta r4L
	lda #0
	sta r4H
	lda #100
	sta r11H
	lda #0
	sec
	jsr jsrfar
	.word _DrawLine
	.byte BANK_GEOS
.endif
.import _Rectangle
	lda #0
	sta r3L
	sta r3H
	sta r2L
	lda #100
	sta r4L
	lda #0
	sta r4H
	lda #100
	sta r2H
	jsr jsrfar
	.word _Rectangle
	.byte BANK_GEOS

	jsr jsrfar
	.word convert_vic_to_vera2
	.byte BANK_GEOS
	cli
	rts

	nop
xxxx	jsr getnum
	lda poker
	ldy poker+1
	jsr linprt
	lda #' '
	jsr $ffd2
	jsr chkcom
	jsr getnum
	ldy poker
	lda poker+1
	jsr linprt
	lda #' '
	jsr $ffd2
	jsr chkcom
	jsr getnum
	ldy poker
	lda poker+1
	jsr linprt
	lda #' '
	jsr $ffd2
	jsr chkcom
	jsr getnum
	ldy poker
	lda poker+1
	jsr linprt
	lda #' '
	jsr $ffd2
	rts


;***************
dos	beq ptstat      ;no argument: print status
	jsr frmstr      ;length in .a
	cmp #0
	beq ptstat      ;no argument: print status
	ldx index1
	ldy index1+1
	jsr setnam
	ldy #0
	lda (index1),y
; dir?
	cmp #'$'
	beq disk_dir
; switch default drive?
	cmp #'8'
	beq dossw
	cmp #'9'
	beq dossw

;***************
; DOS command
	jsr listen_cmd
	ldy #0
dos9	lda (index1),y
	jsr iecout
	iny
	cpy fnlen
	bne dos9
	jmp unlstn

listen_cmd:
	jsr getdev
	jsr listen
	lda #$6f
	jsr second
	lda st
	bmi :+
	rts
device_not_present:
	ldx #5 ; "DEVICE NOT PRESENT"
	jmp error


;***************
; print status
ptstat	jsr listen_cmd
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

;***************
; switch default drive
dossw	and #$0f
	sta fa
	rts

getdev:
	lda #8
	cmp fa
	bcs :+
	lda fa
:	rts


;***************
;  read & display the disk directory

LOGADD = 15

disk_dir
	lda #LOGADD     ;la
	ldx #8          ;fa
	ldy #$60        ;sa
	jsr setlfs
	jsr open        ;open directory channel
	bcs disk_done   ;...branch on error
	ldx #LOGADD
	jsr chkin       ;make it an input channel

	jsr crdo

	ldy #4          ;first pass only- trash first four bytes read

@d20
@d25	jsr basin
	lda st
	bne disk_done   ;...branch if error
	dey
	bne @d25        ;...loop until done

	jsr basin       ;get # blocks low
	ldy st
	bne disk_done   ;...branch if error
	tax
	jsr basin       ;get # blocks high
	ldy st
	bne disk_done   ;...branch if error
	jsr linprt      ;print # blocks

	lda #' '
	jsr bsout       ;print space  (to match loaded directory display)

@d30	jsr basin       ;read & print filename & filetype
	beq @d40        ;...branch if eol
	ldx st
	bne disk_done   ;...branch if error
	jsr bsout
	bcc @d30        ;...loop always

@d40	jsr crdo        ;start a new line
	jsr stop
	beq disk_done   ;...branch if user hit STOP
	ldy #2
	bne @d20        ;...loop always

disk_done
	jsr clrch
	lda #LOGADD
	sec
	jmp close
