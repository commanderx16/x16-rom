.feature labels_without_colons
.setcpu "65c02"

; for monitor
; XXX these should be removed or at least minimized
.export xmon2, ms1
.export stavec

; from editor
.import plot
.import scrorg
.import cint
.import prt
.import loop5
.import crsw
.import hibase
.import indx
.import lnmx
.import lstp
.import lsxp
.import key

.import kbd_scan
.import kbd_clear
.import kbd_get
.import kbd_get_stop

; for editor
.export dfltn
.export dflto
.export iokeys
.export sah
.export sal

; from RS232
.import opn232, cls232, cko232, cki232, bso232, bsi232

.include "../banks.inc"
.include "../io.inc"

.include "declare.s"
.include "serial4.0.s"
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
