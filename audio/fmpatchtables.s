; Patch tables created by Barry Yost (a.k.a. ZeroByte) and MooingLemur
; used for predefined YM2151 instruments and drums
; - 2022

.export patches_lo, patches_hi
.export drum_patches, drum_kc

.segment "PATCHDATA"

; Patch data in 'YMP' (YM Patch) format.

; The format is simply the values for registers:
; $20, $38, $40, $48, $50, $58, ... , $F0, $F8
; (skips $28 and $30 which are note selections, not patch data)

fm_patches:
.include "fmpatches.s"


.linecont +

.define GM0_PIANO \
	M000_Acoustic_Piano, \
	M001_Bright_Acoustic_Piano, \
	M002_Electric_Grand_Piano, \
	M003_Honky_Tonk_Piano, \
	M004_Electric_Piano_1, \
	M005_Electric_Piano_2, \
	M006_Harpsichord, \
	M007_Clavinet

.define GM1_MALLET \
	M008_Celesta, \
	M009_Glockenspiel, \
	M010_Music_Box, \
	M011_Vibraphone, \
	M012_Marimba, \
	M013_Xylophone, \
	M014_Tubular_Bells, \
	M015_Dulcimer

.define GM2_ORGAN \
	M016_Drawbar_Organ, \
	M017_Percussive_Organ, \
	M018_Rock_Organ, \
	M019_Church_Organ, \
	M020_Reed_Organ, \
	M021_Accordion, \
	M022_Harmonica, \
	M023_Bandoneon

.define GM3_GUITAR \
	M024_Acoustic_Nylon_Guitar, \
	M025_Acoustic_Steel_Guitar, \
	M026_Electric_Jazz_Guitar, \
	M027_Electric_Clean_Guitar, \
	M028_Electric_Muted_Guitar, \
	M029_Electric_Overdriven_Guitar, \
	M030_Electric_Distorted_Guitar, \
	M031_Electric_Guitar_Harmonics

.define GM4_BASS \
	M032_Acoustic_Bass, \
	M033_Electric_Finger_Bass, \
	M034_Electric_Picked_Bass, \
	M035_Fretless_Bass, \
	M036_Slap_Bass_1, \
	M037_Slap_Bass_2, \
	M038_Synth_Bass_1, \
	M039_Synth_Bass_2

.define GM5_STRINGS \
	M040_Violin, \
	M041_Viola, \
	M042_Cello, \
	M043_Contrabass, \
	M044_Tremolo_Strings, \
	M045_Pizzicato_Strings, \
	M046_Harp, \
	M047_Timpani

.define GM6_ENSEMBLE \
	M048_String_Ensemble_1, \
	M049_String_Ensemble_2, \
	M050_Synth_Strings_1, \
	M051_Synth_Strings_2, \
	M052_Choir_Aahs, \
	M053_Doo, \
	M054_Synth_Choir, \
	M055_Orch_Hit

.define GM7_BRASS \
	M056_Trumpet, \
	M057_Trombone, \
	M058_Tuba, \
	M059_Muted_Trumpet, \
	M060_French_Horn, \
	M061_Brass_Section, \
	M062_Synth_Brass_1, \
	M063_Synth_Brass_2

.define GM8_REED \
	M064_Soprano_Sax, \
	M065_Alto_Sax, \
	M066_Tenor_Sax, \
	M067_Baritone_Sax, \
	M068_Oboe, \
	M069_English_Horn, \
	M070_Bassoon, \
	M071_Clarinet

.define GM9_PIPE \
	M072_Piccolo, \
	M073_Flute, \
	M074_Recorder, \
	M075_Pan_Flute, \
	M076_Blown_Bottle, \
	M077_Shakuhachi, \
	M078_Whistle, \
	M079_Ocarina

.define GMA_LEAD \
	M080_Lead_1_Square, \
	M081_Lead_2_Saw, \
	M082_Lead_3_Triangle, \
	M083_Lead_4_Chiff_Sine, \
	M084_Lead_5_Charang, \
	M085_Lead_6_Voice, \
	M086_Lead_7_Fifths, \
	M087_Lead_8_Solo

.define GMB_PAD \
	M088_Pad_1_Fantasia, \
	M089_Pad_2_Warm, \
	M090_Pad_3_Poly, \
	M091_Pad_4_Choir, \
	M092_Pad_5_Bowed, \
	M093_Pad_6_Metallic, \
	M094_Pad_7_Halo, \
	M095_Pad_8_Sweep

