.feature labels_without_colons

; from editor
.import plot
.import scrorg
.import cint

.import kbd_scan

.import screen_set_mode
.import screen_set_charset

; from memory driver
.import ramtas
.import indfet
.import stash
.import cmpare
.import jsrfar
.import enter_basic

; from platform driver
.import ioinit

; channelio
; jmp table
.import savesp
.import loadsp
.import setnam
.import setlfs
.import readst
.import settmo
.import setmsg
.import lkupsa
.import lkupla
.import close_all
; vectors
.import nsave
.import nload
.import nclall
.import ngetin
.import nstop
.import nbsout
.import nbasin
.import nclrch
.import nckout
.import nchkin
.import nclose
.import nopen
.import udst
; XXX
.import dfltn
.import dflto

; channelio vectors
.export iload
.export isave

; serial
.import talk
.import listn
.import unlsn
.import untlk
.import ciout
.import acptr
.import tksa
.import secnd

; lzsa
.import memory_fill
.import memory_copy
.import memory_crc
.import memory_decompress

.include "../banks.inc"
.include "../io.inc"

.include "declare.s"
.include "init.s"
.include "nmi.s"
.include "irqfile.s"
.include "primm.s"
.include "vectors.s"
