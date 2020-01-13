; ----------------------------------------------------------------
; KERNAL Symbols
; ----------------------------------------------------------------

.include "kernal.inc"

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
;txtptr = $aa ; XXX

xmon2 = $aaaa ; XXX
bmt2 = $aaaa ; XXX
loop4 = $aaaa ; XXX
xmon1 = $aaaa ; XXX
screen_get_char = $aaaa ; XXX
ldtb1 = $aaaa ; XXX
stavec = $aaaa ; XXX
nlines = $aaaa ; XXX
nlinesm1 = $aaaa ; XXX
pnt = $aaaa ; XXX
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
.endif

.include "banks.inc"
.include "io.inc"

CINV   := $0314 ; IRQ vector
CBINV  := $0316 ; BRK vector

_basic_warm_start := $ff47
FETCH  := $FF74
STASH  := $FF77


PNTR            := pntr   ; cursor column
RVS             := rvs    ; print reverse characters flag
INSRT           := insrt  ; insert mode counter
QTSW            := qtsw   ; quote mode flag
MODE            := mode   ; bit6=1: ISO mode

.if 0
PNT             := pnt    ; current screen line address
BLNSW           := blnsw  ; cursor blink enable
GDBLN           := gdbln  ; character under cursor
BLNON           := blnon  ; cursor blink phase
TBLX            := tblx   ; cursor line
LDTB1           := ldtb1  ; screen line link table
screen_set_char = $aaaa ; XXX
.endif

BUF             := buf ; system input buffer