.define GMC_SYNFX \
	M096_FX_1_Rain, \
	M097_FX_2_Soundtrack, \
	M098_FX_3_Crystal, \
	M088_FX_4_Atmosphere, \
	M100_FX_5_Brightness, \
	M101_FX_6_Goblins, \
	M102_FX_7_Echoes, \
	M103_FX_8_Sci_Fi

.define GMD_ETHNIC \
	M104_Sitar, \
	M105_Banjo, \
	M106_Shamisen, \
	M107_Koto, \
	M108_Kalimba, \
	M109_Bagpipes, \
	M110_Fiddle, \
	M111_Shanai

.define GME_PERC \
	M112_Tinkle_Bell, \
	M113_Agogo, \
	M114_Steel_Drum, \
	M115_Woodblock, \
	M116_Taiko_Drum, \
	M117_Melodic_Tom, \
	M118_Synth_Drum, \
	M119_Reverse_Cymbal

.define GMF_SFX \
	M120_Guitar_Fret_Noise, \
	M121_Breath_Noise, \
	M122_Seashore, \
	M123_Bird_Tweet, \
	M124_Telephone, \
	M125_Helicopter, \
	M126_Applause, \
	M127_Gunshot

.define GM_DRUMS \
	M128_Silent, \
	M129_Snare_Roll, \
	M130_Snap, \
	M131_High_Q, \
	M132_Scratch, \
	M133_Square_Click, \
	M134_Kick, \
	M135_Rim, \
	M136_Snare, \
	M137_Clap, \
	M138_Tom, \
	M139_Closed_Hi_Hat, \
	M140_Pedal_Hi_Hat, \
	M141_Open_Hi_Hat, \
	M142_Crash, \
	M143_Ride_Cymbal, \
	M144_Splash_Cymbal, \
	M145_Tambourine, \
	M146_Vibraslap, \
	M147_Bongo, \
	M148_Maracas, \
	M149_Short_Whistle, \
	M150_Long_Whistle, \
	M151_Short_Guiro, \
	M152_Long_Guiro, \
	M153_Mute_Cuica, \
	M154_Open_Cuica, \
	M155_Mute_Triangle, \
	M156_Open_Triangle, \
	M157_Jingle_Bell, \
	M158_Bell_Tree, \
	M159_Mute_Surdo, \
	M160_Pure_Sine, \
	M161_Timbale, \
	M162_Open_Surdo
.linecont -



patches_lo:
	.lobytes GM0_PIANO
	.lobytes GM1_MALLET
	.lobytes GM2_ORGAN
	.lobytes GM3_GUITAR
	.lobytes GM4_BASS
	.lobytes GM5_STRINGS
	.lobytes GM6_ENSEMBLE
	.lobytes GM7_BRASS
	.lobytes GM8_REED
	.lobytes GM9_PIPE
	.lobytes GMA_LEAD
	.lobytes GMB_PAD
	.lobytes GMC_SYNFX
	.lobytes GMD_ETHNIC
	.lobytes GME_PERC
	.lobytes GMF_SFX
	.lobytes GM_DRUMS

patches_hi:
	.hibytes GM0_PIANO
	.hibytes GM1_MALLET
	.hibytes GM2_ORGAN
	.hibytes GM3_GUITAR
	.hibytes GM4_BASS
	.hibytes GM5_STRINGS
	.hibytes GM6_ENSEMBLE
	.hibytes GM7_BRASS
	.hibytes GM8_REED
	.hibytes GM9_PIPE
	.hibytes GMA_LEAD
	.hibytes GMB_PAD
	.hibytes GMC_SYNFX
	.hibytes GMD_ETHNIC
	.hibytes GME_PERC
	.hibytes GMF_SFX
	.hibytes GM_DRUMS

