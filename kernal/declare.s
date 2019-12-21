; for monitor
.globalzp txtptr, fnadr, pnt
.global fnlen, la, sa, fa, mode, rvs, blnsw, gdbln, blnon, pntr, qtsw, tblx, insrt
.global buf
; for monitor and CBDOS
.global status
; for BASIC and GEOS
.global mousex, mousey, mousebt

.export tmp2; [cpychr]
.export ckbtab; [ps2kbd]
.export imparm; [jsrfar]
.export ptr_fg; [graph]
.export save_ram_bank

.segment "ZPKERNAL" : zeropage
;                      C64 location
;                         VVV
tmp2	.res 2           ;$C3
imparm	.res 2           ;    PRIMM utility string pointer
ckbtab	.res 2           ;    used for keyboard lookup
ptr_fg	.res 2


.segment "KVAR"

;                      C64 location
;                         VVV
buf	.res 2*40+1      ;    basic/monitor buffer
.assert buf = $0200, error, "buf has to be at $0200"

save_ram_bank
	.res 1

; Memory
memstr	.res 2           ;    start of memory
memsiz	.res 2           ;    top of memory
rambks	.res 1           ;    X16: number of ram banks (0 means 256)

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

.segment "KVARSB0"

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

.export mhz
mhz     =8              ;for the scroll delay loop

;rsr 8/3/80 add & change z-page
;rsr 8/11/80 add memuss & plf type
;rsr 8/22/80 add rs-232 routines
;rsr 8/24/80 add open variables
;rsr 8/29/80 add baud space move rs232 to z-page
;rsr 9/2/80 add screen editor vars&con
;rsr 12/7/81 modify for vic-40
