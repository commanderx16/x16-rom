.export aud_helloworld

.import ym_write, ym_loadpatch

.segment "API"
    jmp ym_write
    jmp ym_loadpatch

.segment "CODE"
aud_helloworld:
.asciiz "hello world."

.segment "PATCHDATA"
PAT_marimba:
    .byte $DC,$00,$1B,$67,$61,$31,$21,$17,$1F,$0A,$DF,$5F,$DE
    .byte $DE,$0E,$10,$09,$07,$00,$05,$07,$04,$FF,$A0,$16,$17

.include "banks.inc"
.segment "VECTORS"
 .byt $ff, $ff, $ff, $ff, <banked_irq, >banked_irq
