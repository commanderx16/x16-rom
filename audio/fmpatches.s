
; 000 Acoustic Piano
M000_Acoustic_Piano:
	.byte $C4,$00
	.byte $59,$51,$01,$01,$35,$18,$17,$00
	.byte $1F,$1F,$9F,$9F,$15,$01,$09,$08
	.byte $00,$00,$00,$00,$33,$51,$FA,$F9

; 001 Bright Acoustic Piano
M001_Bright_Acoustic_Piano:
	.byte $C4,$00
	.byte $59,$53,$01,$01,$35,$18,$17,$00
	.byte $1F,$1F,$9F,$9F,$15,$01,$09,$08
	.byte $00,$00,$00,$00,$33,$51,$FA,$F9

; 002 Electric Grand Piano
M002_Electric_Grand_Piano:
	.byte $F9,$00
	.byte $11,$66,$44,$61,$21,$2B,$2F,$00
	.byte $1F,$1F,$1F,$1F,$08,$04,$0A,$09
	.byte $00,$00,$00,$00,$F3,$F1,$F4,$F9

; 003 Honky-Tonk Piano
M003_Honky_Tonk_Piano:
	.byte $F4,$00
	.byte $11,$73,$01,$61,$19,$2C,$0D,$00
	.byte $9F,$1F,$1F,$9F,$07,$00,$0F,$1E
	.byte $0E,$07,$0E,$0B,$14,$07,$0C,$0C

; 004 Electric Piano 1
M004_Electric_Piano_1:
	.byte $C4,$00
	.byte $5E,$51,$01,$01,$39,$35,$17,$00
	.byte $1F,$1F,$1F,$1F,$15,$01,$09,$08
	.byte $00,$00,$00,$00,$33,$51,$FA,$F9

; 005 Electric Piano 2
M005_Electric_Piano_2:
	.byte $FC,$00
	.byte $3B,$31,$3C,$31,$26,$21,$1E,$00
	.byte $1F,$1F,$1F,$1F,$00,$06,$0F,$08
	.byte $00,$00,$00,$00,$F3,$B1,$F8,$F9

; 006 Harpsichord
M006_Harpsichord:
	.byte $C0,$00
	.byte $3B,$36,$35,$31,$0D,$1F,$16,$00
	.byte $1F,$1F,$1F,$1F,$18,$05,$1C,$09
	.byte $00,$00,$06,$00,$67,$11,$16,$F9

; 007 Clavinet
M007_Clavinet:
	.byte $F8,$00
	.byte $31,$32,$31,$31,$20,$13,$16,$00
	.byte $1F,$1F,$1F,$1F,$17,$00,$00,$09
	.byte $08,$00,$00,$00,$43,$B1,$F4,$FA

; 008 Celesta
M008_Celesta:
	.byte $C4,$00
	.byte $56,$3A,$36,$31,$28,$3C,$0C,$00
	.byte $1F,$1F,$1F,$1F,$1A,$0B,$1A,$0B
	.byte $00,$00,$00,$00,$FB,$B1,$FB,$F7

; 009 Glockenspiel
M009_Glockenspiel:
	.byte $CC,$00
	.byte $5A,$5A,$00,$01,$7F,$18,$7F,$00
	.byte $1F,$1F,$1F,$1F,$0D,$11,$04,$0F
	.byte $00,$00,$00,$0A,$F3,$F1,$F4,$45

; 010 Music Box
M010_Music_Box:
	.byte $FC,$00
	.byte $55,$51,$01,$01,$16,$51,$0E,$02
	.byte $1F,$1F,$1F,$1F,$0F,$13,$11,$17
	.byte $00,$00,$00,$00,$F6,$B4,$FC,$FD

; 011 Vibraphone
; Instrument is affected by LFO
M011_Vibraphone:
	.byte $C4,$03
	.byte $35,$35,$34,$31,$2D,$50,$0A,$04
	.byte $1F,$1F,$1F,$1F,$0E,$0A,$0D,$8A
	.byte $06,$00,$10,$00,$AB,$B1,$FB,$F8

; 012 Marimba
M012_Marimba:
	.byte $FD,$00
	.byte $58,$51,$08,$01,$1E,$11,$18,$02
	.byte $1F,$1F,$1F,$1F,$14,$0C,$1A,$0F
	.byte $00,$00,$00,$00,$D3,$F6,$FD,$F9

; 013 Xylophone
M013_Xylophone:
	.byte $E5,$00
	.byte $58,$51,$09,$01,$14,$00,$1B,$0B
	.byte $1F,$1F,$1F,$1F,$16,$0F,$1A,$0F
	.byte $00,$00,$00,$00,$DD,$FB,$FD,$FB

; 014 Tubular Bells
M014_Tubular_Bells:
	.byte $D4,$00
	.byte $19,$3E,$62,$32,$10,$20,$0E,$0E
	.byte $9F,$9F,$9F,$9F,$04,$07,$07,$08
	.byte $00,$00,$00,$00,$F1,$E1,$F4,$E3

; 015 Dulcimer
M015_Dulcimer:
	.byte $C0,$00
	.byte $33,$31,$33,$31,$21,$26,$1B,$02
	.byte $1F,$1F,$1F,$1F,$11,$04,$07,$09
	.byte $09,$00,$00,$00,$23,$B5,$F3,$F5

; 016 Drawbar Organ
; Instrument is affected by LFO
M016_Drawbar_Organ:
	.byte $C7,$60
	.byte $38,$32,$34,$31,$13,$0C,$11,$05
	.byte $1F,$1F,$1F,$1F,$0D,$0D,$0D,$0D
	.byte $00,$00,$00,$00,$1B,$1B,$1B,$1B

; 017 Percussive Organ
; Instrument is affected by LFO
M017_Percussive_Organ:
	.byte $C7,$60
	.byte $36,$32,$33,$31,$10,$09,$0D,$05
	.byte $1F,$1F,$1F,$1F,$10,$0D,$0D,$0D
	.byte $00,$00,$00,$00,$5B,$1B,$1B,$1B

; 018 Rock Organ
; Instrument is affected by LFO
M018_Rock_Organ:
	.byte $C2,$60
	.byte $5D,$41,$02,$31,$36,$23,$1E,$02
	.byte $17,$1F,$1F,$1F,$1F,$00,$00,$00
	.byte $00,$00,$00,$00,$FE,$B1,$F4,$FB

; 019 Church Organ
M019_Church_Organ:
	.byte $C4,$00
	.byte $12,$18,$52,$58,$22,$1E,$0B,$0D
	.byte $1F,$1F,$1F,$1F,$09,$89,$09,$09
	.byte $00,$00,$00,$00,$00,$00,$06,$06

