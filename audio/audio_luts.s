; X16 audio lookup tables
; Most of the space is used by pitch translation tables for VERA

; LUT table created by create_luts.py by MooingLemur (c) 2022

.export kfdelta2_h,kfdelta3_h,kfdelta4_h,kfdelta5_h,kfdelta6_h,kfdelta7_h
.export kfdelta2_l,kfdelta3_l,kfdelta4_l,kfdelta5_l,kfdelta6_l,kfdelta7_l
.export midi2psg_h,midi2psg_l
.export midi2ymkc
.export ymkc2midi
.export midi2bas
.export bas2midi
.export fm_op_alg_carrier

.segment "LUTS"

; PSG pitch tables
midi2psg_l:
	.byte $15,$17,$18,$1a,$1b,$1d,$1f,$20,$22,$24,$27,$29
	.byte $2b,$2e,$31,$34,$37,$3a,$3e,$41,$45,$49,$4e,$52
	.byte $57,$5d,$62,$68,$6e,$75,$7c,$83,$8b,$93,$9c,$a5
	.byte $af,$ba,$c5,$d0,$dd,$ea,$f8,$07,$16,$27,$38,$4b
	.byte $5f,$74,$8a,$a1,$ba,$d4,$f0,$0e,$2d,$4e,$71,$96
	.byte $be,$e8,$14,$43,$74,$a9,$e1,$1c,$5a,$9d,$e3,$2d
	.byte $7c,$d0,$28,$86,$e9,$52,$c2,$38,$b5,$3a,$c6,$5b
	.byte $f9,$a0,$51,$0c,$d3,$a5,$84,$71,$6b,$74,$8d,$b7
	.byte $f2,$40,$a2,$19,$a6,$4b,$09,$e2,$d6,$e8,$1a,$6e
	.byte $e4,$80,$44,$32,$4d,$97,$13,$c4,$ad,$d1,$35,$dc
	.byte $c9,$01,$89,$65,$9a,$2e,$26,$88
midi2psg_h:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02
	.byte $02,$02,$03,$03,$03,$03,$03,$04,$04,$04,$04,$05
	.byte $05,$05,$06,$06,$06,$07,$07,$08,$08,$09,$09,$0a
	.byte $0a,$0b,$0c,$0d,$0d,$0e,$0f,$10,$11,$12,$13,$14
	.byte $15,$17,$18,$1a,$1b,$1d,$1f,$20,$22,$24,$27,$29
	.byte $2b,$2e,$31,$34,$37,$3a,$3e,$41,$45,$49,$4e,$52
	.byte $57,$5d,$62,$68,$6e,$75,$7c,$83
; MIDI to YM2151 KC
midi2ymkc:
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $ff,$00,$01,$02,$04,$05,$06,$08,$09,$0a,$0c,$0d
	.byte $0e,$10,$11,$12,$14,$15,$16,$18,$19,$1a,$1c,$1d
	.byte $1e,$20,$21,$22,$24,$25,$26,$28,$29,$2a,$2c,$2d
	.byte $2e,$30,$31,$32,$34,$35,$36,$38,$39,$3a,$3c,$3d
	.byte $3e,$40,$41,$42,$44,$45,$46,$48,$49,$4a,$4c,$4d
	.byte $4e,$50,$51,$52,$54,$55,$56,$58,$59,$5a,$5c,$5d
	.byte $5e,$60,$61,$62,$64,$65,$66,$68,$69,$6a,$6c,$6d
	.byte $6e,$70,$71,$72,$74,$75,$76,$78,$79,$7a,$7c,$7d
	.byte $7e,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
; MIDI to BAS
midi2bas:
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c
	.byte $11,$12,$13,$14,$15,$16,$17,$18,$19,$1a,$1b,$1c
	.byte $21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c
	.byte $31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c
	.byte $41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c
	.byte $51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$5b,$5c
	.byte $61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c
	.byte $71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$7b,$7c
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
; YM2151 KC to MIDI
ymkc2midi:
	.byte $0d,$0e,$0f,$0f,$10,$11,$12,$12,$13,$14,$15,$15
	.byte $16,$17,$18,$18,$19,$1a,$1b,$1b,$1c,$1d,$1e,$1e
	.byte $1f,$20,$21,$21,$22,$23,$24,$24,$25,$26,$27,$27
	.byte $28,$29,$2a,$2a,$2b,$2c,$2d,$2d,$2e,$2f,$30,$30
	.byte $31,$32,$33,$33,$34,$35,$36,$36,$37,$38,$39,$39
	.byte $3a,$3b,$3c,$3c,$3d,$3e,$3f,$3f,$40,$41,$42,$42
	.byte $43,$44,$45,$45,$46,$47,$48,$48,$49,$4a,$4b,$4b
	.byte $4c,$4d,$4e,$4e,$4f,$50,$51,$51,$52,$53,$54,$54
	.byte $55,$56,$57,$57,$58,$59,$5a,$5a,$5b,$5c,$5d,$5d
	.byte $5e,$5f,$60,$60,$61,$62,$63,$63,$64,$65,$66,$66
	.byte $67,$68,$69,$69,$6a,$6b,$6c,$6c
