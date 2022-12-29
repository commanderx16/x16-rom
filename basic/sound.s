; Code by Jestin Stoffel
; - 2022

; This file is for implementing the BASIC statements having to do with sound.
; It will be used for any statements relating to either the VERA's PSG or PCM
; sound capabilities, or the YM2151 FM synthesizer.

.setcpu "65c02"
.include "audio.inc"

;***************
fminit:
	jsr jsrfar
	.word ym_init
	.byte BANK_AUDIO
	rts

;***************
fmfreq:
	jsr get_channel
	pha				; push the channel
	jsr chkcom
	jsr get_freq
	pla		; channel
	clc
	jsr jsrfar
	.word bas_fmhz
	.byte BANK_AUDIO
	rts

;***************
fmnote:
	jsr get_channel
	pha				; push the channel
	jsr chkcom
	jsr get_note
	pla		; channel
	jsr jsrfar
	.word bas_fmnote
	.byte BANK_AUDIO
	rts

;***************
fmdrum:
	jsr get_channel
	pha				; push the channel
	jsr chkcom
	jsr get_drum
	pla		; channel
	jsr jsrfar
	.word ym_playdrum
	.byte BANK_AUDIO
	rts

;***************
fminst:
	jsr get_channel
	pha				; push the channel
	jsr chkcom
	jsr get_inst
	tax
	pla
	sec				; load from rom
	jsr jsrfar
	.word ym_loadpatch
	.byte BANK_AUDIO
	rts

;***************
fmvib:
	jsr getbyt
	phx				; push the speed
	jsr chkcom
	jsr get_depth
	pla
	jsr jsrfar
	.word bas_fmvib
	.byte BANK_AUDIO
	rts

;***************
psgnote:
	jsr get_channel
	pha				; push the channel
	jsr chkcom
	jsr get_note
	pla				; channel
	jsr jsrfar
	.word bas_psgnote
	.byte BANK_AUDIO
	rts

;***************
psgfreq:
	jsr get_channel
	pha				; push the channel
	jsr chkcom
	jsr get_freq
	pla				; channel
	jsr jsrfar
	.word bas_psghz
	.byte BANK_AUDIO
	rts

;***************
psgwav:
	jsr get_channel
	pha				; push the channel
	jsr chkcom
	jsr getbyt
	pla		; channel
	jsr jsrfar
	.word bas_psgwav
	.byte BANK_AUDIO
	rts

;***************
psginit:
	jsr jsrfar
	.word psg_init
	.byte BANK_AUDIO
	rts

;***************
psgvol:
	jsr get_channel
	pha				; push the channel
	jsr chkcom
	jsr get_vol
	eor #$3f
	tax
	pla				; channel
	jsr jsrfar
	.word psg_setatten
	.byte BANK_AUDIO
	rts

;---------------------------------------------------------------
; Reads and validates a channel argument
;---------------------------------------------------------------
; inputs: none
; returns: .A with the channel 0-7
;
get_channel:
	jsr getbyt
	txa
	cmp #8
	bcs channel_error
	rts

;---------------------------------------------------------------
; Reads and validates an instrument argument
;---------------------------------------------------------------
; inputs: none
; returns: .A with the instrument 0-31
;
get_inst:
	jsr getbyt
	txa
	cmp #128
	bcs channel_error
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
;
get_note:
	jsr frmnum
	lda facsgn
	pha			; store for later to set `.C` from
	stz facsgn	; required or else conint will throw error
	jsr conint
	txa
	lsr
	lsr
	lsr
	lsr
	cmp #8
	bcs octave_error
	ldy #0		; no semi-tones from BASIC
	pla
	cmp #$ff	; if facsgn was $ff, the value was negative
	rts

get_freq:
	jsr frmadr
	ldx poker
	ldy poker+1
	cpy #$5f
	bcs freq_error
	rts

get_vol:
	jsr getbyt
	txa
	cmp #64
	bcs volume_error
	rts

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

get_depth:
	jsr getbyt
	txa
	cmp #128
	bcs depth_error
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
