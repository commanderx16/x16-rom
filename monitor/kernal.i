; ----------------------------------------------------------------
; KERNAL Symbols
; ----------------------------------------------------------------

_basic_warm_start := $ff47
CINT            := $FF81
IOINIT          := $FF84
RAMTAS          := $FF87
RESTOR          := $FF8A
VECTOR          := $FF8D
SETMSG          := $FF90
SECOND          := $FF93
TKSA            := $FF96
MEMTOP          := $FF99
MEMBOT          := $FF9C
SCNKEY          := $FF9F
SETTMO          := $FFA2
IECIN           := $FFA5
IECOUT          := $FFA8
UNTALK          := $FFAB
UNLSTN          := $FFAE
LISTEN          := $FFB1
TALK            := $FFB4
READST          := $FFB7
SETLFS          := $FFBA
SETNAM          := $FFBD
OPEN            := $FFC0
CLOSE           := $FFC3
CHKIN           := $FFC6
CKOUT           := $FFC9
CLRCH           := $FFCC
BASIN           := $FFCF
BSOUT           := $FFD2
LOAD            := $FFD5
SAVE            := $FFD8
SETTIM          := $FFDB
RDTIM           := $FFDE
STOP            := $FFE1
GETIN           := $FFE4
CLALL           := $FFE7
UDTIM           := $FFEA
SCREEN          := $FFED
PLOT            := $FFF0
IOBASE          := $FFF3

;CHRGET          := $0073
;CHRGOT          := $0079

; PETSCII
CR              := $0D
CSR_DOWN        := $11
CSR_HOME        := $13
CSR_RIGHT       := $1D
CSR_UP          := $91
KEY_STOP        := $03
KEY_F3          := $86
KEY_F5          := $87
KEY_F7          := $88

; from KERNAL
.if 0
.import xmon2, bmt2, loop4, xmon1, screen_get_char, screen_set_char, ldtb1, stavec
.import nlines, nlinesm1

.importzp txtptr, fnadr
.import pnt
.import fnlen, la, sa, fa, mode, rvs, blnsw, gdbln, blnon, pntr, qtsw, tblx, insrt
.import buf, rptflg

.import kbdbuf_clear, kbdbuf_put
.import jsrfar
.else
txtptr = $aa ; XXX
fnadr = $aa ; XXX

xmon2 = $aaaa ; XXX
bmt2 = $aaaa ; XXX
loop4 = $aaaa ; XXX
xmon1 = $aaaa ; XXX
screen_get_char = $aaaa ; XXX
screen_set_char = $aaaa ; XXX
ldtb1 = $aaaa ; XXX
stavec = $aaaa ; XXX
nlines = $aaaa ; XXX
nlinesm1 = $aaaa ; XXX
pnt = $aaaa ; XXX
fnlen = $aaaa ; XXX
la = $aaaa ; XXX
sa = $aaaa ; XXX
mode = $aaaa ; XXX
rvs = $aaaa ; XXX
blnsw = $aaaa ; XXX
gdbln = $aaaa ; XXX
blnon = $aaaa ; XXX
pntr = $aaaa ; XXX
qtsw = $aaaa ; XXX
tblx = $aaaa ; XXX
insrt = $aaaa ; XXX
buf = $aaaa ; XXX
rptflg = $aaaa ; XXX
kbdbuf_clear = $aaaa ; XXX
kbdbuf_put = $aaaa ; XXX
jsrfar = $aaaa ; XXX
.endif

.include "banks.inc"

via1	=$9f60                  ;VIA 6522 #1
d1prb	=via1+0
d1pra	=via1+1

FETCH  := $FF74
STASH  := $FF77

ST              := status ; kernal I/O status
FNLEN           := fnlen  ; length of current file name
LA              := la     ; logical file number
SA              := sa     ; secondary address
FA              := fa     ; device number
FNADR           := fnadr  ; file name
MODE            := mode   ; bit6=1: ISO mode
RVS             := rvs    ; print reverse characters flag
BLNSW           := blnsw  ; cursor blink enable
GDBLN           := gdbln  ; character under cursor
BLNON           := blnon  ; cursor blink phase
PNT             := pnt    ; current screen line address
PNTR            := pntr   ; cursor column
QTSW            := qtsw   ; quote mode flag
TBLX            := tblx   ; cursor line
INSRT           := insrt  ; insert mode counter
LDTB1           := ldtb1  ; screen line link table


BUF             := buf ; system input buffer
