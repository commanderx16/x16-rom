banked_irq          = $038b ; irq handler: RAM part
VERA_L              = $9f20
VERA_M              = $9f21
VERA_H              = $9f22
VERA_D0             = $9f23

.CODE

;HEADER
jmp main_entry
.byt "x16"      ;Magic string
.byt 1, 0, 0    ;Program version
.byt 4          ;Program name length
.byt "test"     ;Program name

;CODE
main_entry:
    stz VERA_L
    lda #20
    sta VERA_M
    lda #(2<<4)
    sta VERA_H
    ldy #0

:   lda hello,y
    beq exit
    sta VERA_D0
    iny
    bra :-

exit:
    rts

hello:
    .byt 8, 5, 12, 12, 15, 0

.segment "IRQ"
    .byt $ff, $ff, $ff, $ff, <banked_irq, >banked_irq