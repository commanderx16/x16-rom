.segment "KBDMETA"

.include "asm/409.s"    ; US
.include "asm/809.s"    ; United Kingdom
.include "asm/407.s"    ; German
.include "asm/41D.s"    ; Swedish
.include "asm/410.s"    ; Italian
.include "asm/415.s"    ; Polish (Programmers)
.include "asm/40E.s"    ; Hungarian
.include "asm/40A.s"    ; Spanish
.include "asm/40C.s"    ; French
.include "asm/807.s"    ; Swiss German
.include "asm/80C.s"    ; Belgian French
;.include "asm/416.s"    ; Portuguese (Brazil ABNT)

.segment "KBDMETA"
	.byte 0 ; terminator
