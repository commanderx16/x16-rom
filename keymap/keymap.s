.segment "KBDMETA"
.word kbdmeta  ; $c000
.word ikbdmeta ; $c002

kbdmeta:

; PETSCII
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
.include "asm/416.s"    ; Portuguese (Brazil ABNT)

.segment "KBDMETA"
	.byte 0 ; terminator

.segment "IKBDMETA"
ikbdmeta:

; ISO
.include "asm/i409.s"
.include "asm/i809.s"
.include "asm/i407.s"
.include "asm/i41D.s"
.include "asm/i410.s"
.include "asm/i415.s"
.include "asm/i40E.s"
.include "asm/i40A.s"
.include "asm/i40C.s"
.include "asm/i807.s"
.include "asm/i80C.s"
.include "asm/i416.s"

.segment "IKBDMETA"
	.byte 0 ; terminator
