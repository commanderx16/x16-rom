; Code by Jestin Stoffel
; - 2022-2023

; This file is for implementing the BASIC statements having to do with sound.
; It will be used for any statements relating to either the VERA's PSG or PCM
; sound capabilities, or the YM2151 FM synthesizer.

.setcpu "65c02"
.include "audio.inc"

.macro audio_call addr
    jsr jsrfar
    .word addr
    .byte BANK_AUDIO
.endmacro

;---------------------------------------------------------------
; FMINIT
;---------------------------------------------------------------
fminit:
	audio_call ym_init
	audio_call ym_loaddefpatches
	rts

;---------------------------------------------------------------
; FMFREQ <channel>,<frequency>
;---------------------------------------------------------------
fmfreq:
	jsr get_fmchannel
	pha                ; push the channel
	jsr chkcom
	jsr get_freq
	pla                ; channel
	clc
	audio_call bas_fmfreq
	bcc :+            ; let the bank do additional validation for fm
	jmp freq_error
:
	rts

;---------------------------------------------------------------
; FMNOTE <channel>,<note>
;---------------------------------------------------------------
fmnote:
	jsr get_fmchannel
	pha                ; push the channel
	jsr chkcom
	jsr get_note
	pla                ; channel
	audio_call bas_fmnote
	rts

;---------------------------------------------------------------
; FMDRUM <channel>,<drum>
;---------------------------------------------------------------
fmdrum:
	jsr get_fmchannel
	pha                ; push the channel
	jsr chkcom
	jsr get_drum
	pla                ; channel
	audio_call ym_playdrum
	rts

;---------------------------------------------------------------
; FMINST <channel>,<instrument>
;---------------------------------------------------------------
fminst:
	jsr get_fmchannel
	pha                ; push the channel
	jsr chkcom
	jsr get_inst
	tax
	pla
	sec                ; load from rom
	audio_call ym_loadpatch
	rts

;---------------------------------------------------------------
; FMVIB <speed>,<depth>
;---------------------------------------------------------------
fmvib:
	jsr getbyt
	phx                ; push the speed
	jsr chkcom
	jsr get_depth
	pla
	audio_call bas_fmvib
	rts

;---------------------------------------------------------------
; FMVOL <channel>,<volume>
;---------------------------------------------------------------
fmvol:
	jsr get_fmchannel
	pha                ; push the channel
	jsr chkcom
	jsr get_vol
	ora #0
	bne :+
	lda #$40
:
	eor #$3f
	tax
	pla                ; channel
	audio_call ym_setatten
	rts

;---------------------------------------------------------------
; FMPAN <channel>,<pan>
;---------------------------------------------------------------
fmpan:
	jsr get_fmchannel
	pha                ; push the channel
	jsr chkcom
	jsr get_pan
	pla
	audio_call ym_setpan
	rts

;---------------------------------------------------------------
; FMPLAY <channel>,<playstring>
;---------------------------------------------------------------
fmplay:
	jsr get_fmchannel
	audio_call bas_playstringvoice
	jsr chkcom
	jsr frmstr
	audio_call bas_fmplaystring
	rts

;---------------------------------------------------------------
; FMCHORD <channel>,<chordstring>
;---------------------------------------------------------------
fmchord:
	jsr get_fmchannel
	audio_call bas_playstringvoice
	jsr chkcom
	jsr frmstr
	audio_call bas_fmchordstring
	rts

;---------------------------------------------------------------
; FMPOKE <register>,<value>
;---------------------------------------------------------------
fmpoke:
	jsr getbyt
	phx                ; push the register
	jsr chkcom
	jsr getbyt
	txa
	plx                ; pull the register
	audio_call ym_write
	rts

;---------------------------------------------------------------
; PSGNOTE <channel>,<note>
;---------------------------------------------------------------
psgnote:
	jsr get_psgchannel
	pha                ; push the channel
	jsr chkcom
	jsr get_note
	pla                ; channel
	audio_call bas_psgnote
	rts

;---------------------------------------------------------------
; PSGFREQ <channel>,<freq>
;---------------------------------------------------------------
psgfreq:
	jsr get_psgchannel
	pha                ; push the channel
	jsr chkcom
	jsr get_freq
	pla                ; channel
	audio_call bas_psgfreq
	rts

;---------------------------------------------------------------
; PSGWAV <channel>,<wave>
;---------------------------------------------------------------
psgwav:
	jsr get_psgchannel
	pha                ; push the channel
	jsr chkcom
	jsr getbyt
	pla                ; channel
	audio_call bas_psgwav
	rts

;---------------------------------------------------------------
; PSGINIT
;---------------------------------------------------------------
psginit:
	audio_call psg_init
	rts

;---------------------------------------------------------------
; PSGVOL <channel>,<volume>
;---------------------------------------------------------------
psgvol:
	jsr get_psgchannel
	pha                ; push the channel
	jsr chkcom
	jsr get_vol
	eor #$3f
	tax
	pla                ; channel
	audio_call psg_setatten
	rts

