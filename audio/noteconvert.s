; Routines for converting note values between various standards
; Code by MooingLemur, Barry Yost (a.k.a. ZeroByte) 2022
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
	.export notecon_bas2midi
	.export notecon_fm2midi
	.export notecon_freq2midi
	.export notecon_psg2midi
	.export notecon_bas2psg
	.export notecon_fm2psg
	.export notecon_freq2psg
	.export notecon_midi2psg

	.import psgfreqtmp

	.import kfdelta2_h,kfdelta3_h,kfdelta4_h
	.import kfdelta5_h,kfdelta6_h,kfdelta7_h
	.import kfdelta2_l,kfdelta3_l,kfdelta4_l
	.import kfdelta5_l,kfdelta6_l,kfdelta7_l
	.import midi2psg_h,midi2psg_l
	.import midi2ymkc
	.import ymkc2midi

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

.proc notecon_fm2midi: near
	; inputs: .X = YM2151 KC
	; outputs: .A = MIDI note
	lda ymkc2midi,x
	rts
.endproc

.proc notecon_midi2fm: near
	; inputs: .X = MIDI note
	; outputs: .A = YM2151 KC
	lda midi2ymkc,x
	rts
.endproc

.proc notecon_midi2psg: near
	; inputs .X = midi note (0-127)
	; clobbers: .A
	; outputs .X .Y = low, high of VERA PSG frequency
	lda midi2psg_l,x
	ldy midi2psg_h,x
	tax
	rts
.endproc

.proc notecon_fm2psg: near
	; inputs: .X = YM2151 KC, .Y = YM2151 KF
	; clobbers: .A
	; outputs: .X .Y = low, high of VERA PSG frequency
	lda ymkc2midi,x
	tax
	lda midi2psg_l,x
	sta psgfreqtmp ; lay down the base psg freq in RAM
	lda midi2psg_h,x
	sta psgfreqtmp+1

	lda ram_bank
	pha
	stz ram_bank
test7:
	; Test bit 7 in KF and adjust freq if set
	tya ; KF
	bne :+
	jmp end ; short circuit if KF is zero
:	and #%10000000 
	beq test6
	lda kfdelta7_l,x
	clc
	adc psgfreqtmp
	sta psgfreqtmp
	lda kfdelta7_h,x
	adc psgfreqtmp+1
	sta psgfreqtmp+1
test6:
	; Test bit 6 in KF and adjust freq if set
	tya ; KF
	and #%01000000 
	beq test5
	lda kfdelta6_l,x
	clc
	adc psgfreqtmp
	sta psgfreqtmp
	lda kfdelta6_h,x
	adc psgfreqtmp+1
	sta psgfreqtmp+1
test5:
	; Test bit 5 in KF and adjust freq if set
	tya ; KF
	and #%00100000 
	beq test4
	lda kfdelta5_l,x
	clc
	adc psgfreqtmp
	sta psgfreqtmp
	lda kfdelta5_h,x
	adc psgfreqtmp+1
	sta psgfreqtmp+1
test4:
	; Test bit 4 in KF and adjust freq if set
	tya ; KF
	and #%00010000 
	beq test3
	lda kfdelta4_l,x
	clc
	adc psgfreqtmp
	sta psgfreqtmp
	lda kfdelta4_h,x
	adc psgfreqtmp+1
	sta psgfreqtmp+1
test3:
	; Test bit 3 in KF and adjust freq if set
	tya ; KF
	and #%00001000 
	beq test2
	lda kfdelta3_l,x
	clc
	adc psgfreqtmp
	sta psgfreqtmp
	lda kfdelta3_h,x
	adc psgfreqtmp+1
	sta psgfreqtmp+1
test2:
	; Test bit 2 in KF and adjust freq if set
	tya ; KF
	and #%00000100 
	beq end
	lda kfdelta2_l,x
	clc
	adc psgfreqtmp
	sta psgfreqtmp
	lda kfdelta2_h,x
	adc psgfreqtmp+1
	sta psgfreqtmp+1
end:
	ldx psgfreqtmp
	ldy psgfreqtmp+1
	pla
	sta ram_bank
	rts
.endproc


; stubs for as-yet unimplemented conversion routines. Just return error until
; they are implemented

notecon_freq2bas:
notecon_midi2bas:
notecon_psg2bas:
notecon_fm2bas:
notecon_psg2fm:
notecon_freq2fm:
notecon_bas2psg:
notecon_freq2psg:
notecon_psg2midi:
notecon_freq2midi:
notecon_bas2midi:

; save some code size by having a generic "return error" routine
.proc return_error: near
	ldx #0
	ldy #0
	sec
	rts
.endproc
