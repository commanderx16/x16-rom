.feature labels_without_colons
.setcpu "65c02"

; for monitor
; XXX these should be removed or at least minimized
;.export xmon2, ms1

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
.export acptr
.export bsout
.export ciout
.export close
.export clrch
;.export crsw
.export dfltn
.export dflto
.export eah
.export eal
.export fa
.export fat
.exportzp fnadr
.export fnlen
.export iload
;.export indx
.export isave
;.export kbd_clear
;.export kbd_get
;.export kbd_get_stop
.export la
.export lat
.export ldtnd
.export listn
;.export lnmx
;.export loop5
;.export lstp
;.export lsxp
.export memuss
.export msgflg
;.export pntr
;.export prt
.export sa
.export sah
.export sal
.export sat
.export scatn
.export secnd
.export stah
.export stal
.export status
.export stop
.export t1
.export talk
;.export tblx
.export tkatn
.export tksa
.export unlsn
.export untlk
.export veradat
.export verahi
.export veralo
.export veramid
.export verck
.export xsav

.include "../banks.inc"
.include "../io.inc"

.include "declare.s"
.include "serial4.0.s"
.include "init.s"
.include "nmi.s"
.include "irqfile.s"
.include "primm.s"
.include "vectors.s"
