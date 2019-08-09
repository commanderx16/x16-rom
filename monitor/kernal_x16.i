; C64-specific KERNAL symbols
; http://www.c64.ch/programming/memorymap.php

; from KERNAL
.import xmon2, ms1, key, bmt2, loop4, xmon1, ldapnty, stapnty, ldtb1, stavec

via1	=$9f60                  ;VIA 6522 #1
d1prb	=via1+0
d1pra	=via1+1

LE50C  := xmon1 ; set cursor position
LE716  := loop4 ; screen CHROUT
LE96C  := bmt2  ; insert line at top of screen
LEA31  := key   ; default contents of CINV vector
LF0BD  := ms1   ; string "I/O ERROR"
LF646  := xmon2 ; IEC close

FETCH  := $FF74
STASH  := $FF77

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
LDTB1           := ldtb1 ; screen line link table

BUF             := $0200 ; system input buffer
KEYD            := $0277 ; keyboard buffer
RPTFLG          := $028A ; key repeat flag
