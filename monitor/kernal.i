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

; monitor

; irq

; monitor and irq
pnt = $1111 ; XXX
pntr = $1111 ; XXX

; monitor and io
insrt = $1111 ; XXX

.endif

.include "banks.inc"
.include "io.inc"

CINV   := $0314 ; IRQ vector
CBINV  := $0316 ; BRK vector

_basic_warm_start := $ff47
FETCH  := $FF74
STASH  := $FF77

; for "dump_8_ascii_characters" and "read_ascii"
PNTR            := pntr   ; cursor column
INSRT           := insrt  ; insert mode counter

BUF             := $0200 ; system input buffer