; 020 Reed Organ
M020_Reed_Organ:
	.byte $FC,$00
	.byte $33,$33,$31,$31,$21,$21,$09,$12
	.byte $1F,$1F,$1F,$1F,$00,$00,$18,$18
	.byte $00,$00,$00,$00,$45,$45,$07,$07

; 021 Accordion
M021_Accordion:
	.byte $D4,$00
	.byte $44,$41,$72,$01,$12,$0C,$13,$06
	.byte $1F,$1F,$10,$10,$00,$00,$0A,$0A
	.byte $00,$00,$00,$00,$03,$01,$1B,$1B

; 022 Harmonica
M022_Harmonica:
	.byte $F8,$00
	.byte $32,$31,$32,$31,$32,$16,$1B,$02
	.byte $1F,$1F,$1F,$10,$00,$00,$00,$0C
	.byte $00,$00,$00,$00,$06,$06,$06,$1B

; 023 Bandoneon
M023_Bandoneon:
	.byte $E4,$00
	.byte $34,$31,$32,$31,$1D,$10,$0B,$06
	.byte $1F,$1F,$10,$10,$00,$00,$0A,$0A
	.byte $00,$00,$00,$00,$03,$01,$1B,$1B

; 024 Acoustic Nylon Guitar
M024_Acoustic_Nylon_Guitar:
	.byte $C2,$00
	.byte $68,$62,$65,$61,$2D,$26,$28,$00
	.byte $19,$1F,$1F,$1F,$1C,$07,$08,$0A
	.byte $00,$00,$00,$00,$FF,$F1,$F4,$F9

; 025 Acoustic Steel Guitar
M025_Acoustic_Steel_Guitar:
	.byte $C2,$00
	.byte $68,$61,$63,$61,$27,$28,$18,$00
	.byte $19,$1F,$1F,$1F,$1C,$05,$07,$0A
	.byte $00,$00,$00,$00,$FF,$91,$F4,$F9

; 026 Electric Jazz Guitar
M026_Electric_Jazz_Guitar:
	.byte $FA,$00
	.byte $31,$31,$24,$31,$24,$2B,$2D,$00
	.byte $17,$1F,$1F,$1F,$15,$00,$00,$0A
	.byte $00,$00,$00,$00,$FF,$F1,$F4,$F9

; 027 Electric Clean Guitar
M027_Electric_Clean_Guitar:
	.byte $F8,$00
	.byte $29,$31,$21,$31,$2E,$1E,$0F,$00
	.byte $1F,$1F,$1F,$1F,$10,$04,$08,$09
	.byte $00,$00,$00,$00,$F9,$B1,$F4,$FB

; 028 Electric Muted Guitar
M028_Electric_Muted_Guitar:
	.byte $E2,$00
	.byte $54,$51,$01,$01,$20,$21,$32,$00
	.byte $1C,$1F,$1F,$1F,$15,$02,$03,$0A
	.byte $00,$00,$00,$00,$FF,$B1,$F4,$F9

; 029 Electric Overdriven Guitar
M029_Electric_Overdriven_Guitar:
	.byte $FA,$00
	.byte $33,$11,$32,$33,$10,$16,$21,$00
	.byte $1F,$1F,$1F,$1F,$17,$00,$00,$07
	.byte $00,$00,$00,$00,$FF,$B1,$F4,$FB

; 030 Electric Distorted Guitar
M030_Electric_Distorted_Guitar:
	.byte $FA,$00
	.byte $33,$11,$31,$33,$09,$0B,$1A,$00
	.byte $1F,$1F,$1F,$1F,$17,$00,$00,$07
	.byte $00,$00,$00,$00,$FF,$B1,$F4,$FB

; 031 Electric Guitar Harmonics
M031_Electric_Guitar_Harmonics:
	.byte $FA,$00
	.byte $62,$34,$38,$6A,$10,$16,$21,$0A
	.byte $1F,$1F,$1F,$1F,$17,$00,$00,$06
	.byte $00,$00,$00,$00,$FF,$B1,$F4,$FB

; 032 Acoustic Bass
M032_Acoustic_Bass:
	.byte $E0,$00
	.byte $51,$50,$01,$00,$3B,$19,$0F,$00
	.byte $1F,$1F,$1F,$1F,$0F,$0C,$16,$09
	.byte $00,$00,$00,$00,$5E,$6E,$6E,$FE

; 033 Electric Finger Bass
M033_Electric_Finger_Bass:
	.byte $C0,$00
	.byte $63,$61,$62,$61,$1F,$18,$2E,$00
	.byte $1F,$1F,$1F,$1F,$0F,$0A,$0D,$04
	.byte $00,$00,$00,$00,$1B,$1A,$1A,$FB

; 034 Electric Picked Bass
M034_Electric_Picked_Bass:
	.byte $C0,$00
	.byte $65,$61,$63,$61,$18,$21,$21,$00
	.byte $1F,$1F,$1F,$1F,$12,$0A,$12,$04
	.byte $01,$03,$02,$00,$3B,$1A,$1A,$FB

; 035 Fretless Bass
M035_Fretless_Bass:
	.byte $C0,$00
	.byte $21,$21,$31,$31,$15,$1A,$3C,$00
	.byte $1F,$1F,$1F,$1F,$00,$00,$00,$04
	.byte $00,$00,$00,$00,$F3,$B7,$F6,$FC

; 036 Slap Bass 1
M036_Slap_Bass_1:
	.byte $C8,$00
	.byte $69,$60,$65,$61,$1A,$11,$29,$00
	.byte $1F,$1F,$1F,$1F,$16,$07,$0A,$08
	.byte $07,$07,$07,$08,$93,$13,$13,$88

; 037 Slap Bass 2
M037_Slap_Bass_2:
	.byte $DB,$00
	.byte $69,$60,$65,$61,$07,$11,$25,$00
	.byte $1F,$1F,$1F,$1F,$13,$09,$0A,$08
	.byte $07,$04,$07,$08,$83,$43,$13,$88

; 038 Synth Bass 1
M038_Synth_Bass_1:
	.byte $F9,$00
	.byte $30,$30,$30,$30,$1B,$11,$0A,$05
	.byte $1F,$1F,$1F,$1F,$13,$06,$1D,$00
	.byte $00,$00,$00,$00,$A2,$22,$E2,$68