; These are the patches that are used for the drums
drum_patches:
	.byte $80,$80,$80,$80,$80,$80,$80,$80
	.byte $80,$80,$80,$80,$80,$80,$80,$80
	.byte $80,$80,$80,$80,$80,$80,$80,$80
	.byte $80
	.byte $81 ; 25: 129 Snare Roll
	.byte $82 ; 26: 130 Snap
	.byte $83 ; 27: 131 High Q
	.byte $82 ; 28: Slap = 130 Snap
	.byte $84 ; 29: Scratch Pull = 132 Scratch
	.byte $84 ; 30: Scratch Push = 132 Scratch
	.byte $82 ; 31: Sticks = 130 Snap

	.byte $85 ; 32: 133 Square Click
	.byte $70 ; 33: Metronome Bell = 112 Tinkle Bell
	.byte $82 ; 34: Metronome Click = 130 Snap
	.byte $86 ; 35: Acoustic Bass Drum = 134 Kick
	.byte $86 ; 36: Electric Bass Drum = 134 Kick
	.byte $87 ; 37: Side Stick = 135 Rim
	.byte $88 ; 38: Acoustic Snare = 136 Snare
	.byte $89 ; 39: Hand Clap = 137 Clap

	.byte $88 ; 40: Electric Snare = 136 Snare
	.byte $8A ; 41: Low Floor Tom = 138 Tom
	.byte $8B ; 42: 139 Closed Hi-Hat
	.byte $8A ; 43: High Floor Tom = 138 Tom
	.byte $8C ; 44: 140 Pedal Hi-Hat
	.byte $8A ; 45: Low Tom = 138 Tom
	.byte $8D ; 46: 141 Open Hi-Hat
	.byte $8A ; 47: Low-Mid Tom = 138 Tom
	
	.byte $8A ; 48: High-Mid Tom = 138 Tom
	.byte $8E ; 49: Crash Cymbal 1 = 142 Crash
	.byte $8A ; 50: High Tom = 138 Tom
	.byte $8F ; 51: Ride Cymbal 1 = 143 Ride Cymbal
	.byte $90 ; 52: Chinese Cymbal = 144 Splash Cymbal
	.byte $8F ; 53: Ride Bell = 143 Ride Cymbal
	.byte $91 ; 54: 145 Tambourine
	.byte $90 ; 55: 144 Splash Cymbal

	.byte $71 ; 56: Cowbell = 113 Agogo
	.byte $8E ; 57: Crash Cymbal 2 = 142 Crash
	.byte $92 ; 58: 146 Vibraslap
	.byte $8F ; 59: Ride Cymbal 2 = 143 Ride Cymbal
	.byte $93 ; 60: High Bongo = 147 Bongo
	.byte $93 ; 61: Low Bongo = 147 Bongo
	.byte $8A ; 62: Mute High Conga = 138 Tom
	.byte $93 ; 63: Open High Conga = 147 Bongo

	.byte $93 ; 64: Low Conga = 147 Bongo
	.byte $A1 ; 65: High Timbale = 161 Timbale
	.byte $A1 ; 66: Low Timbale = 161 Timbale
	.byte $71 ; 67: High Agogo = 113 Agogo
	.byte $71 ; 68: Low Agogo = 113 Agogo
	.byte $78 ; 69: Cabasa = 120 Guitar Fret Noise
	.byte $94 ; 70: 148 Maracas
	.byte $95 ; 71: 149 Short Whistle

	.byte $96 ; 72: 150 Long Whistle
	.byte $97 ; 73: 151 Short Guiro
	.byte $98 ; 74: 152 Long Guiro
	.byte $85 ; 75: Claves = 133 Square Click
	.byte $73 ; 76: High Woodblock = 115 Woodblock
	.byte $73 ; 77: Low Woodblock = 115 Woodblock
	.byte $99 ; 78: 153 Mute Cuica
	.byte $9A ; 79: 154 Open Cuica

	.byte $9B ; 80: 155 Mute Triangle
	.byte $9C ; 81: 156 Open Triangle
	.byte $94 ; 82: Shaker = 148 Maracas
	.byte $9D ; 83: 157 Jingle Bell
	.byte $9E ; 84: 158 Bell Tree
	.byte $87 ; 85: Castanets = 135 Rim
	.byte $9F ; 86: 159 Mute Surdo
	.byte $A2 ; 87: 162 Open Surdo

	.byte $80,$80,$80,$80,$80,$80,$80,$80
	.byte $80,$80,$80,$80,$80,$80,$80,$80
	.byte $80,$80,$80,$80,$80,$80,$80,$80
	.byte $80,$80,$80,$80,$80,$80,$80,$80
	.byte $80,$80,$80,$80,$80,$80,$80,$80


