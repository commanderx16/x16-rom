; Patch data in 'YMP' (YM Patch) format.

; The format is simply the values for registers:
; $20, $38, $40, $48, $50, $58, ... , $F0, $F8
; (skips $28 and $30 which are note selections, not patch data)


.export patches_lo, patches_hi

.segment "PATCHDATA"
fm_patches:
YMP_Marimba:
	.byte $DC,$00
	.byte $1B,$67,$61,$31,$21,$17,$1F,$0A
	.byte $DF,$5F,$DE,$DE,$0E,$10,$09,$07
	.byte $00,$05,$07,$04,$FF,$A0,$16,$17

YMP_Finger_Bass_1:
	.byte $F0,$00
	.byte $10,$10,$10,$10,$17,$17,$3F,$0A
	.byte $9E,$9C,$98,$9C,$0E,$04,$0A,$05
	.byte $08,$09,$09,$09,$B6,$C6,$C6,$C6

YMP_Electric_Piano_1:
	.byte $D4,$00
	.byte $31,$6A,$21,$31,$17,$39,$14,$0A
	.byte $9A,$DA,$98,$D8,$0F,$07,$0C,$0C
	.byte $00,$03,$05,$05,$26,$46,$28,$28

YMP_Electric_Piano_2:
	.byte $DC,$00
	.byte $1F,$61,$61,$61,$28,$2A,$1E,$0A
	.byte $9F,$9E,$DB,$5E,$0F,$06,$07,$06
	.byte $08,$0B,$0A,$00,$8A,$F6,$86,$F7

YMP_Electric_Piano_3:
	.byte $FA,$00
	.byte $11,$44,$6C,$61,$21,$31,$47,$0A
	.byte $9C,$9C,$DB,$DA,$04,$04,$09,$03
	.byte $03,$03,$01,$00,$17,$06,$02,$A5

YMP_Choir:
	.byte $C4,$00
	.byte $02,$62,$32,$62,$23,$23,$0A,$0A
	.byte $12,$12,$12,$12,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$06,$06,$06,$06

YMP_Crystal_1:
	.byte $C4,$00
	.byte $07,$67,$02,$62,$18,$1C,$0A,$0A
	.byte $1F,$1F,$1F,$1F,$0C,$0E,$0C,$0C
	.byte $06,$06,$06,$06,$40,$40,$47,$47

YMP_Brass:
	.byte $FA,$00
	.byte $62,$62,$26,$32,$19,$2A,$20,$0A
	.byte $8D,$15,$4F,$52,$06,$07,$08,$01
	.byte $02,$00,$00,$00,$18,$28,$18,$28

YMP_Flute:
	.byte $CC,$00
	.byte $00,$00,$00,$00,$29,$20,$09,$0E
	.byte $1F,$1F,$13,$12,$05,$04,$04,$03
	.byte $02,$02,$01,$0C,$32,$4D,$1D,$7B

YMP_Silent:
	.byte $C7,$00
	.byte $00,$00,$00,$00,$7F,$7F,$7F,$7F
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00

.linecont +

.define M0_PIANO \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Electric_Piano_3, \
	YMP_Silent, \
	YMP_Electric_Piano_1, \
	YMP_Electric_Piano_2, \
	YMP_Silent, \						
	YMP_Silent

.define M1_MALLET \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Marimba, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define M2_ORGAN \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define M3_GUITAR \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define M4_BASS \
	YMP_Silent, \
	YMP_Finger_Bass_1, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define M5_STRINGS \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define M6_ENSEMBLE \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define M7_BRASS \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Brass, \						
	YMP_Silent

.define M8_REED \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define M9_PIPE \
	YMP_Silent, \
	YMP_Flute, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define MA_LEAD \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define MB_PAD \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Choir, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define MC_SYNFX \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Crystal_1, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define MD_ETHNIC \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define ME_PERC \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent

.define MF_SFX \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \						
	YMP_Silent


.define PATCHTABLE \
	YMP_Marimba, \
	YMP_Finger_Bass_1, \
	YMP_Electric_Piano_1, \
	YMP_Electric_Piano_2, \
	YMP_Electric_Piano_3, \
	YMP_Choir, \
	YMP_Crystal_1, \
	YMP_Brass, \
	YMP_Flute, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent, \
	YMP_Silent

.linecont -

; We're still using the old patch table for now
; so it's stuffed at the front

patches_lo:
	.lobytes PATCHTABLE
	.lobytes M0_PIANO
	.lobytes M1_MALLET
	.lobytes M2_ORGAN
	.lobytes M3_GUITAR
	.lobytes M4_BASS
	.lobytes M5_STRINGS
	.lobytes M6_ENSEMBLE
	.lobytes M7_BRASS
	.lobytes M8_REED
	.lobytes M9_PIPE
	.lobytes MA_LEAD
	.lobytes MB_PAD
	.lobytes MC_SYNFX
	.lobytes MD_ETHNIC
	.lobytes ME_PERC
	.lobytes MF_SFX

patches_hi:
	.hibytes PATCHTABLE
	.hibytes M0_PIANO
	.hibytes M1_MALLET
	.hibytes M2_ORGAN
	.hibytes M3_GUITAR
	.hibytes M4_BASS
	.hibytes M5_STRINGS
	.hibytes M6_ENSEMBLE
	.hibytes M7_BRASS
	.hibytes M8_REED
	.hibytes M9_PIPE
	.hibytes MA_LEAD
	.hibytes MB_PAD
	.hibytes MC_SYNFX
	.hibytes MD_ETHNIC
	.hibytes ME_PERC
	.hibytes MF_SFX

