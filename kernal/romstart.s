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
;Output: C=1, program not found
;        C=0, program found

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
    
    tsx             ;save current bank on stack
    lda $1
    sta $0101,x
    
    stz jmpfr+1     ;set call address, always $c000
    lda #$c0
    sta jmpfr+2

    lda bnk         ;set ROM bank
    rts jsrfar3
    clc

nxtbnk:
    inc bnk
    lda bnk
    cmp #32
    bne loop

notfound:
    sec
    rts

magic:
    .byt "X16"