; These are the KC values for the drum patches
; indexed by GM drums' corresponding MIDI note
drum_kc:
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00
	.byte $00 ; 25 Snare Roll (C#0)
	.byte $3E ; 26 Snap (YM C3/MIDI C4)
	.byte $1E ; 27 High Q (YM C1/MIDI C2)
	.byte $10 ; 28 Slap (C#1)
	.byte $18 ; 29 Scratch Pull (G1)
	.byte $11 ; 30 Scratch Push (D1)
	.byte $75 ; 31 Sticks (F7)

	.byte $4E ; 32 Square Click (YM C4/MIDI C5)
	.byte $5E ; 33 Metronome Bell (YM C5/MIDI C6)
	.byte $4E ; 34 Metronome Click (YM C4/MIDI C5)
	.byte $2E ; 35 Acoustic Bass Drum (YM C2/MIDI C3)
	.byte $3E ; 36 Electric Bass Drum (YM C3/MIDI C4)
	.byte $61 ; 37 Side Stick (D6)
	.byte $41 ; 38 Acoustic Snare (D4)
	.byte $2E ; 39 Hand Clap (YM C2/MIDI C3)

	.byte $2E ; 40 Electric Snare (YM C2/MIDI C3)
	.byte $2E ; 41 Low Floor Tom (YM C2/MIDI C3)
	.byte $5E ; 42 Closed Hi-Hat (YM C5/MIDI C6)
	.byte $35 ; 43 High Floor Tom (F3)
	.byte $7E ; 44 Pedal Hi-Hat (YM C7/MIDI C8)
	.byte $38 ; 45 Low Tom (G3)
	.byte $7E ; 46 Open Hi-Hat (YM C7/MIDI C8)
	.byte $3C ; 47 Low-Mid Tom (A#3)

	.byte $40 ; 48 High-Mid Tom (C#4)
	.byte $7E ; 49 Crash Cymbal 1 (YM C7/MIDI C8)
	.byte $44 ; 50 High Tom (E4)
	.byte $7E ; 51 Ride Cymbal 1 (YM C7/MIDI C8)
	.byte $2E ; 52 Chinese Cymbal (YM C2/MIDI C3)
	.byte $31 ; 53 Ride Bell (D3)
	.byte $38 ; 54 Tambourine (G3)
	.byte $45 ; 55 Splash Cymbal (F4)

	.byte $68 ; 56 Cowbell (G6)
	.byte $2E ; 57 Crash Cymbal 2 (YM C2/MIDI C3)
	.byte $08 ; 58 Vibraslap (G0)
	.byte $6E ; 51 Ride Cymbal 2 (YM C6/MIDI C7)
	.byte $3A ; 60 High Bongo (A3)
	.byte $34 ; 61 Low Bongo (E3)
	.byte $2E ; 62 Mute High Conga (YM C2/MIDI C3)
	.byte $2E ; 63 Open High Conga (YM C2/MIDI C3)

	.byte $28 ; 64 Low Conga (G2)
	.byte $6E ; 65 High Timbale (YM C6/MIDI C7)
	.byte $6D ; 66 Low Timbale (B6)
	.byte $75 ; 67 High Agogo (F7)
	.byte $6E ; 68 Low Agogo (YM C6/MIDI C7)
	.byte $7E ; 69 Cabasa (YM C7/MIDI C8)
	.byte $1E ; 70 Maracas (YM C1/MIDI C2)
	.byte $3E ; 71 Short Whistle (YM C3/MIDI C4)

	.byte $3E ; 72 Long Whistle (YM C3/MIDI C4)
	.byte $1A ; 73 Short Guiro (A1)
	.byte $1A ; 74 Long Guiro (A1)
	.byte $68 ; 75 Claves (G6)
	.byte $55 ; 76 High Woodblock (F5)
	.byte $4E ; 77 Low Woodblock (YM C4/MIDI C5)
	.byte $7E ; 78 Mute Cuica (YM C7/MIDI C8)
	.byte $55 ; 79 Open Cuica (F6)

	.byte $7E ; 80 Mute Triangle (YM C7/MIDI C8)
	.byte $7E ; 81 Open Triangle (YM C7/MIDI C8)
	.byte $6E ; 82 Shaker (YM C6/MIDI C7)
	.byte $44 ; 83 Jingle Bell (E4)
	.byte $25 ; 84 Bell Tree (F2)
	.byte $65 ; 85 Castanets (F6)
	.byte $3E ; 86 Mute Surdo (YM C3/MIDI C4)
	.byte $3E ; 87 Open Surdo (YM C3/MIDI C4)
	
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00

