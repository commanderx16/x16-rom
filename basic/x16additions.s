verareg =$9f20
veralo  =verareg+0
veramid =verareg+1
verahi  =verareg+2
veradat =verareg+3
veradat2=verareg+4
veractl =verareg+5
veraien =verareg+6
veraisr =verareg+7

; XXX from KERNAL
.import status, fnlen, la, sa, fa
.import mousex, mousey, mousebt

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
	lda status
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
	lda status
	bne disk_done   ;...branch if error
	dey
	bne @d25        ;...loop until done

	jsr basin       ;get # blocks low
	ldy status
	bne disk_done   ;...branch if error
	tax
	jsr basin       ;get # blocks high
	ldy status
	bne disk_done   ;...branch if error
	jsr linprt      ;print # blocks

	lda #' '
	jsr bsout       ;print space  (to match loaded directory display)

@d30	jsr basin       ;read & print filename & filetype
	beq @d40        ;...branch if eol
	ldx status
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

mouse:
	jsr getbyt
	txa
	ldx #0 ; keep scale
	jmp $ff09

mx:
	jsr chrget
	ldy mousex
	lda mousex+1
	jmp givayf

my:
	jsr chrget
	ldy mousey
	lda mousey+1
	jmp givayf

mb:
	jsr chrget
	ldy mousebt
	jmp sngflt
