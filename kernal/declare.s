; for monitor
.globalzp txtptr, fnadr, pnt
.global fnlen, la, sa, fa, mode, rvs, blnsw, gdbln, blnon, pntr, qtsw, tblx, insrt
.global buf
; for monitor and CBDOS
.global status
; for BASIC
.global scrmod
; for BASIC and GEOS
.global mousex, mousey, mousebt

.segment "ZPKERNAL" : zeropage
;                      C64 location
;                         VVV
.export tmp2; [cpychr]
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
.export ckbtab; [ps2kbd]
imparm	.res 2           ;PRIMM utility string pointer
ckbtab	.res 2           ;used for keyboard lookup
.export ptr_fg, ptr_bg; [graph]
ptr_fg	.res 2
ptr_bg	.res 2


.segment "KVAR"

;                      C64 location
;                         VVV
buf	.res 2*40+1      ;    basic/monitor buffer
.assert buf = $0200, error, "buf has to be at $0200"

.export save_ram_bank
save_ram_bank
	.res 1

; Screen Mode
;
cscrmd	.res 1           ;    X16: current screen mode (argument to scrmod)

; Memory
memstr	.res 2           ;    start of memory
memsiz	.res 2           ;    top of memory
rambks	.res 1           ;    X16: number of ram banks (0 means 256)

; Channel I/O
;
lat	.res 10          ;    logical file numbers
fat	.res 10          ;    primary device numbers
sat	.res 10          ;    secondary addresses
status	.res 1           ;$90 i/o operation status byte
verck	.res 1           ;$93 load or verify flag
xsav	.res 1           ;$97 temp for basin
ldtnd	.res 1           ;$98 index to logical file
dfltn	.res 1           ;$99 default input device #
dflto	.res 1           ;$9A default output device #
msgflg	.res 1           ;$9D os message flag
t1	.res 1           ;$9E temporary 1
fnlen	.res 1           ;$B7 length current file n str
la	.res 1           ;$B8 current file logical addr
sa	.res 1           ;$B9 current file 2nd addr
fa	.res 1           ;$BA current file primary addr
stal	.res 1           ;$C1
stah	.res 1           ;$C2

; Serial
;
c3p0	.res 1           ;$94 ieee buffered char flag
bsour	.res 1           ;$95 char buffer for ieee
r2d2	.res 1           ;$A3 serial bus usage
bsour1	.res 1           ;$A4 temp used by serial routine
count	.res 1           ;$A5 temp used by serial routine

.segment "GDRVVEC"

.export I_GRAPH_LL_BASE, I_GRAPH_LL_END; [graph]
I_GRAPH_LL_BASE:
I_GRAPH_LL_init:
	.res 2
I_GRAPH_LL_get_info:
	.res 2
I_GRAPH_LL_set_palette
	.res 2
I_GRAPH_LL_cursor_position:
	.res 2
I_GRAPH_LL_cursor_next_line:
	.res 2
I_GRAPH_LL_get_pixel:
	.res 2
I_GRAPH_LL_get_pixels:
	.res 2
I_GRAPH_LL_set_pixel:
	.res 2
I_GRAPH_LL_set_pixels:
	.res 2
I_GRAPH_LL_set_8_pixels:
	.res 2
I_GRAPH_LL_set_8_pixels_opaque:
	.res 2
I_GRAPH_LL_fill_pixels:
	.res 2
I_GRAPH_LL_filter_pixels:
	.res 2
I_GRAPH_LL_move_pixels:
	.res 2
I_GRAPH_LL_END:

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

.segment "KVAR2" ; more KERNAL vars
ldtb1	.res 61 +1       ;flags+endspace
	;       ^^ XXX at label 'lps2', the code counts up to
	;              numlines+1, THEN writes the end marker,
	;              which seems like one too many. This was
	;              worked around for now by adding one more
	;              byte here, but we should have a look at
	;              whether there's an off-by-one error over
	;              at 'lps2'!

; Screen
;
.export mode; [ps2kbd]
.export data; [cpychr]
mode	.res 1           ;    bit7=1: charset locked, bit6=1: ISO
gdcol	.res 1           ;    original color before cursor
hibase	.res 1           ;    base location of screen (top)
autodn	.res 1           ;    auto scroll down flag(=0 on,<>0 off)
lintmp	.res 1           ;    temporary for line index
color	.res 1           ;    activ color nybble
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
nlinesp1 .res 1          ;    X16: y resolution + 1
nlinesm1 .res 1          ;    X16: y resolution - 1

.segment "KVARSB0"

KVARSB0_START:

; Keyboard
;
.export keyd, ndx, shflag, kbdbyte, prefix, brkflg, stkey, curkbd, kbdnam, kbdtab
keyd	.res 10          ;    irq keyboard buffer
ndx	.res 1           ;$C6 index to keyboard q
shflag	.res 1           ;    shift flag byte
kbdbyte	.res 1           ;    X16: PS/2: bit input
prefix	.res 1           ;    X16: PS/2: prefix code (e0/e1)
brkflg	.res 1           ;    X16: PS/2: was key-up event
stkey	.res 1           ;$91 stop key flag: $ff = stop down
curkbd	.res 1           ;    X16: current keyboard layout index
kbdnam  .res 6           ;    keyboard layout name
kbdtab  .res 10          ;    pointers to shift/alt/ctrl/altgr/unshifted tables

; Mouse
;
.export msepar, mousel, mouser, mouset, mouseb, mousex, mousey, mousebt
msepar	.res 1           ;    X16: mouse: $80=on; 1/2: scale
mousel	.res 2           ;    X16: mouse: min x coordinate
mouser	.res 2           ;    X16: mouse: max x coordinate
mouset	.res 2           ;    X16: mouse: min y coordinate
mouseb	.res 2           ;    X16: mouse: max y coordinate
mousex	.res 2           ;    X16: mouse: x coordinate
mousey	.res 2           ;    X16: mouse: y coordinate
mousebt	.res 1           ;    X16: mouse: buttons (1: left, 2: right, 4: third)

; Joystick
;
.export j0tmp, joy0, joy1, joy2
j0tmp	.res 1           ;    X16: keyboard joystick temp
joy0	.res 1           ;    X16: keyboard joystick temp
joy1	.res 3           ;    X16: joystick 1 status
joy2	.res 3           ;    X16: joystick 2 status

; Time
;
.export datey, datem, dated, timeh, timem, times, timej, timer; [time]
datey	.res 1           ;    year-1900
datem	.res 1           ;    month
dated	.res 1           ;    day
timeh	.res 1           ;    hours
timem	.res 1           ;    minutes
times	.res 1           ;    seconds
timej	.res 1           ;    jiffies
timer	.res 3           ;$A0 24 bit 1/60th second timer

KVARSB0_END:

vicscn	=$0000

; i/o devices
;
mmtop   =$9f00

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

.export mhz
mhz     =8              ;for the scroll delay loop

;rsr 8/3/80 add & change z-page
;rsr 8/11/80 add memuss & plf type
;rsr 8/22/80 add rs-232 routines
;rsr 8/24/80 add open variables
;rsr 8/29/80 add baud space move rs232 to z-page
;rsr 9/2/80 add screen editor vars&con
;rsr 12/7/81 modify for vic-40
