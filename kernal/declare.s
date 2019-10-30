; for monitor
.globalzp txtptr, fnadr, pnt
.global status, fnlen, la, sa, fa, isomod, ndx, rvs, blnsw, gdbln, blnon, pntr, qtsw, tblx, insrt
.global buf, keyd, rptflg

; for basic
.global color, scrmod
; for basic and GEOS
.global mousex, mousey, mousebt
; for GEOS
.global mseinit, mouse, msescn, msespr

.segment "ZPKERNAL" : zeropage
;                      C64 location
;                         VVV
sal	.res 1           ;$AC
sah	.res 1           ;$AD
eal	.res 1           ;$AE
eah	.res 1           ;$AF
fnadr	.res 2           ;$BB addr current file name str
memuss	=tmp2            ;$C3 load temps (2 bytes)
tmp2	.res 2           ;$C3
pnt	.res 2           ;$D1 pointer to row
;
; X16 additions
;
imparm	.res 2           ;PRIMM utility string pointer
ckbtab	.res 2           ;used for keyboard lookup

.segment "STACK"

bad	.res 1

.segment "KVAR"

buf	.res 2*40+1      ;basic/monitor buffer

; tables for open files
;
lat	.res 10          ;logical file numbers
fat	.res 10          ;primary device numbers
sat	.res 10          ;secondary addresses

; system storage
;
keyd	.res 10          ;irq keyboard buffer
memstr	.res 2           ;start of memory
memsiz	.res 2           ;top of memory
timout	.res 1           ;ieee timeout flag

; screen editor storage
;
gdcol	.res 1           ;original color before cursor
hibase	.res 1           ;base location of screen (top)
xmax	.res 1
delay	.res 1
shflag	.res 1           ;shift flag byte
mode	.res 1           ;0-pet mode, 1-cattacanna
autodn	.res 1           ;auto scroll down flag(=0 on,<>0 off)
lintmp	.res 1           ;temporary for line index
color	.res 1           ;activ color nybble

;.segment "KVAR2"
;                      C64 location
;                         VVV
status	.res 1           ;$90 i/o operation status byte
stkey	.res 1           ;$91 stop key flag
verck	.res 1           ;$93 load or verify flag
c3p0	.res 1           ;$94 ieee buffered char flag
bsour	.res 1           ;$95 char buffer for ieee
xsav	.res 1           ;$97 temp for basin
ldtnd	.res 1           ;$98 index to logical file
dfltn	.res 1           ;$99 default input device #
dflto	.res 1           ;$9A default output device #
msgflg	.res 1           ;$9D os message flag
t1	.res 1           ;$9E temporary 1
time	.res 3           ;$A0 24 hour clock in 1/60th seconds
r2d2	.res 1           ;$A3 serial bus usage
bsour1	.res 1           ;$A4 temp used by serial routine
count	.res 1           ;$A5 temp used by serial routine
fnlen	.res 1           ;$B7 length current file n str
la	.res 1           ;$B8 current file logical addr
sa	.res 1           ;$B9 current file 2nd addr
fa	.res 1           ;$BA current file primary addr
stal	.res 1           ;$C1
stah	.res 1           ;$C2
;
;variables for screen editor
;
ndx	.res 1           ;$C6 index to keyboard q
rvs	.res 1           ;$C7 rvs field on flag
indx	.res 1           ;$C8
lsxp	.res 1           ;$C9 x pos at start
lstp	.res 1           ;$CA
blnsw	.res 1           ;$CC cursor blink enab
blnct	.res 1           ;$CD count to toggle cur
gdbln	.res 1           ;$CE char before cursor
blnon	.res 1           ;$CF on/off blink flag
crsw	.res 1           ;$D0 input vs get flag
pntr	.res 1           ;$D3 pointer to column
qtsw	.res 1           ;$D4 quote switch
lnmx	.res 1           ;$D5 40/80 max positon
tblx	.res 1           ;$D6
data	.res 1           ;$D7
insrt	.res 1           ;$D8 insert mode flag
llen	.res 1           ;$D9 x resolution
nlines	.res 1           ;$DA y resolution
;
; X16 additions
;
rambks	.res 1           ;number of ram banks (0 means 256)
isomod	.res 1           ;ISO mode
curkbd	.res 1           ;current keyboard layout index
kbdbyte	.res 1           ;PS/2: bit input
prefix	.res 1           ;PS/2: prefix code (e0/e1)
brkflg	.res 1           ;PS/2: was key-up event
llenm1	.res 1           ;x resolution - 1
nlinesp1 .res 1          ;y resolution + 1
nlinesm1 .res 1          ;y resolution - 1
nlinesm2 .res 1          ;y resolution - 2
j0tmp	.res 1           ;keyboard joystick temp
joy0	.res 1           ;keyboard joystick temp
joy1	.res 3           ;joystick 1 status
joy2	.res 3           ;joystick 2 status


	.segment "KVECTORS";rem kernal/os indirects(20)
