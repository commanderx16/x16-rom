.segment "KBDMETA"

.include "asm/20409.s"  ; United States-International
.include "asm/809.s"    ; United Kingdom
.include "asm/41D.s"    ; Swedish
.include "asm/407.s"    ; German
.include "asm/406.s"    ; Danish
.include "asm/410.s"    ; Italian
.include "asm/415.s"    ; Polish (Programmers)
.include "asm/414.s"    ; Norwegian
.include "asm/40E.s"    ; Hungarian
.include "asm/40A.s"    ; Spanish
.include "asm/40B.s"    ; Finnish
.include "asm/416.s"    ; Portuguese (Brazil ABNT)
.include "asm/405.s"    ; Czech
.include "asm/411.s"    ; Japanese
.include "asm/40C.s"    ; French
.include "asm/807.s"    ; Swiss German
.include "asm/10409.s"  ; Dvorak
.include "asm/425.s"    ; Estonian
.include "asm/80C.s"    ; Belgian French
.include "asm/1009.s"   ; Canadian French
.include "asm/40F.s"    ; Icelandic
.include "asm/816.s"    ; Portuguese
.include "asm/80A.s"    ; Latin American Spanish
.include "asm/Colemak.s"; US - Colemak

.segment "KBDMETA"
	.byte 0 ; terminator
