; Code by Jestin Stoffel
; - 2022

; This file is for implementing the BASIC statements having to do with sound.
; It will be used for any statements relating to either the VERA's PSG or PCM
; sound capabilities, or the YM2151 FM synthesizer.

.setcpu "65c02"

;***************
fmnote:
	jsr get_channel
	pha				; push the channel
	jsr chkcom
	jsr get_note
	pla		; channel
	jsr jsrfar
	.word $c000 + 3 * 9
	.byte $0A
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
	.word $c000 + 3 * 2
	.byte $0A
	rts

;***************
psgnote:
	nop
	rts

;***************
psginst:
	nop
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
	cmp #32
	bcs channel_error
	rts

;---------------------------------------------------------------
; Reads and validates a note argument
;---------------------------------------------------------------
; inputs: none
; returns: .X with the note, .Y with the octave
;
get_note:
	jsr frmnum
	lda facsgn
	pha
	stz facsgn
	jsr conint
	txa
	lsr
	lsr
	lsr
	lsr
	cmp #8
	bcs octave_error
	tay
	txa
	and #$0f
	tax
	pla
	cmp #$ff
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
