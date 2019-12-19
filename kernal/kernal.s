.feature labels_without_colons
.setcpu "65c02"

; for monitor
; XXX these should be removed or at least minimized
.export xmon2, ms1
.export stavec

; from editor
.import plot
.import scrorg
.import kbd_scan
.import scnsiz
.import cint
.import kbd_clear
.import kbd_get_stop
.import prt
.import loop5
.import kbd_get
.import stapnty
.import ldapnty
.import xmon1
.import loop4
.import bmt2
.import key

; for editor
.export dfltn
.export dflto
.export iokeys
.export sah
.export sal

.include "../banks.inc"
.include "../io.inc"

.include "declare.s"
.include "serial4.0.s"
.include "rs232.s"
.include "messages.s"
.include "channelio.s"
.include "openchannel.s"
.include "close.s"
.include "clall.s"
.include "open.s"
.include "load.s"
.include "save.s"
.include "errorhandler.s"
.include "read.s"
.include "write.s"
.include "init.s"
.include "nmi.s"
.include "irqfile.s"
.include "routines.s"
.include "vectors.s"






; from editor
.import nlinesp1
.import lsxp
.import lstp
.import lnmx
.import llen
.import lintmp
.import indx
.import hibase
.import gdcol
.import crsw
.import color
.import blnct
.import autodn
.import nlinesm1
.import nlines
.import ldtb1
