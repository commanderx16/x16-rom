; Patch data in 'YMP' (YM Patch) format.

; The format is simply the values for registers:
; $20, $38, $40, $48, $50, $58, ... , $F0, $F8
; (skips $28 and $30 which are note selections, not patch data)


.export patches_lo, patches_hi

.segment "PATCHDATA"
fm_patches:
YMP_marimba:
	.byte $DC,$00,$1B,$67,$61,$31,$21,$17,$1F,$0A,$DF,$5F,$DE
	.byte $DE,$0E,$10,$09,$07,$00,$05,$07,$04,$FF,$A0,$16,$17

YMP_finger_bass_1:
	.byte	$F0,$00,$10,$10,$10,$10,$17,$17
	.byte	$3F,$0A,$9E,$9C,$98,$9C,$0E,$04
	.byte	$0A,$05,$08,$09,$09,$09,$B6,$C6
	.byte	$C6,$C6

YMP_Electric_Piano_1:
	.byte	$D4,$00,$31,$6A,$21,$31,$17,$39
	.byte	$14,$0A,$9A,$DA,$98,$D8,$0F,$07
	.byte	$0C,$0C,$00,$03,$05,$05,$26,$46
	.byte	$28,$28

YMP_Electric_Piano_2:
	.byte	$D4,$00,$31,$6A,$21,$31,$17,$39
	.byte	$14,$0A,$9A,$DA,$98,$D8,$0F,$07
	.byte	$0C,$0C,$00,$03,$05,$05,$26,$46
	.byte	$28,$28

YMP_Electric_Piano_3:
	.byte	$D4,$00,$31,$6A,$21,$31,$17,$39
	.byte	$14,$0A,$9A,$DA,$98,$D8,$0F,$07
	.byte	$0C,$0C,$00,$03,$05,$05,$26,$46
	.byte	$28,$28

YMP_Choir:
	.byte	$D4,$00,$31,$6A,$21,$31,$17,$39
	.byte	$14,$0A,$9A,$DA,$98,$D8,$0F,$07
	.byte	$0C,$0C,$00,$03,$05,$05,$26,$46
	.byte	$28,$28

YMP_Crystal_1:
	.byte	$D4,$00,$31,$6A,$21,$31,$17,$39
	.byte	$14,$0A,$9A,$DA,$98,$D8,$0F,$07
	.byte	$0C,$0C,$00,$03,$05,$05,$26,$46
	.byte	$28,$28

YMP_Brass:
	.byte	$D4,$00,$31,$6A,$21,$31,$17,$39
	.byte	$14,$0A,$9A,$DA,$98,$D8,$0F,$07
	.byte	$0C,$0C,$00,$03,$05,$05,$26,$46
	.byte	$28,$28


.define PATCHTABLE YMP_marimba, YMP_finger_bass_1, YMP_Electric_Piano_1, YMP_Electric_Piano_2, YMP_Electric_Piano_3, YMP_Choir, YMP_Crystal_1, YMP_Brass

patches_lo:   .lobytes   PATCHTABLE
patches_hi:   .hibytes   PATCHTABLE