; 039 Synth Bass 2
M039_Synth_Bass_2:
	.byte $F9,$00
	.byte $30,$30,$30,$30,$1B,$07,$0A,$05
	.byte $1F,$1F,$1F,$1F,$13,$06,$1D,$00
	.byte $00,$00,$00,$00,$A2,$22,$E2,$68

; 040 Violin
; Instrument is affected by LFO
M040_Violin:
	.byte $C3,$60
	.byte $58,$02,$41,$42,$2D,$13,$1A,$05
	.byte $1F,$1F,$1F,$0E,$00,$0E,$00,$00
	.byte $00,$00,$00,$00,$00,$60,$00,$0A

; 041 Viola
; Instrument is affected by LFO
M041_Viola:
	.byte $C3,$60
	.byte $58,$02,$41,$42,$3B,$13,$1A,$05
	.byte $1F,$1F,$1F,$0E,$00,$0E,$00,$00
	.byte $00,$00,$00,$00,$00,$60,$00,$0A

; 042 Cello
; Instrument is affected by LFO
M042_Cello:
	.byte $C3,$63
	.byte $58,$54,$00,$02,$3D,$38,$1A,$02
	.byte $1F,$1F,$1F,$0F,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$09

; 043 Contrabass
; Instrument is affected by LFO
M043_Contrabass:
	.byte $C3,$43
	.byte $55,$54,$00,$01,$3A,$3A,$1A,$02
	.byte $1F,$1F,$1F,$13,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$0A

; 044 Tremolo Strings
; Instrument is affected by LFO
M044_Tremolo_Strings:
	.byte $FC,$02
	.byte $51,$13,$51,$11,$1C,$1B,$0B,$09
	.byte $13,$14,$10,$0E,$09,$0B,$8B,$90
	.byte $04,$04,$04,$04,$17,$17,$17,$27

; 045 Pizzicato Strings
M045_Pizzicato_Strings:
	.byte $C2,$00
	.byte $35,$52,$13,$31,$2A,$1C,$2C,$00
	.byte $9F,$1F,$1F,$5F,$17,$15,$14,$10
	.byte $05,$00,$0A,$13,$69,$A9,$27,$39

; 046 Harp
M046_Harp:
	.byte $C2,$00
	.byte $35,$32,$33,$31,$2E,$31,$2C,$00
	.byte $9F,$1F,$1F,$9F,$17,$15,$14,$0F
	.byte $05,$00,$0A,$06,$69,$A9,$27,$34

; 047 Timpani
M047_Timpani:
	.byte $DD,$00
	.byte $10,$21,$61,$61,$27,$00,$04,$02
	.byte $1F,$1F,$1F,$1F,$00,$0A,$0A,$0A
	.byte $D0,$0F,$0F,$0F,$0A,$0B,$2A,$1A

; 048 String Ensemble 1
; Instrument is affected by LFO
M048_String_Ensemble_1:
	.byte $EC,$30
	.byte $31,$32,$71,$01,$0B,$3C,$0E,$11
	.byte $15,$15,$0E,$0F,$06,$00,$00,$06
	.byte $00,$00,$00,$04,$67,$06,$0C,$07

; 049 String Ensemble 2
; Instrument is affected by LFO
M049_String_Ensemble_2:
	.byte $EC,$30
	.byte $31,$32,$71,$01,$0D,$3C,$0E,$11
	.byte $15,$12,$0D,$11,$04,$00,$00,$06
	.byte $00,$00,$00,$04,$07,$06,$0C,$07

; 050 Synth Strings 1
; Instrument is affected by LFO
M050_Synth_Strings_1:
	.byte $FC,$30
	.byte $51,$11,$51,$11,$1F,$1B,$0B,$09
	.byte $13,$14,$10,$0E,$04,$00,$0B,$10
	.byte $00,$04,$04,$04,$37,$17,$17,$27

; 051 Synth Strings 2
; Instrument is affected by LFO
M051_Synth_Strings_2:
	.byte $FC,$30
	.byte $51,$11,$51,$14,$1C,$18,$0B,$09
	.byte $13,$14,$10,$0E,$04,$00,$0B,$10
	.byte $00,$04,$04,$04,$07,$17,$17,$27

; 052 Choir Aahs
; Instrument is affected by LFO
M052_Choir_Aahs:
	.byte $C4,$60
	.byte $31,$30,$31,$30,$18,$27,$0A,$13
	.byte $1F,$1F,$0B,$0B,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$0F,$06,$06

; 053 Doo
M053_Doo:
	.byte $E6,$00
	.byte $38,$32,$31,$31,$1D,$1A,$05,$00
	.byte $1F,$1F,$1F,$1F,$17,$00,$00,$0D
	.byte $00,$00,$00,$00,$F0,$7F,$0F,$7F

; 054 Synth Choir
; Instrument is affected by LFO
M054_Synth_Choir:
	.byte $C4,$60
	.byte $31,$30,$31,$30,$25,$25,$0A,$13
	.byte $1F,$1F,$0B,$0B,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$0F,$0F,$0F,$0F

; 055 Orch Hit
M055_Orch_Hit:
	.byte $FC,$00
	.byte $02,$62,$32,$64,$16,$00,$00,$00
	.byte $1F,$1F,$1F,$1F,$00,$14,$0E,$0F
	.byte $00,$00,$00,$00,$00,$FC,$F8,$FA

; 056 Trumpet
; Instrument is affected by LFO
M056_Trumpet:
	.byte $FC,$60
	.byte $31,$31,$31,$31,$1D,$1D,$00,$08
	.byte $14,$14,$13,$13,$06,$06,$06,$06
	.byte $00,$00,$00,$00,$68,$68,$08,$08

; 057 Trombone
M057_Trombone:
	.byte $F5,$00
	.byte $31,$31,$54,$31,$1A,$00,$35,$00
	.byte $14,$19,$16,$18,$05,$15,$19,$08
	.byte $00,$00,$00,$00,$11,$19,$29,$2A

; 058 Tuba
M058_Tuba:
	.byte $FD,$00
	.byte $31,$61,$31,$61,$1D,$00,$00,$00
	.byte $0D,$0E,$10,$0F,$1F,$1F,$1F,$1F
	.byte $0B,$00,$00,$00,$07,$08,$09,$08

; 059 Muted Trumpet
; Instrument is affected by LFO
M059_Muted_Trumpet:
	.byte $FC,$50
	.byte $31,$36,$31,$31,$23,$1D,$0A,$0B
	.byte $14,$14,$13,$13,$06,$06,$06,$06
	.byte $00,$00,$00,$00,$68,$68,$08,$08

