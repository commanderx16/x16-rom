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

; monitor and irq
pntr = $1111 ; XXX

BUF             := $0200 ; system input buffer
