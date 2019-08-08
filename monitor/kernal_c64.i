; C64-specific KERNAL symbols
; http://www.c64.ch/programming/memorymap.php

LE50C  := $E50C ; set cursor position
LE716  := $E716 ; screen CHROUT
LE96C  := $E96C ; insert line at top of screen
LEA31  := $EA31 ; default contents of CINV vector
LF0BD  := $F0BD ; string "I/O ERROR"
LF333  := $F333 ; default contents of CLRCHN vector
LF646  := $F646 ; IEC close

ICLRCH := $0322 ; CLRCHN vector
IBSOUT := $0326 ; CHROUT vector

R6510           := $01   ; 6510 I/O register
TXTPTR          := $7A   ; current byte of BASIC text
ST              := $90   ; kernal I/O status
FNLEN           := $B7   ; length of current file name
LA              := $B8   ; logical file number
SA              := $B9   ; secondary address
FA              := $BA   ; device number
FNADR           := $BB   ; file name
NDX             := $C6   ; number of characters in keyboard buffer
RVS             := $C7   ; print reverse characters flag
BLNSW           := $CC   ; cursor blink enable
GDBLN           := $CE   ; character under cursor
BLNON           := $CF   ; cursor blink phase
PNT             := $D1   ; current screen line address
PNTR            := $D3   ; cursor column
QTSW            := $D4   ; quote mode flag
TBLX            := $D6   ; cursor line
INSRT           := $D8   ; insert mode counter
LDTB1           := $D9   ; screen line link table

BUF             := $0200 ; system input buffer
KEYD            := $0277 ; keyboard buffer
RPTFLG          := $028A ; key repeat flag