; 060 French Horn
M060_French_Horn:
	.byte $F4,$00
	.byte $31,$31,$31,$31,$25,$22,$00,$00
	.byte $1F,$5F,$10,$15,$05,$0F,$09,$09
	.byte $00,$00,$00,$00,$41,$25,$47,$47

; 061 Brass Section
M061_Brass_Section:
	.byte $F5,$00
	.byte $21,$20,$11,$34,$18,$11,$0A,$0F
	.byte $90,$95,$9B,$94,$00,$00,$05,$00
	.byte $01,$02,$02,$02,$47,$17,$36,$08

; 062 Synth Brass 1
M062_Synth_Brass_1:
	.byte $FA,$00
	.byte $61,$51,$61,$01,$2A,$2A,$10,$02
	.byte $9C,$13,$5A,$14,$08,$04,$0A,$09
	.byte $00,$00,$06,$00,$03,$B0,$24,$F9

; 063 Synth Brass 2
M063_Synth_Brass_2:
	.byte $FD,$02
	.byte $01,$60,$01,$02,$20,$0A,$12,$13
	.byte $13,$1F,$1F,$1F,$08,$08,$00,$00
	.byte $00,$1F,$00,$00,$2F,$FF,$0F,$0F

; 064 Soprano Sax
; Instrument is affected by LFO
M064_Soprano_Sax:
	.byte $FD,$60
	.byte $51,$34,$01,$31,$1A,$19,$18,$00
	.byte $17,$18,$1F,$13,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$F0,$4B,$F6,$F9

; 065 Alto Sax
; Instrument is affected by LFO
M065_Alto_Sax:
	.byte $FD,$60
	.byte $51,$34,$01,$31,$17,$19,$18,$00
	.byte $17,$0D,$0F,$12,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$F0,$4B,$F6,$F9

; 066 Tenor Sax
; Instrument is affected by LFO
M066_Tenor_Sax:
	.byte $FD,$60
	.byte $51,$34,$01,$31,$1D,$19,$18,$00
	.byte $1A,$14,$19,$14,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$F0,$4B,$F6,$F9

; 067 Baritone Sax
M067_Baritone_Sax:
	.byte $EB,$00
	.byte $30,$32,$30,$30,$0F,$1B,$12,$00
	.byte $1F,$13,$1F,$13,$00,$09,$00,$08
	.byte $17,$00,$00,$00,$50,$0C,$00,$0B

; 068 Oboe
; Instrument is affected by LFO
M068_Oboe:
	.byte $DC,$50
	.byte $31,$31,$31,$31,$12,$12,$00,$0A
	.byte $1F,$1F,$16,$1D,$00,$00,$07,$00
	.byte $00,$00,$00,$07,$00,$00,$08,$08

; 069 English Horn
; Instrument is affected by LFO
M069_English_Horn:
	.byte $EC,$40
	.byte $31,$31,$31,$32,$1C,$19,$00,$00
	.byte $1F,$1F,$12,$16,$00,$00,$07,$00
	.byte $00,$00,$00,$07,$00,$00,$08,$08

; 070 Bassoon
M070_Bassoon:
	.byte $C3,$00
	.byte $54,$54,$01,$02,$3D,$38,$1A,$02
	.byte $14,$14,$14,$11,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$01,$00,$0A

; 071 Clarinet
; Instrument is affected by LFO
M071_Clarinet:
	.byte $C2,$50
	.byte $31,$32,$34,$31,$2E,$26,$34,$06
	.byte $05,$13,$1F,$13,$00,$09,$00,$08
	.byte $17,$00,$00,$00,$5F,$0C,$00,$0B

; 072 Piccolo
M072_Piccolo:
	.byte $CC,$00
	.byte $32,$32,$32,$32,$29,$20,$09,$0E
	.byte $1F,$1F,$13,$14,$05,$04,$04,$03
	.byte $01,$02,$06,$0A,$32,$46,$4C,$7C

; 073 Flute
; Instrument is affected by LFO
M073_Flute:
	.byte $CC,$50
	.byte $31,$31,$31,$31,$29,$20,$09,$0E
	.byte $1F,$1F,$0D,$12,$05,$04,$04,$03
	.byte $01,$03,$01,$00,$32,$46,$49,$77

; 074 Recorder
M074_Recorder:
	.byte $CF,$00
	.byte $31,$31,$31,$31,$08,$11,$11,$0D
	.byte $17,$18,$17,$16,$03,$03,$03,$03
	.byte $00,$00,$00,$00,$2A,$2A,$2A,$2A

; 075 Pan Flute
M075_Pan_Flute:
	.byte $EC,$00
	.byte $33,$34,$02,$32,$00,$21,$0A,$00
	.byte $14,$13,$93,$12,$09,$10,$10,$12
	.byte $00,$00,$00,$00,$F0,$29,$F9,$28

; 076 Blown Bottle
M076_Blown_Bottle:
	.byte $EC,$00
	.byte $33,$32,$02,$31,$00,$21,$0A,$00
	.byte $14,$13,$90,$11,$09,$10,$10,$12
	.byte $00,$00,$00,$00,$F0,$F9,$F9,$08

; 077 Shakuhachi
M077_Shakuhachi:
	.byte $EC,$00
	.byte $3F,$32,$02,$31,$00,$21,$0B,$00
	.byte $1F,$13,$93,$1B,$00,$10,$1F,$12
	.byte $00,$00,$00,$00,$F0,$59,$89,$08

; 078 Whistle
; Instrument is affected by LFO
M078_Whistle:
	.byte $C7,$62
	.byte $24,$44,$24,$44,$00,$00,$00,$0E
	.byte $50,$04,$0A,$0E,$0C,$8C,$0C,$8B
	.byte $0E,$03,$09,$00,$0D,$1B,$1D,$0B

; 079 Ocarina
M079_Ocarina:
	.byte $C7,$00
	.byte $32,$30,$30,$30,$08,$7F,$7F,$7F
	.byte $14,$1F,$1F,$1F,$03,$1F,$1F,$1F
	.byte $00,$1F,$1F,$1F,$3F,$FF,$FF,$FF

; 080 Lead 1 Square
; Instrument is affected by LFO
M080_Lead_1_Square:
	.byte $FB,$40
	.byte $32,$32,$32,$31,$1B,$25,$1D,$02
	.byte $1F,$1F,$1F,$19,$09,$09,$09,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$09

; 081 Lead 2 Saw
; Instrument is affected by LFO
M081_Lead_2_Saw:
	.byte $FB,$50
	.byte $31,$31,$31,$31,$1B,$28,$1C,$00
	.byte $1F,$1F,$1F,$14,$09,$09,$09,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$09

