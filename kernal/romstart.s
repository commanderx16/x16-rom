;----------------------------------------------------------------------
; ROM_START
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "regs.inc"
.include "banks.inc"
.export rom_start

.segment "ROMSTART"

name    = r1        ;Program name
len     = r0        ;Length of program name
bnk     = r0+1      ;Current ROM bank
vect    = r2        ;Vector to ROM

;**************************************************
;ROM_START: A KERNAL function searches for and
;runs a program stored in ROM. The function
;expects the start of a ROM image to
;be formatted as such.
;
;----------------------------------------------------
;Address   | Description
;----------------------------------------------------
;c000-c002 | Jump instruction to program entry point 
;c003-c005 | Magic string: "X16"
;c006-c008 | Program version, major-minor-patch
;c009      | Program name length
;c00a-     | Program name
;----------------------------------------------------
;
;Input:  R0 LSB = Program name length
;        R1     = Pointer to program name string
;
;Output: Nothing

rom_start:
    ;Setup
    stz bnk
    lda #$c0
    sta vect+1

loop:
    ;Verify magic string "X16"
    lda #3
    sta vect
    ldy #0
    
:   ldx bnk
    lda #vect
    jsr $ff74
    cmp magic,y
    bne nxtbnk
    iny
    cpy #3
    bne :-

    ;Verify length of program name
    ldx bnk
    lda #vect
    ldy #6
    jsr $ff74
    cmp len
    bne nxtbnk

    ;Verify program name
    lda #$a
    sta vect
    ldy #0

:   ldx bnk
    lda #vect
    jsr $ff74
    cmp (name),y
    bne nxtbnk
    iny
    cpy len
    bne :-

found:
    pha             ;reserve 1 byte on the stack
    php
    pha

    tsx             ;save current bank on stack
    lda $1
    sta $0103,x
    
    stz jmpfr+1     ;set call address, always $c000
    lda #$c0
    sta jmpfr+2

    lda bnk         ;set ROM bank
    jmp jsrfar3

nxtbnk:
    inc bnk
    lda bnk
    cmp #32
    bne loop

    ldy #0
:   lda notfoundmsg,y
    beq list
    jsr $ffd2
    iny
    bra :-

list:
    ;Setup
    stz bnk
    lda #$c0
    sta vect+1

    ;Verify magic string "X16"
listloop:
    lda #3
    sta vect
    ldy #0
    
:   ldx bnk
    lda #vect
    jsr $ff74
    cmp magic,y
    bne nxtbnk2
    iny
    cpy #3
    bne :-

    ;Get length of program name
    ldx bnk
    lda #vect
    ldy #6
    jsr $ff74
    sta len

    ;Indent six spaces
    ldy #6
:   lda #32
    phy
    jsr $ffd2
    ply
    dey
    bne :-

    ;Print name
    lda #$a
    sta vect
    ldy #0

:   cpy len
    beq :+
    ldx bnk
    lda #vect
    jsr $ff74
    phy
    jsr $ffd2
    ply
    iny
    bra :-

:   lda #13
    jsr $ffd2

nxtbnk2:
    inc bnk
    lda bnk
    cmp #8
    bne listloop
    rts

magic:
    .byt "X16"
notfoundmsg:
    .byt 13, "NOT FOUND. LIST OF ROM BASED PROGRAMS:",13, 0