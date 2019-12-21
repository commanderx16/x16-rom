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

; for editor
.export dfltn
.export dflto
.export sah
.export sal

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

.export acptr     ; serial
.export ciout     ; serial
.export listn     ; serial
.export scatn     ; serial
.export secnd     ; serial
.export talk      ; serial
.export tkatn     ; serial
.export tksa      ; serial
.export unlsn     ; serial
.export untlk     ; serial

.export iload     ; vectors
.export isave     ; vectors

.export bsout     ; XXX should go through jump table symbol
.export close     ; XXX should go through jump table symbol
.export clrch     ; XXX should go through jump table symbol
.export stop      ; XXX should go through jump table symbol

.export dfltn     ; XXX zp move?
.export dflto     ; XXX zp move?
.export sah       ; XXX zp move?
.export sal       ; XXX zp move?
.export eah       ; XXX zp move
.export eal       ; XXX zp move
.export fa        ; XXX zp move
.export fat       ; XXX zp move
.exportzp fnadr   ; XXX zp move
.export fnlen     ; XXX zp move
.export la        ; XXX zp move
.export lat       ; XXX zp move
.export ldtnd     ; XXX zp move
.export memuss    ; XXX zp move
.export msgflg    ; XXX zp move
.export sa        ; XXX zp move
.export sat       ; XXX zp move
.export stah      ; XXX zp move
.export stal      ; XXX zp move
.export status    ; XXX zp move
.export t1        ; XXX zp move
.export verck     ; XXX zp move
.export xsav      ; XXX zp move

.include "../banks.inc"
.include "../io.inc"

.include "declare.s"
.include "serial4.0.s"
.include "init.s"
.include "nmi.s"
.include "irqfile.s"
.include "primm.s"
.include "vectors.s"