; 082 Lead 3 Triangle
; Instrument is affected by LFO
M082_Lead_3_Triangle:
	.byte $F1,$50
	.byte $32,$32,$32,$31,$18,$3C,$21,$00
	.byte $1F,$1F,$1F,$19,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$0A

; 083 Lead 4 Chiff Sine
; Instrument is affected by LFO
M083_Lead_4_Chiff_Sine:
	.byte $FE,$50
	.byte $30,$61,$31,$30,$0B,$00,$00,$7F
	.byte $1F,$1B,$13,$1F,$00,$00,$10,$1F
	.byte $17,$00,$07,$1F,$50,$0A,$FD,$FF

; 084 Lead 5 Charang
; Instrument is affected by LFO
M084_Lead_5_Charang:
	.byte $CB,$50
	.byte $31,$36,$31,$38,$0F,$0B,$0A,$00
	.byte $17,$0D,$11,$1F,$08,$09,$0E,$09
	.byte $00,$00,$00,$00,$F0,$80,$50,$69

; 085 Lead 6 Voice
; Instrument is affected by LFO
M085_Lead_6_Voice:
	.byte $C4,$50
	.byte $31,$31,$31,$31,$18,$18,$00,$07
	.byte $1F,$1F,$14,$14,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$0F,$09,$0B

; 086 Lead 7 Fifths
; Instrument is affected by LFO
M086_Lead_7_Fifths:
	.byte $D4,$50
	.byte $04,$06,$62,$63,$1D,$27,$00,$0C
	.byte $5F,$4E,$1F,$1D,$0A,$0A,$05,$05
	.byte $02,$02,$02,$02,$50,$00,$08,$28

; 087 Lead 8 Solo
; Instrument is affected by LFO
M087_Lead_8_Solo:
	.byte $C5,$50
	.byte $32,$31,$32,$31,$0D,$07,$00,$1D
	.byte $5F,$16,$1C,$15,$0D,$05,$05,$05
	.byte $01,$07,$0C,$07,$53,$4B,$47,$38

; 088 Pad 1 Fantasia
; Instrument is affected by LFO
M088_Pad_1_Fantasia:
	.byte $C4,$10
	.byte $5E,$51,$01,$01,$2A,$10,$02,$02
	.byte $1F,$04,$1F,$0A,$08,$04,$0E,$05
	.byte $00,$00,$00,$00,$F3,$B3,$F7,$F4

; 089 Pad 2 Warm
; Instrument is affected by LFO
M089_Pad_2_Warm:
	.byte $C2,$10
	.byte $55,$51,$01,$01,$7F,$10,$16,$02
	.byte $03,$04,$08,$0A,$08,$04,$00,$05
	.byte $00,$00,$00,$00,$F3,$B3,$F4,$F4

; 090 Pad 3 Poly
; Instrument is affected by LFO
M090_Pad_3_Poly:
	.byte $FC,$10
	.byte $31,$31,$31,$31,$1C,$1C,$00,$00
	.byte $1F,$09,$1F,$07,$07,$00,$09,$00
	.byte $00,$00,$00,$00,$50,$09,$08,$08

; 091 Pad 4 Choir
; Instrument is affected by LFO
M091_Pad_4_Choir:
	.byte $C4,$10
	.byte $31,$30,$31,$30,$25,$25,$0A,$13
	.byte $1F,$1F,$0B,$0B,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$06,$07

; 092 Pad 5 Bowed
M092_Pad_5_Bowed:
	.byte $C6,$00
	.byte $31,$39,$3A,$31,$22,$0E,$06,$0F
	.byte $10,$08,$06,$0A,$09,$09,$07,$09
	.byte $00,$00,$00,$00,$01,$39,$79,$38

; 093 Pad 6 Metallic
M093_Pad_6_Metallic:
	.byte $C4,$00
	.byte $59,$51,$01,$01,$35,$18,$17,$00
	.byte $1F,$1F,$8B,$87,$15,$01,$09,$08
	.byte $00,$00,$00,$00,$33,$51,$F8,$F5

; 094 Pad 7 Halo
; Instrument is affected by LFO
M094_Pad_7_Halo:
	.byte $C4,$50
	.byte $33,$31,$31,$30,$25,$25,$0A,$13
	.byte $1F,$1F,$0B,$0B,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$06,$07

; 095 Pad 8 Sweep
; Instrument is affected by LFO
M095_Pad_8_Sweep:
	.byte $C4,$61
	.byte $02,$04,$61,$62,$14,$14,$0A,$0A
	.byte $45,$45,$10,$0E,$8A,$8A,$05,$05
	.byte $02,$02,$02,$02,$09,$08,$07,$27

; 096 FX 1 Rain
M096_FX_1_Rain:
	.byte $E1,$00
	.byte $55,$51,$01,$01,$11,$28,$12,$00
	.byte $1F,$1F,$1F,$1E,$18,$17,$00,$13
	.byte $00,$00,$00,$0B,$F3,$F1,$F4,$B9

; 097 FX 2 Soundtrack
; Instrument is affected by LFO
M097_FX_2_Soundtrack:
	.byte $C4,$10
	.byte $04,$06,$62,$63,$23,$14,$00,$0A
	.byte $5F,$4E,$17,$09,$0A,$0A,$05,$05
	.byte $02,$02,$02,$02,$00,$00,$08,$28

; 098 FX 3 Crystal
M098_FX_3_Crystal:
	.byte $C4,$00
	.byte $31,$34,$31,$32,$29,$17,$08,$0E
	.byte $1F,$1F,$1F,$1F,$00,$09,$10,$09
	.byte $00,$00,$01,$00,$03,$26,$84,$F4

; 088 FX 4 Atmosphere
; Instrument is affected by LFO
M088_FX_4_Atmosphere:
	.byte $C4,$50
	.byte $51,$51,$01,$01,$2A,$10,$02,$02
	.byte $1F,$04,$1F,$0A,$08,$08,$0E,$05
	.byte $00,$00,$00,$00,$F0,$B0,$F7,$F6

; 100 FX 5 Brightness
; Instrument is affected by LFO
M100_FX_5_Brightness:
	.byte $FF,$40
	.byte $61,$62,$01,$03,$0B,$0D,$0D,$10
	.byte $1F,$1F,$1F,$1F,$17,$0F,$0A,$0D
	.byte $00,$00,$00,$00,$1F,$BA,$C8,$B7

