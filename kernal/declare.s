	.segment "ZPKERNAL" : zeropage
status	.res 1           ;i/o operation status byte
; crfac .res 2 ;correction factor (unused)
stkey	.res 1           ;stop key flag
savbank	.res 1           ;old bank when switching (was: tape)
verck	.res 1           ;load or verify flag
c3p0	.res 1           ;ieee buffered char flag
bsour	.res 1           ;char buffer for ieee
	.res 1           ;unused (tape)
xsav	.res 1           ;temp for basin
ldtnd	.res 1           ;index to logical file
dfltn	.res 1           ;default input device #
dflto	.res 1           ;default output device #
imparm	.res 2           ;PRIMM utility string pointer (was: tape)
msgflg	.res 1           ;os message flag
t1	.res 1           ;temporary 1
	.res 1           ;unused (tape)
time	.res 3           ;24 hour clock in 1/60th seconds
r2d2	.res 1           ;serial bus usage
; ptch .res 1  (unused)
bsour1	;temp used by serial routine
	.res 1           ;also used by CBDOS
count	.res 1           ;temp used by serial routine
	.res 1           ;unused (tape)
	.res 5           ;unused (rs-232)
sal	.res 1
sah	.res 1
eal	.res 1
eah	.res 1
kbdbyte	.res 1           ;PS/2: bit input (was: tape)
prefix	.res 1           ;PS/2: prefix code (e0/e1) (was: tape)
brkflg	.res 1           ;PS/2: was key-up event (was: tape)
shflag2	.res 1           ;PS/2: modifier state (was: tape)
	.res 3           ;unused (rs-232)
fnlen	.res 1           ;length current file n str
la	.res 1           ;current file logical addr
sa	.res 1           ;current file 2nd addr
fa	.res 1           ;current file primary addr
fnadr	.res 2           ;addr current file name str
	.res 1           ;unused (rs-232)
ckbtab	.res 2           ;used for keyboard lookup
	.res 1           ;unused (tape)
tmp0
stal	.res 1
stah	.res 1
memuss	;cassette load temps (2 bytes)
tmp2	.res 2
;
;variables for screen editor
;
isomod	.res 1           ;ISO mode
ndx	.res 1           ;index to keyboard q
rvs	.res 1           ;rvs field on flag
indx	.res 1
lsxp	.res 1           ;x pos at start
lstp	.res 1
sfdx	.res 1           ;shift mode on print
blnsw	.res 1           ;cursor blink enab
blnct	.res 1           ;count to toggle cur
gdbln	.res 1           ;char before cursor
blnon	.res 1           ;on/off blink flag
crsw	.res 1           ;input vs get flag
pnt	.res 2           ;pointer to row
; point .res 1   (unused)
pntr	.res 1           ;pointer to column
qtsw	.res 1           ;quote switch
lnmx	.res 1           ;40/80 max positon
tblx	.res 1
data	.res 1
insrt	.res 1           ;insert mode flag
llen	.res 1           ;x resolution
nlines	.res 1           ;y resolution
llenm1	.res 1           ;x resolution - 1
nlinesp1 .res 1          ;y resolution + 1
nlinesm1 .res 1          ;y resolution - 1
nlinesm2 .res 1          ;y resolution - 2
	.res 16          ;used by CBDOS
joy1	.res 3           ;joystick 1 status
joy2	.res 3           ;joystick 2 status
keytab	.res 2           ;keyscan table indirect
	.res 4           ;unused (rs-232)
frekzp	.res 4           ;free kernal zero page 9/24/80
baszpt	.res 1           ;location ($00ff) used by basic

	.segment "STACK"
bad	.res 1
	.segment "KVAR"
buf	.res 89          ;basic/monitor buffer

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
color	.res 1           ;activ color nybble
gdcol	.res 1           ;original color before cursor
hibase	.res 1           ;base location of screen (top)
xmax	.res 1
ps2byte	.res 1           ;byte storage for ps/2 communication
ps2par	.res 1           ;parity for ps/2 communication
delay	.res 1
shflag	.res 1           ;shift flag byte
lstshf	.res 1           ;last shift pattern
	.res 2           ;unused (keyboard)
mode	.res 1           ;0-pet mode, 1-cattacanna
autodn	.res 1           ;auto scroll down flag(=0 on,<>0 off)

	.res 12          ;unused (rs-232)
	.res 1           ;unused (tape)
joy0	.res 1           ;keyboard joystick temp
;
; temp space for vic-40 variables ****
;
	.res 1           ;rs-232 enables (replaces ier)
curkbd	.res 1           ;current keyboard layout index
	.res 2           ;unused (tape)
lintmp	.res 1           ;temporary for line index
palnts	.res 1           ;pal vs ntsc flag 0=ntsc 1=pal

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

ldtb1	.res 61          ;flags+endspace

kbdnam  =$0400           ;6 character keyboard layout name
kbdtab  =$0406           ;5 pointers to shift/alt/ctrl/altgr/unshifted tables

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
