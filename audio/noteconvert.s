; Routines for converting note values between various standards
; Code by Barry Yost (ZeroByte) 2022
;

; The general form of these routines will be to return YM2151/VERA PSG register
; settings in the .XY registers.
; For YM,  X = KC and Y = KF
; For PSG, X = freq low byte, and Y = freq high byte
;
; Invalid inputs will return 0 in .X and .Y with C flag set.
;
; BAS -> FM / PSG functions will simply ignore the MSB of the octave instead of
; returning an error.
;
;
    .export notecon_fm2bas
    .export notecon_psg2bas
    .export notecon_midi2bas
    .export notecon_freq2bas
    .export notecon_bas2fm
    .export notecon_psg2fm
    .export notecon_freq2fm
    .export notecon_midi2fm
    .export notecon_bas2psg
    .export notecon_fm2psg
    .export notecon_freq2psg
    .export notecon_midi2psg

; inputs: .X = BASIC xxNOTE format.
; returns: (standard) (.Y always returns 0, even though BAS format doesn't use it)
;
; * Function ignores the MSB of the octave value instead of returning an error.
.proc notecon_bas2fm: near
    txa
    and #$7F ; ignore bit7 (octave is only bits 4-6)
    tax
    and #$0F ; mask off the octave
    beq err
    cmp #13
    bcc go
err:
    jmp return_error
go:
    dex
    cmp #10
    bcs inc3
    cmp #7
    bcs inc2
    cmp #4
    bcs inc1
    bra inc0
inc3:
    inx
inc2:
    inx
inc1:
    inx
inc0:
    ldy #0
    clc
    rts
.endproc

; stubs for as-yet unimplemented conversion routines. Just return error until
; they are implemented

notecon_fm2psg:
notecon_freq2bas:
notecon_midi2bas:
notecon_psg2bas:
notecon_fm2bas:
notecon_psg2fm:
notecon_freq2fm:
notecon_midi2fm:
notecon_bas2psg:
notecon_freq2psg:
notecon_midi2psg:

; save some code size by having a generic "return error" routine
.proc return_error: near
    ldx #0
    ldy #0
    sec
    rts
.endproc