; 101 FX 6 Goblins
M101_FX_6_Goblins:
	.byte $C4,$00
	.byte $31,$35,$31,$31,$29,$27,$1D,$00
	.byte $1F,$1F,$09,$15,$00,$09,$00,$09
	.byte $00,$00,$C1,$00,$03,$26,$8B,$F4

; 102 FX 7 Echoes
M102_FX_7_Echoes:
	.byte $C4,$00
	.byte $53,$51,$01,$01,$2B,$28,$1C,$00
	.byte $1F,$1F,$07,$1E,$00,$17,$1F,$12
	.byte $00,$00,$00,$0B,$F3,$F1,$FF,$B9

; 103 FX 8 Sci-Fi
; Instrument is affected by LFO
M103_FX_8_Sci_Fi:
	.byte $D5,$51
	.byte $48,$34,$32,$32,$1D,$11,$05,$0A
	.byte $17,$1F,$1F,$15,$86,$0A,$10,$09
	.byte $00,$00,$13,$0E,$20,$46,$67,$88

; 104 Sitar
M104_Sitar:
	.byte $F6,$00
	.byte $31,$32,$31,$34,$0C,$00,$00,$0C
	.byte $17,$0D,$1C,$1F,$10,$0D,$09,$11
	.byte $06,$1F,$08,$00,$20,$F7,$C8,$B8

; 105 Banjo
M105_Banjo:
	.byte $C1,$00
	.byte $31,$32,$31,$31,$2A,$15,$1E,$00
	.byte $1F,$1F,$1F,$1F,$09,$09,$0E,$11
	.byte $00,$00,$00,$0B,$0F,$FF,$9F,$6F

; 106 Shamisen
M106_Shamisen:
	.byte $EA,$00
	.byte $51,$61,$69,$23,$0E,$0D,$07,$00
	.byte $9E,$9F,$DF,$9F,$17,$02,$1A,$0D
	.byte $00,$03,$08,$0B,$3A,$2B,$9A,$68

; 107 Koto
M107_Koto:
	.byte $C2,$00
	.byte $35,$52,$13,$31,$13,$21,$1E,$00
	.byte $9F,$1F,$1F,$5F,$17,$00,$14,$0B
	.byte $05,$00,$0A,$0A,$69,$B9,$27,$39

; 108 Kalimba
M108_Kalimba:
	.byte $FD,$01
	.byte $58,$51,$08,$02,$22,$11,$0D,$02
	.byte $1F,$1F,$1F,$1F,$14,$12,$1A,$0F
	.byte $00,$00,$00,$00,$D3,$F6,$FD,$F9

; 109 Bagpipes
M109_Bagpipes:
	.byte $EB,$00
	.byte $30,$33,$30,$31,$2B,$1B,$12,$00
	.byte $1F,$13,$1F,$13,$00,$09,$00,$08
	.byte $17,$00,$00,$00,$50,$0C,$00,$0B

; 110 Fiddle
; Instrument is affected by LFO
M110_Fiddle:
	.byte $FA,$51
	.byte $31,$62,$35,$31,$26,$29,$17,$00
	.byte $57,$51,$4E,$4E,$8A,$0D,$0B,$04
	.byte $00,$00,$00,$00,$15,$26,$58,$09

; 111 Shanai
; Instrument is affected by LFO
M111_Shanai:
	.byte $FA,$50
	.byte $30,$31,$30,$31,$1F,$1F,$14,$00
	.byte $16,$14,$11,$11,$00,$00,$00,$00
	.byte $1F,$00,$1F,$1F,$FF,$BF,$FF,$9F

; 112 Tinkle Bell
M112_Tinkle_Bell:
	.byte $C7,$00
	.byte $05,$64,$38,$62,$00,$11,$0A,$0A
	.byte $1F,$12,$1F,$12,$0E,$0D,$0D,$0B
	.byte $1F,$1F,$13,$1F,$F6,$F6,$F6,$F6

; 113 Agogo
M113_Agogo:
	.byte $FC,$00
	.byte $50,$5C,$00,$00,$0F,$00,$00,$00
	.byte $1F,$1F,$1F,$18,$00,$00,$11,$1F
	.byte $C0,$00,$12,$11,$FF,$FF,$FF,$0F

; 114 Steel Drum
M114_Steel_Drum:
	.byte $E0,$00
	.byte $55,$63,$05,$31,$2A,$21,$47,$00
	.byte $1F,$10,$10,$1F,$08,$0B,$0D,$0A
	.byte $00,$0A,$00,$00,$F3,$37,$F9,$F7

; 115 Woodblock
M115_Woodblock:
	.byte $FC,$00
	.byte $3F,$30,$3F,$30,$10,$2A,$00,$00
	.byte $1F,$1F,$1F,$1F,$00,$00,$17,$12
	.byte $00,$00,$00,$80,$06,$06,$F6,$F6

; 116 Taiko Drum
M116_Taiko_Drum:
	.byte $FC,$00
	.byte $3F,$30,$30,$30,$0F,$27,$00,$00
	.byte $1F,$1F,$1F,$1F,$00,$00,$12,$13
	.byte $00,$00,$00,$80,$06,$06,$F6,$F6

; 117 Melodic Tom
M117_Melodic_Tom:
	.byte $E0,$00
	.byte $55,$52,$01,$01,$35,$1A,$00,$02
	.byte $1F,$1F,$1F,$18,$17,$15,$1B,$0E
	.byte $00,$00,$00,$00,$F3,$B1,$F4,$F9

; 118 Synth Drum
M118_Synth_Drum:
	.byte $FC,$00
	.byte $33,$30,$30,$30,$0B,$23,$00,$00
	.byte $1F,$1F,$1F,$1F,$12,$00,$12,$12
	.byte $00,$00,$00,$00,$F6,$06,$F6,$F6

; 119 Reverse Cymbal
M119_Reverse_Cymbal:
	.byte $F8,$00
	.byte $3F,$3F,$3F,$30,$00,$00,$00,$00
	.byte $1F,$1F,$1F,$05,$00,$00,$00,$1F
	.byte $1F,$00,$00,$00,$F8,$07,$06,$FF

; 120 Guitar Fret Noise
M120_Guitar_Fret_Noise:
	.byte $FA,$00
	.byte $62,$32,$38,$6A,$00,$16,$21,$10
	.byte $1F,$1F,$1F,$0F,$17,$00,$00,$12
	.byte $40,$40,$80,$40,$4F,$B1,$F4,$FB

; 121 Breath Noise
M121_Breath_Noise:
	.byte $EC,$00
	.byte $33,$32,$02,$31,$00,$21,$0A,$02
	.byte $14,$13,$53,$12,$09,$10,$10,$16
	.byte $00,$00,$00,$00,$F0,$F9,$F9,$FF

