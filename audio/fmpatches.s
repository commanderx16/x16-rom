; Patch data in 'YMP' (YM Patch) format.

; The format is simply the values for registers:
; $20, $38, $40, $48, $50, $58, ... , $F0, $F8
; (skips $28 and $30 which are note selections, not patch data)


.export patches_lo, patches_hi

.segment "PATCHDATA"
fm_patches:
marimba:
	.byte $DC,$00,$1B,$67,$61,$31,$21,$17,$1F,$0A,$DF,$5F,$DE
	.byte $DE,$0E,$10,$09,$07,$00,$05,$07,$04,$FF,$A0,$16,$17

finger_bass_1:
	.byte	$F0,$00,$10,$10,$10,$10,$17,$17
	.byte	$3F,$0A,$9E,$9C,$98,$9C,$0E,$04
	.byte	$0A,$05,$08,$09,$09,$09,$B6,$C6
	.byte	$C6,$C6


.define PATCHTABLE marimba, finger_bass_1, marimba

patches_lo:   .lobytes   PATCHTABLE
patches_hi:   .hibytes   PATCHTABLE
