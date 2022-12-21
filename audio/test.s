.export patches_lo, patches_hi

.import ym_write, ym_loadpatch, ym_loadpatch_rom, ym_playnote, ym_setnote
.import ym_trigger, ym_release
.import bas_fmnote

.import notecon_fm2bas
.import notecon_psg2bas
.import notecon_midi2bas
.import notecon_freq2bas
.import notecon_bas2fm
.import notecon_psg2fm
.import notecon_freq2fm
.import notecon_midi2fm
.import notecon_bas2psg
.import notecon_fm2psg
.import notecon_freq2psg
.import notecon_midi2psg


.segment "API"
	jmp ym_write
	jmp ym_loadpatch
	jmp ym_loadpatch_rom
	jmp ym_playnote
	jmp ym_setnote
	jmp ym_trigger
	jmp ym_release
	jmp bas_fmnote
	; note that most of these are stubs that return error (.X and .Y = 0)
	jmp notecon_fm2bas
	jmp notecon_psg2bas
	jmp notecon_midi2bas
	jmp notecon_freq2bas
	jmp notecon_bas2fm
	jmp notecon_psg2fm
	jmp notecon_freq2fm
	jmp notecon_midi2fm
	jmp notecon_bas2psg
	jmp notecon_fm2psg
	jmp notecon_freq2psg
	jmp notecon_midi2psg

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

.include "banks.inc"
.segment "VECTORS"
 .byt $ff, $ff, $ff, $ff, <banked_irq, >banked_irq
