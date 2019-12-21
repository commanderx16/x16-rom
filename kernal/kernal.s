.feature labels_without_colons
.setcpu "65c02"

; from editor
.import plot
.import scrorg
.import cint
.import prt
.import loop5
.import crsw
.import indx
.import lnmx
.import lstp
.import lsxp

.import kbd_scan
.import kbd_clear
.import kbd_get
.import kbd_get_stop

.import screen_set_mode
.import screen_set_charset

; from memory driver
.import ramtas
.import indfet
.import fetch
.import stash
.import cmpare
.import jsrfar
.import restore_basic

; from platform driver
.import ioinit

; channelio
.import savesp    ; jmp table
.import loadsp    ; jmp table
.import setnam    ; jmp table
.import setlfs    ; jmp table
.import readst    ; jmp table
.import settmo    ; jmp table
.import setmsg    ; jmp table
.import lkupsa    ; jmp table
.import lkupla    ; jmp table
.import close_all ; jmp table
.import nsave     ; vectors
.import nload     ; vectors
.import nclall    ; vectors
.import ngetin    ; vectors
.import nstop     ; vectors
.import nbsout    ; vectors
.import nbasin    ; vectors
.import nclrch    ; vectors
.import nckout    ; vectors
.import nchkin    ; vectors
.import nclose    ; vectors
.import nopen     ; vectors
.import udst      ; serial
.import dfltn     ; XXX
.import dflto     ; XXX

; channelio
.export iload     ; vectors
.export isave     ; vectors

.include "../banks.inc"
.include "../io.inc"

.include "declare.s"
.include "serial4.0.s"
.include "init.s"
.include "nmi.s"
.include "irqfile.s"
.include "primm.s"
.include "vectors.s"