; BAS to MIDI
bas2midi:
	.byte $ff,$0c,$0d,$0e,$0f,$10,$11,$12,$13,$14,$15,$16
	.byte $ff,$ff,$ff,$ff,$ff,$18,$19,$1a,$1b,$1c,$1d,$1e
	.byte $1f,$20,$21,$22,$ff,$ff,$ff,$ff,$ff,$24,$25,$26
	.byte $27,$28,$29,$2a,$2b,$2c,$2d,$2e,$ff,$ff,$ff,$ff
	.byte $ff,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a
	.byte $ff,$ff,$ff,$ff,$ff,$3c,$3d,$3e,$3f,$40,$41,$42
	.byte $43,$44,$45,$46,$ff,$ff,$ff,$ff,$ff,$48,$49,$4a
	.byte $4b,$4c,$4d,$4e,$4f,$50,$51,$52,$ff,$ff,$ff,$ff
	.byte $ff,$54,$55,$56,$57,$58,$59,$5a,$5b,$5c,$5d,$5e
	.byte $ff,$ff,$ff,$ff,$ff,$60,$61,$62,$63,$64,$65,$66
	.byte $67,$68,$69,$6a,$ff,$ff,$ff,$ff
; KF bit 0 delta per MIDI note (high)
kfdelta0_h:
; KF bit 1 delta per MIDI note (high)
kfdelta1_h:
; KF bit 2 delta per MIDI note (high)
kfdelta2_h:
; KF bit 3 delta per MIDI note (high)
kfdelta3_h:
; KF bit 4 delta per MIDI note (high)
kfdelta4_h:
; KF bit 5 delta per MIDI note (high)
kfdelta5_h:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; KF bit 6 delta per MIDI note (high)
kfdelta6_h:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; KF bit 7 delta per MIDI note (high)
kfdelta7_h:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; KF bit 0 delta per MIDI note (low)
kfdelta0_l:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; KF bit 1 delta per MIDI note (low)
kfdelta1_l:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; KF bit 2 delta per MIDI note (low)
kfdelta2_l:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; KF bit 3 delta per MIDI note (low)
kfdelta3_l:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; KF bit 4 delta per MIDI note (low)
kfdelta4_l:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; KF bit 5 delta per MIDI note (low)
kfdelta5_l:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; KF bit 6 delta per MIDI note (low)
kfdelta6_l:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; KF bit 7 delta per MIDI note (low)
kfdelta7_l:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02
	.byte $02,$02,$02,$03,$03,$03,$03,$03,$04,$04,$04,$04
	.byte $05,$05,$05,$06,$06,$06,$07,$07,$08,$08,$09,$09
	.byte $0a,$0b,$0b,$0c,$0d,$0d,$0e,$0f,$10,$11,$12,$13
	.byte $14,$16,$17,$18,$1a,$1b,$1d,$1f,$21,$23,$25,$27
	.byte $29,$2c,$2e,$31,$34,$37,$3b,$3e,$42,$46,$4a,$4e
	.byte $53,$58,$5d,$63,$69,$6f,$76,$7d,$84,$8c,$94,$9d
	.byte $a7,$b0,$bb,$c6,$d2,$de,$ec,$fa,$09,$18,$29,$3b
	.byte $4e,$61,$76,$8d,$a4,$bd,$d8,$f4,$12,$31,$53,$76
	.byte $9c,$c3,$ed,$1a,$49,$7b,$b0,$e8

; Lookup table to find whether op is a carrier, per alg
fm_op_alg_carrier:
	; ALG   0   1   2   3   4   5   6   7
	.byte $00,$00,$00,$00,$00,$00,$00,$01 ; M1 (1)
	.byte $00,$00,$00,$00,$00,$01,$01,$01 ; M2 (3)
	.byte $00,$00,$00,$00,$01,$01,$01,$01 ; C1 (2)
	.byte $01,$01,$01,$01,$01,$01,$01,$01 ; C2 (4)
	; alg 0  1->2->3->4
	; alg 1  (1+2)->3->4
	; alg 2  (1+(2->3))->4
	; alg 3  ((1->2)+3)->4
	; alg 4  1->2, 3->4
	; alg 5  1->(2+3+4)
	; alg 6  1->2, 3, 4
	; alg 7  1, 2, 3, 4

