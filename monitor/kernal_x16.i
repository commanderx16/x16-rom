; C64-specific KERNAL symbols
; http://www.c64.ch/programming/memorymap.php

; from KERNAL
.import xmon2, ms1, key, bmt2, loop4, xmon1, ldapnty, stapnty, ldtb1, stavec
.import nlines, nlinesm1

.importzp txtptr, fnadr, pnt
.import status, fnlen, la, sa, fa, mode, rvs, blnsw, gdbln, blnon, pntr, qtsw, tblx, insrt
.import buf, rptflg

.import kbd_clear, kbd_peek, kbd_put, jsrfar


.include "../banks.inc"

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

;R6510           := $01   ; 6510 I/O register
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
