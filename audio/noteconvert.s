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

.include "io.inc" 
	
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

.import psgfreqtmp, hztmp

.import kfdelta2_h, kfdelta3_h, kfdelta4_h
.import kfdelta5_h, kfdelta6_h, kfdelta7_h
.import kfdelta2_l, kfdelta3_l, kfdelta4_l
.import kfdelta5_l, kfdelta6_l, kfdelta7_l
.import midi2psg_h, midi2psg_l
.import midi2ymkc
.import ymkc2midi
.import midi2bas
.import bas2midi

.proc notecon_bas2fm: near
	; inputs: .X = BASIC oct/note
	; outputs: .A = .X = YM2151 KC
	txa
	and #$7F
	tax
	lda bas2midi,x
	cmp #$FF
	beq error
	tax
	lda midi2ymkc,x
	cmp #$FF
	beq error
	tax
	; carry is clear
	rts
error:
	jmp return_error
.endproc

.proc notecon_fm2bas: near
	; inputs: .X = YM2151 KC
	; outputs: .A = .X = BASIC oct/note
	txa
	and #$7F
	tax
	lda ymkc2midi,x
	tax
	lda midi2bas,x
	cmp #$FF
	beq error
	tax
	; carry is clear
	rts
error:
	jmp return_error
.endproc
	
.proc notecon_bas2psg: near
	; inputs: .X = BASIC oct/note (also process .Y as KF)
	; clobbers: .A
	; outputs .X .Y = low, high of VERA PSG frequency
	txa
	and #$7F
	tax
	lda bas2midi,x
	cmp #$FF
	beq error
	tax
	jmp notecon_midi2psg
error:
	jmp return_error
.endproc

.proc notecon_midi2bas: near
	; inputs: .A = MIDI note
	; outputs: .A = .X = BASIC oct/note
	and #$7F
	tax
	lda bas2midi,x
	tax
	clc
	rts
.endproc

.proc notecon_bas2midi: near
	; inputs: .X = BASIC oct/note
	; outputs: .A = .X = MIDI note
	txa
	and #$7F
	tax
	lda bas2midi,x
	cmp #$FF
	beq error
	tax
	; carry is already clear
	rts
error:
	jmp return_error
.endproc

.proc notecon_fm2midi: near
	; inputs: .X = YM2151 KC
	; outputs: .A = .X = MIDI note
	txa
	and #$7F
	tax
	lda ymkc2midi,x
	tax
	clc
	rts
.endproc

.proc notecon_midi2fm: near
	; inputs: .X = MIDI note
	; outputs: .A = .X = YM2151 KC
	txa
	and #$7F
	tax
	lda midi2ymkc,x
	cmp #$FF
	beq error
	; carry is already clear
	tax
	rts
error:
	jmp return_error
.endproc

.proc notecon_fm2psg: near
	; inputs: .X = YM2151 KC, .Y = YM2151 KF
	; clobbers: .A
	; outputs: .X .Y = low, high of VERA PSG frequency
	txa
	and #$7F
	tax

	lda ymkc2midi,x
	tax
	; fall through to notecon_midi2psg

.endproc

.proc notecon_midi2psg: near
	; inputs .X = midi note (0-127), .Y = YM2151 KF
	; clobbers: .A
	; outputs .X .Y = low, high of VERA PSG frequency
	txa
	and #$7F
	tax

	lda ram_bank
	pha
	stz ram_bank

	lda midi2psg_l,x
	sta psgfreqtmp ; lay down the base psg freq in RAM
	lda midi2psg_h,x
	sta psgfreqtmp+1

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
	clc
	rts
.endproc

.proc notecon_freq2psg: near
	; inputs: .X .Y = low, high of Hz frequency
	; clobbers: .A
	; outputs: .X .Y = low, high of VERA PSG frequency

	MAX_HZ = 24411

	cpy #(>MAX_HZ) 
	bcc pass          ; if high byte < that of MAX_HZ, we're clear
	beq check         ; if high byte = that of MAX_HZ, we check low byte
	jmp return_error  ; if high byte > that of MAX_HZ, error
check:
	cpx #(<MAX_HZ+1) 
	bcc pass         ; if low byte of freq is <= that of MAX_HZ, fine
	jmp return_error ; if low byte of freq is >  that of MAX_HZ, error
pass:
	lda ram_bank
	pha
	stz ram_bank

	stx psgfreqtmp
	stx hztmp
	sty psgfreqtmp+1
	sty hztmp+1

	; we want to multiply by 2.68435456
	; aka add 1.68435456x the original value

	; multiply by 2
	asl psgfreqtmp
	rol psgfreqtmp+1
	; remaining to add: 0.68435456x

	; add 0.5x
	jsr add_div2
	; remaining to add: 0.18435456x

	; add 0.125x
	jsr add_div4
	; remaining to add: 0.05935456x

	; add 0.03125x
	jsr add_div4
	; remaining to add: 0.02810456x

	; add 0.015625x
	jsr add_div2
	; remaining to add: 0.01247956x

	; add 0.0078125x
	jsr add_div2
	; remaining to add: 0.00466706x

	; add 0.00390625x
	jsr add_div2
	; remaining to add: 0.00076081x

	; add 0.000976562x (a slight overshoot)
	jsr add_div4
	; overshot by: 0.000215752x or 0.02%
end:
	ldx psgfreqtmp
	ldy psgfreqtmp+1
	pla
	sta ram_bank
	clc
	rts
add_div4:
	lsr hztmp+1
	ror hztmp
add_div2:
	lsr hztmp+1
	ror hztmp
