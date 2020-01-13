; ----------------------------------------------------------------
; KERNAL Symbols
; ----------------------------------------------------------------

.include "kernal.inc"
.include "banks.inc"
.include "io.inc"

cbinv  := $0316 ; BRK vector

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
; monitor

; irq

; monitor and irq
pnt = $1111 ; XXX
pntr = $1111 ; XXX

; monitor and io
insrt = $1111 ; XXX

; for "dump_8_ascii_characters" and "read_ascii"
PNTR            := pntr   ; cursor column
INSRT           := insrt  ; insert mode counter

BUF             := $0200 ; system input buffer
