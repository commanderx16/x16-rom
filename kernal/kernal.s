.feature labels_without_colons
.setcpu "65c02"

; for monitor
; XXX these should be removed or at least minimized
.export xmon2, ms1, key, bmt2, loop4, xmon1, ldapnty, stapnty, ldtb1, nlines, nlinesm1
.export stavec

.include "../banks.inc"
.include "../io.inc"

.include "declare.s"
.include "editor.1.s"
.include "editor.3.s"
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