; 122 Seashore
; Instrument is affected by LFO
M122_Seashore:
	.byte $F8,$30
	.byte $3F,$3F,$3F,$30,$00,$00,$00,$00
	.byte $1F,$1F,$1F,$02,$00,$00,$00,$07
	.byte $1F,$00,$00,$00,$F0,$00,$00,$F4

; 123 Bird Tweet
M123_Bird_Tweet:
	.byte $C2,$00
	.byte $33,$39,$32,$32,$47,$18,$18,$00
	.byte $15,$12,$16,$12,$05,$15,$10,$90
	.byte $05,$80,$0F,$80,$4F,$6F,$0F,$FF

; 124 Telephone
M124_Telephone:
	.byte $C0,$00
	.byte $31,$31,$31,$3B,$35,$06,$10,$06
	.byte $1F,$1F,$1F,$1F,$09,$06,$08,$06
	.byte $40,$80,$80,$08,$0F,$0F,$0F,$0F

; 125 Helicopter
M125_Helicopter:
	.byte $F8,$00
	.byte $31,$31,$31,$3B,$17,$06,$10,$06
	.byte $1F,$1F,$1F,$06,$09,$06,$08,$00
	.byte $40,$80,$80,$00,$00,$00,$00,$04

; 126 Applause
; Instrument is affected by LFO
M126_Applause:
	.byte $F8,$01
	.byte $3F,$3F,$3F,$30,$00,$00,$00,$00
	.byte $1F,$1F,$1F,$0A,$00,$00,$00,$87
	.byte $1F,$00,$00,$00,$F0,$00,$00,$F4

; 127 Gunshot
M127_Gunshot:
	.byte $F8,$00
	.byte $00,$00,$00,$60,$00,$00,$00,$00
	.byte $1F,$1F,$1F,$5F,$00,$00,$00,$09
	.byte $00,$00,$00,$0E,$60,$50,$50,$08

; 128 Silent
M128_Silent:
	.byte $E7,$00
	.byte $00,$00,$00,$00,$7F,$7F,$7F,$7F
	.byte $1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F
	.byte $1F,$1F,$1F,$1F,$FF,$FF,$FF,$FF

; 129 Snare Roll
M129_Snare_Roll:
	.byte $F8,$00
	.byte $00,$00,$00,$60,$00,$00,$00,$00
	.byte $1F,$1F,$1F,$5F,$00,$00,$00,$0D
	.byte $00,$00,$00,$00,$60,$50,$50,$38

; 130 Snap
M130_Snap:
	.byte $FB,$00
	.byte $52,$50,$00,$0F,$08,$16,$11,$00
	.byte $1F,$1F,$1F,$1F,$00,$00,$00,$15
	.byte $80,$C0,$40,$00,$FF,$FF,$FF,$FF

; 131 High Q
M131_High_Q:
	.byte $C0,$00
	.byte $50,$50,$00,$00,$00,$00,$27,$00
	.byte $1F,$1F,$1F,$1F,$18,$11,$16,$0E
	.byte $80,$C0,$4E,$00,$FF,$FF,$FF,$FF

; 132 Scratch
M132_Scratch:
	.byte $E8,$00
	.byte $55,$52,$01,$01,$2C,$2D,$00,$02
	.byte $1A,$14,$14,$11,$17,$15,$1B,$10
	.byte $00,$00,$00,$00,$F3,$B1,$F4,$FB

; 133 Square Click
M133_Square_Click:
	.byte $FB,$00
	.byte $32,$32,$32,$31,$1B,$25,$1D,$02
	.byte $1F,$1F,$1F,$1F,$09,$09,$09,$16
	.byte $00,$00,$00,$00,$00,$00,$00,$F9

; 134 Kick
M134_Kick:
	.byte $FD,$00
	.byte $50,$50,$00,$00,$11,$00,$00,$02
	.byte $1F,$1F,$1F,$1F,$18,$00,$00,$00
	.byte $00,$13,$0D,$19,$FF,$0F,$0F,$0F

; 135 Rim
M135_Rim:
	.byte $FB,$00
	.byte $52,$50,$00,$0F,$08,$28,$22,$00
	.byte $1F,$1F,$1F,$1F,$00,$00,$00,$12
	.byte $80,$C0,$40,$00,$FF,$FF,$FF,$FF

; 136 Snare
M136_Snare:
	.byte $FC,$00
	.byte $5F,$51,$0F,$00,$00,$10,$00,$00
	.byte $1F,$1F,$1F,$1F,$1F,$1A,$11,$0E
	.byte $00,$00,$00,$0A,$05,$F1,$FC,$7A

; 137 Clap
M137_Clap:
	.byte $FB,$00
	.byte $52,$50,$00,$0F,$08,$16,$1A,$00
	.byte $1F,$1F,$1F,$1F,$00,$00,$00,$11
	.byte $80,$C0,$40,$0F,$FF,$FF,$FF,$6F

; 138 Tom
M138_Tom:
	.byte $C0,$00
	.byte $30,$31,$34,$30,$22,$2B,$1F,$05
	.byte $D9,$1F,$DF,$1F,$12,$14,$11,$0F
	.byte $0A,$0A,$00,$09,$F3,$F3,$F6,$96

; 139 Closed Hi-Hat
M139_Closed_Hi_Hat:
	.byte $F6,$00
	.byte $3F,$38,$3F,$39,$00,$65,$00,$53
	.byte $16,$00,$18,$1F,$0F,$0C,$16,$0B
	.byte $00,$00,$12,$00,$06,$4F,$2F,$4F

; 140 Pedal Hi-Hat
M140_Pedal_Hi_Hat:
	.byte $F6,$00
	.byte $3F,$38,$3F,$39,$00,$20,$0E,$7C
	.byte $16,$00,$16,$1F,$0F,$0C,$0F,$0B
	.byte $00,$00,$18,$00,$06,$4F,$5F,$4F

; 141 Open Hi-Hat
M141_Open_Hi_Hat:
	.byte $F6,$00
	.byte $3F,$38,$3F,$39,$00,$20,$12,$25
	.byte $16,$00,$18,$1F,$0F,$0C,$0A,$0B
	.byte $00,$00,$0B,$00,$06,$4F,$5F,$4F

; 142 Crash
M142_Crash:
	.byte $C0,$00
	.byte $50,$50,$00,$0F,$00,$00,$00,$00
	.byte $1F,$1F,$1F,$18,$1A,$05,$03,$00
	.byte $C0,$C0,$40,$0A,$F0,$F0,$F0,$06