cinv	.res 2           ;irq ram vector
cbinv	.res 2           ;brk instr ram vector
nminv	.res 2           ;nmi ram vector
iopen	.res 2           ;indirects for code
iclose	.res 2           ; conforms to kernal spec 8/19/80
ichkin	.res 2
ickout	.res 2
iclrch	.res 2
ibasin	.res 2
ibsout	.res 2
istop	.res 2
igetin	.res 2
iclall	.res 2
usrcmd	.res 2
iload	.res 2
isave	.res 2           ;savesp

; more KERNAL vars
ldtb1	.res 61          ;flags+endspace

msepar	.res 1           ;mouse: $80=sprite on; 1/2: scale
mousel	.res 2           ;mouse: min x coordinate
mouser	.res 2           ;mouse: max x coordinate
mouset	.res 2           ;mouse: min y coordinate
mouseb	.res 2           ;mouse: max y coordinate
mousex	.res 2           ;mouse: x coordinate
mousey	.res 2           ;mouse: y coordinate
mousebt	.res 1           ;mouse: buttons (1: left, 2: right, 4: third)

cscrmd	.res 1           ;current screen mode (argument to scrmod)

kbdnam  =$0500           ;6 character keyboard layout name
kbdtab  =$0506           ;5 pointers to shift/alt/ctrl/altgr/unshifted tables

vicscn	=$0000

verareg =$9f20
veralo  =verareg+0
veramid =verareg+1
verahi  =verareg+2
veradat =verareg+3
veradat2=verareg+4
veractl =verareg+5
veraien =verareg+6
veraisr =verareg+7

; i/o devices
;
mmtop   =$9f00

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

; XXX TODO:
; XXX The following symbols are CIA 6526-based and required for
; XXX serial & rs232. Both drivers need to be changed to use
; XXX the VIAs instead. At that point, these symbols must be removed.
d2cra	=0
d2crb	=0
d2icr	=0
d1crb	=0
d1icr	=0

; XXX TODO:
; XXX These symbols are currently used in the screen editor. They
; XXX need to be removed once the keyboard driver has been replaced.
colm	=d1pra                  ;keyboard matrix
rows	=d1prb                  ;keyboard matrix

; XXX TODO
timrb	=$19            ;6526 crb enable one-shot tb

;screen editor constants
;
white	=$01            ;white char color
blue	=$06            ;blue screen color
cr	=$d             ;carriage return

mhz     =8              ;for the scroll delay loop

;rsr 8/3/80 add & change z-page
;rsr 8/11/80 add memuss & plf type
;rsr 8/22/80 add rs-232 routines
;rsr 8/24/80 add open variables
;rsr 8/29/80 add baud space move rs232 to z-page
;rsr 9/2/80 add screen editor vars&con
;rsr 12/7/81 modify for vic-40