add:
	lda hztmp
	; no clc here because rounding up seems to help accuracy
	adc psgfreqtmp
	sta psgfreqtmp
	lda hztmp+1
	adc psgfreqtmp+1
	sta psgfreqtmp+1
	rts
.endproc

.proc notecon_psg2midi: near
	; inputs: .X .Y = low, high of VERA PSG frequency
	; outputs: .X = midi note, .Y = KF

	lda ram_bank
	pha
	stz ram_bank

	stx psgfreqtmp
	sty psgfreqtmp+1

	ldx #0
mloop:
	lda psgfreqtmp+1
	cmp midi2psg_h,x
	beq mlow
	bcs mnext
	bra mpassed
mlow:
	lda psgfreqtmp
	cmp midi2psg_l,x
	beq mfound
	bcs mnext
	bra mpassed
mnext:
	inx
	bpl :+
	jmp error
:	bra mloop
mpassed:
	dex
	bpl :+
	jmp error
:
mfound:
	lda psgfreqtmp
	sec
	sbc midi2psg_l,x
	sta psgfreqtmp
	lda psgfreqtmp+1
	sbc midi2psg_h,x
	sta psgfreqtmp+1

	; Now the delta is in psgfreqtmp.  Find the KF.
	stz hztmp
b7:
	; bit 7
	lda psgfreqtmp
	cmp kfdelta7_l,x
	lda psgfreqtmp+1
	sbc kfdelta7_h,x
	bcc b6
	lda psgfreqtmp
	sbc kfdelta7_l,x
	sta psgfreqtmp
	lda psgfreqtmp+1
	sbc kfdelta7_h,x
	sta psgfreqtmp+1
	lda hztmp
	ora #$80
	sta hztmp
b6:
	; bit 6
	lda psgfreqtmp
	cmp kfdelta6_l,x
	lda psgfreqtmp+1
	sbc kfdelta6_h,x
	bcc b5
	lda psgfreqtmp
	sbc kfdelta6_l,x
	sta psgfreqtmp
	lda psgfreqtmp+1
	sbc kfdelta6_h,x
	sta psgfreqtmp+1
	lda hztmp
	ora #$40
	sta hztmp
b5:
	; bit 5
	lda psgfreqtmp
	cmp kfdelta5_l,x
	lda psgfreqtmp+1
	sbc kfdelta5_h,x
	bcc b4
	lda psgfreqtmp
	sbc kfdelta5_l,x
	sta psgfreqtmp
	lda psgfreqtmp+1
	sbc kfdelta5_h,x
	sta psgfreqtmp+1
	lda hztmp
	ora #$20
	sta hztmp
b4:
	; bit 4
	lda psgfreqtmp
	cmp kfdelta4_l,x
	lda psgfreqtmp+1
	sbc kfdelta4_h,x
	bcc b3
	lda psgfreqtmp
	sbc kfdelta4_l,x
	sta psgfreqtmp
	lda psgfreqtmp+1
	sbc kfdelta4_h,x
	sta psgfreqtmp+1
	lda hztmp
	ora #$10
	sta hztmp
b3:
	; bit 3
	lda psgfreqtmp
	cmp kfdelta3_l,x
	lda psgfreqtmp+1
	sbc kfdelta3_h,x
	bcc b2
	lda psgfreqtmp
	sbc kfdelta3_l,x
	sta psgfreqtmp
	lda psgfreqtmp+1
	sbc kfdelta3_h,x
	sta psgfreqtmp+1
	lda hztmp
	ora #$08
	sta hztmp
b2:
	; bit 2
	lda psgfreqtmp
	cmp kfdelta2_l,x
	lda psgfreqtmp+1
	sbc kfdelta2_h,x
	bcc b1
	lda psgfreqtmp
	sbc kfdelta2_l,x
	sta psgfreqtmp
	lda psgfreqtmp+1
	sbc kfdelta2_h,x
	sta psgfreqtmp+1
	lda hztmp
	ora #$04
	sta hztmp
b1:
	ldy hztmp
	clc
	bra end
error:
	ldx #0
	ldy #0
	sec
end:
	pla
	sta ram_bank
	rts
.endproc

.proc notecon_freq2fm: near
	; inputs: .X .Y = low, high of Hz frequency
	; clobbers: .A
	; outputs: .X = KC, .Y = KF
	jsr notecon_freq2midi
	bcs error
	jmp notecon_midi2fm
error:
	jmp return_error
.endproc

.proc notecon_psg2fm: near
	; inputs: .X .Y = low, high of PSG frequency
	; clobbers: .A
	; outputs: .X = KC, .Y = KF
	jsr notecon_psg2midi
	bcs error
	jmp notecon_midi2fm
error:
	jmp return_error
.endproc

.proc notecon_psg2bas: near
	; inputs: .X .Y = low, high of PSG frequency
	; clobbers: .A
	; outputs: .X = BASIC oct/note, .Y = KF
	jsr notecon_psg2midi
	bcs error
	jmp notecon_midi2bas
error:
	jmp return_error
.endproc

.proc notecon_freq2midi: near
	; inputs: .X .Y = low, high of Hz frequency
	; clobbers: .A
	; outputs: .X = MIDI note, .Y = KF
	jsr notecon_freq2psg
	bcs error
	jmp notecon_psg2midi
error:
	jmp return_error
.endproc

.proc notecon_freq2bas: near
	; inputs: .X .Y = low, high of Hz frequency
	; clobbers: .A
	; outputs: .X = BASIC oct/note, .Y = KF
	jsr notecon_freq2midi
	bcs error
	jmp notecon_midi2bas
error:
	jmp return_error
.endproc

; save some code size by having a generic "return error" routine
.proc return_error: near
	ldx #0
	ldy #0
	sec
	rts
.endproc