; 143 Ride Cymbal
M143_Ride_Cymbal:
	.byte $C0,$00
	.byte $32,$37,$36,$3F,$54,$1E,$0C,$00
	.byte $1F,$1F,$1F,$1F,$00,$00,$00,$0C
	.byte $C0,$00,$C0,$00,$00,$00,$00,$F6

; 144 Splash Cymbal
M144_Splash_Cymbal:
	.byte $C0,$00
	.byte $50,$50,$00,$00,$00,$03,$00,$04
	.byte $1F,$1F,$1F,$18,$1A,$05,$03,$00
	.byte $C0,$40,$40,$0A,$F0,$00,$90,$06

; 145 Tambourine
M145_Tambourine:
	.byte $FC,$00
	.byte $0B,$2F,$68,$4B,$00,$00,$00,$00
	.byte $1F,$DF,$1F,$15,$00,$00,$11,$11
	.byte $1F,$C0,$00,$00,$FF,$00,$FF,$FE

; 146 Vibraslap
M146_Vibraslap:
	.byte $F8,$00
	.byte $00,$00,$00,$60,$30,$00,$00,$00
	.byte $1F,$1F,$1F,$5F,$00,$00,$00,$0C
	.byte $00,$00,$00,$0D,$60,$50,$50,$38

; 147 Bongo
M147_Bongo:
	.byte $D0,$00
	.byte $30,$32,$3C,$30,$0C,$2B,$27,$00
	.byte $D8,$1F,$DF,$1F,$0E,$14,$11,$11
	.byte $0A,$0A,$00,$09,$F3,$F3,$F7,$FA

; 148 Maracas
M148_Maracas:
	.byte $FA,$00
	.byte $62,$32,$38,$6A,$00,$16,$21,$07
	.byte $1F,$1F,$1F,$10,$00,$00,$00,$0F
	.byte $40,$40,$80,$4B,$40,$B1,$F4,$B8

; 149 Short Whistle
M149_Short_Whistle:
	.byte $C7,$00
	.byte $29,$47,$76,$05,$00,$00,$00,$0E
	.byte $0F,$16,$12,$12,$0B,$0B,$0B,$0B
	.byte $19,$19,$59,$D9,$1D,$1E,$1D,$1B

; 150 Long Whistle
M150_Long_Whistle:
	.byte $C7,$00
	.byte $29,$47,$76,$05,$00,$00,$00,$0E
	.byte $0F,$16,$12,$12,$05,$05,$05,$05
	.byte $1F,$1F,$5F,$DF,$1D,$1E,$1D,$1B

; 151 Short Guiro
M151_Short_Guiro:
	.byte $F8,$00
	.byte $00,$00,$7C,$30,$1E,$08,$32,$02
	.byte $1F,$1F,$15,$5F,$00,$00,$00,$0E
	.byte $00,$00,$08,$1F,$6F,$5F,$FF,$1F

; 152 Long Guiro
M152_Long_Guiro:
	.byte $F8,$00
	.byte $00,$00,$7C,$30,$1E,$08,$32,$02
	.byte $1F,$1F,$0B,$4C,$00,$00,$00,$0A
	.byte $00,$00,$08,$1F,$6F,$5F,$FF,$1F

; 153 Mute Cuica
M153_Mute_Cuica:
	.byte $C0,$00
	.byte $30,$37,$30,$30,$07,$00,$34,$00
	.byte $1F,$1F,$1F,$1F,$18,$11,$16,$10
	.byte $00,$00,$0E,$1D,$FF,$FF,$FF,$6F

; 154 Open Cuica
M154_Open_Cuica:
	.byte $C0,$00
	.byte $30,$37,$30,$30,$07,$00,$34,$00
	.byte $1F,$1F,$1F,$1F,$18,$05,$0D,$0D
	.byte $00,$00,$0E,$1D,$FF,$BF,$DF,$6F

; 155 Mute Triangle
M155_Mute_Triangle:
	.byte $CC,$00
	.byte $3A,$3A,$30,$31,$7F,$18,$7F,$00
	.byte $1F,$1F,$1F,$1F,$0D,$11,$04,$0C
	.byte $00,$00,$00,$1F,$F3,$F1,$F4,$1F

; 156 Open Triangle
M156_Open_Triangle:
	.byte $CC,$00
	.byte $3A,$3A,$30,$31,$7F,$18,$7F,$00
	.byte $1F,$1F,$1F,$1F,$0D,$11,$04,$0C
	.byte $00,$00,$00,$08,$F3,$F1,$F4,$15

; 157 Jingle Bell
M157_Jingle_Bell:
	.byte $C7,$00
	.byte $29,$47,$76,$05,$00,$00,$00,$02
	.byte $1F,$12,$1F,$12,$0D,$0D,$14,$14
	.byte $10,$94,$4F,$D3,$1D,$1E,$1D,$1B

; 158 Bell Tree
M158_Bell_Tree:
	.byte $C7,$00
	.byte $2B,$4D,$79,$0D,$00,$00,$00,$02
	.byte $1F,$1F,$1F,$1F,$14,$13,$14,$13
	.byte $8D,$4F,$4F,$8D,$6D,$9E,$4D,$6D

; 159 Mute Surdo
M159_Mute_Surdo:
	.byte $C4,$00
	.byte $70,$51,$00,$00,$30,$10,$26,$00
	.byte $1F,$1F,$1F,$1F,$19,$1A,$19,$16
	.byte $80,$00,$59,$0F,$FF,$FF,$8C,$0A

; 160 Pure Sine
M160_Pure_Sine:
	.byte $C7,$00
	.byte $31,$31,$31,$31,$7F,$7F,$7F,$00
	.byte $1F,$1F,$1F,$1F,$1F,$1F,$1F,$00
	.byte $1F,$1F,$1F,$00,$FF,$FF,$FF,$0F

; 161 Timbale
M161_Timbale:
	.byte $C0,$00
	.byte $30,$37,$30,$30,$07,$04,$4A,$00
	.byte $1F,$18,$1F,$1F,$18,$01,$00,$0D
	.byte $00,$00,$0E,$17,$FF,$BF,$DF,$5F

; 162 Open Surdo
M162_Open_Surdo:
	.byte $C4,$00
	.byte $70,$51,$00,$00,$30,$10,$00,$00
	.byte $1F,$1F,$1F,$1F,$19,$1A,$0C,$0E
	.byte $80,$00,$40,$0A,$F5,$F1,$FC,$7A