;---------------------------------------------------------------
; PSGPAN <channel>,<pan>
;---------------------------------------------------------------
psgpan:
	jsr get_psgchannel
	pha                ; push the channel
	jsr chkcom
	jsr get_pan
	pla                ; channel
	audio_call psg_setpan
	rts

;---------------------------------------------------------------
; PSGPLAY <channel>,<playstring>
;---------------------------------------------------------------
psgplay:
	jsr get_psgchannel
	audio_call bas_playstringvoice
	jsr chkcom
	jsr frmstr
	audio_call bas_psgplaystring
	rts

;---------------------------------------------------------------
; PSGCHORD <channel>,<chordstring>
;---------------------------------------------------------------
psgchord:
	jsr get_psgchannel
	audio_call bas_playstringvoice
	jsr chkcom
	jsr frmstr
	audio_call bas_psgchordstring
	rts

;---------------------------------------------------------------
; Reads and validates an FM channel argument
;---------------------------------------------------------------
; inputs: none
; returns: .A with the channel 0-7
; errors: displays error if channel > 7 or channel < 0
;
get_fmchannel:
	jsr getbyt
	txa
	cmp #8
	bcs channel_error
	rts

;---------------------------------------------------------------
; Reads and validates an PSG channel argument
;---------------------------------------------------------------
; inputs: none
; returns: .A with the channel 0-15
; errors: displays error if channel > 15 or channel < 0
;
get_psgchannel:
	jsr getbyt
	txa
	cmp #16
	bcs channel_error
	rts

;---------------------------------------------------------------
; Reads and validates an instrument argument
;---------------------------------------------------------------
; inputs: none
; returns: .A with the instrument 0-162
; errors: displays error if instrument > 162 or instrument < 0
;
get_inst:
	jsr getbyt
	txa
	cmp #163
	bcs instrument_error
	rts

;---------------------------------------------------------------
; Reads and validates a note argument
;---------------------------------------------------------------
; inputs: none
; outputs: .X = high nybble octave (0-7), low nybble note (1-12)
;              if low nybble is 0, release note
;              if low nybble is 13-15, no-op return
;         .Y = 0 (no semi-tones set from BASIC)
;         .C set = the input for was negative
; errors: displays error if octave > 7
;
get_note:
	jsr frmnum
	lda facsgn
	pha                ; store for later to set `.C` from
	stz facsgn         ; required or else conint will throw error
	jsr conint
	txa
	lsr
	lsr
	lsr
	lsr
	cmp #8
	bcs octave_error
	ldy #0             ; no semi-tones from BASIC
	pla
	cmp #$ff           ; if facsgn was $ff, the value was negative
	rts

;---------------------------------------------------------------
; Reads and validates a frequency argument
;---------------------------------------------------------------
; inputs: none
; returns: .X (lo) and .Y (hi) with 16-bit freq
; errors: displays error if frequency >= $5f00 or frequency < 0
;
get_freq:
	jsr frmadr
	ldx poker
	ldy poker+1
	cpy #$5f
	bcs freq_error
	rts

;---------------------------------------------------------------
; Reads and validates a PSG volume argument
;---------------------------------------------------------------
; inputs: none
; returns: .A
; errors: displays error if volume >= 64 or volume < 0
;
get_vol:
	jsr getbyt
	txa
	cmp #64
	bcs volume_error
	rts

;---------------------------------------------------------------
; Reads and validates a FM drum instrument argument
;---------------------------------------------------------------
; inputs: none
; returns: .X
; errors: displays error if drum >= 88 or drum < 25
;
get_drum:
	jsr getbyt
	txa
	beq :+
	cmp #88
	bcs drum_error
	cmp #25
	bcc drum_error
:
	rts

;---------------------------------------------------------------
; Reads and validates a FM vibrato depth argument
;---------------------------------------------------------------
; inputs: none
; returns: .X
; errors: displays error if depth >= 128 or depth < 0
;
get_depth:
	jsr getbyt
	txa
	cmp #128
	bcs depth_error
	rts

;---------------------------------------------------------------
; Reads and validates a pan argument
;---------------------------------------------------------------
; inputs: none
; returns: .X
; errors: displays error if pan >= 4 or pan < 1
;
get_pan:
	jsr getbyt
	txa
	beq pan_error
	cmp #4
	bcs pan_error
	rts

;***************
channel_error:
	ldx #erchan
	jmp error

;***************
instrument_error:
	ldx #erinst
	jmp error

;***************
octave_error:
	ldx #eroct
	jmp error

;***************
volume_error:
	ldx #ervol
	jmp error

;***************
drum_error:
	ldx #erdrum
	jmp error

;***************
depth_error:
	ldx #erdep
	jmp error
;***************
freq_error:
	ldx #erfrq
	jmp error
;***************
pan_error:
	ldx #erpan
	jmp error
