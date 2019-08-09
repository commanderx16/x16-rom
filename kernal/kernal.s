.feature labels_without_colons, pc_assignment

; for monitor
; XXX these should be removed or at least minimized
.export xmon2, ms1, key, bmt2, loop4, xmon1, ldapnty, stapnty, ldtb1
.ifndef C64
.export stavec
.endif

.include "declare.s"
.include "editor.1.s"
.include "editor.2.s"
.include "editor.3.s"
.include "serial4.0.s"
.include "rs232trans.s"
.include "rs232rcvr.s"
.include "rs232inout.s"
.include "messages.s"
.include "channelio.s"
.include "openchannel.s"
.include "close.s"
.include "clall.s"
.include "open.s"
.include "load.s"
.include "save.s"
.include "time.s"
.include "errorhandler.s"
.include "read.s"
.include "write.s"
.include "init.s"
.include "rs232nmi.s"
.include "irqfile.s"
.ifndef C64
.include "routines.s"
.endif
.include "vectors.s"

