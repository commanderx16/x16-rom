.feature labels_without_colons
.setcpu "65c02"

; for monitor
; XXX these should be removed or at least minimized
.export xmon2, ms1

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

; from RS232
.import opn232, cls232, cko232, cki232, bso232, bsi232

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

.include "../banks.inc"
.include "../io.inc"

.include "declare.s"
.include "serial4.0.s"

.include "channelio/messages.s"
.include "channelio/channelio.s"
.include "channelio/openchannel.s"
.include "channelio/close.s"
.include "channelio/clall.s"
.include "channelio/open.s"
.include "channelio/load.s"
.include "channelio/save.s"
.include "channelio/errorhandler.s"

.include "init.s"
.include "nmi.s"
.include "irqfile.s"
.include "primm.s"
.include "vectors.s"
