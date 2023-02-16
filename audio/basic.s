; Code by Barry Yost (a.k.a. ZeroByte) and MooingLemur
; - 2022

; This file is for code that underpins BASIC functions, but re-homed into the
; audio bank for saving storage space in the BASIC bank (4) and giving immediate
; (i.e. non-jsrfar) access to utility functions within the audio ROM.

.export bas_fmfreq
.export bas_fmnote
.export bas_fmvib
.export bas_psgfreq
.export bas_psgnote
.export bas_psgwav

.importzp azp0, azp0L, azp0H

.import psg_playfreq
.import psg_setvol
.import psg_write
.import ym_playnote
.import ym_release
.import ym_write
.import notecon_bas2fm
.import notecon_bas2psg
.import notecon_freq2psg
.import notecon_freq2fm

;-----------------------------------------------------------------
; bas_fmfreq
;-----------------------------------------------------------------
; Sets FM frequency in Hz
; inputs: .A = channel
;         .X = LSB Hz
;         .Y = MSB Hz
;         .C set = no retrigger
;-----------------------------------------------------------------
.proc bas_fmfreq: near
	php              ; store the C flag on the stack...
	cpx #0
	bne hz
	cpy #0
	bne hz
	plp
	jmp ym_release
hz:
	pha              ; save channel
	jsr notecon_freq2fm
	bcs error
	pla              ; restore channel
	plp              ; retreive C flag from stack
	jmp ym_playnote
error:
	pla
	plp
	sec
	rts
.endproc

;-----------------------------------------------------------------
; bas_fmnote
;-----------------------------------------------------------------
; inputs: .A = channel
;         .X = high nybble octave (0-7), low nybble note (1-12)
;              if low nybble is 0, release note
;              if low nybble is 13-15, no-op return
;         .Y = fractional semitone (YM2151 KF, 0 = unaltered note)
;         .C set = no retrigger
;-----------------------------------------------------------------
.proc bas_fmnote: near
	php              ; store the C flag on the stack...
	pha              ; save voice
	txa
	and #$0F         ; ignore high nybble bits.
	beq release
	cmp #13
	bcs noop
playnote:
	jsr notecon_bas2fm
	bcs error
	pla              ; restore voice
	plp              ; retreive C flag from stack
	jmp ym_playnote
noop:
	pla           
	plp              ; clear the stack	              
	clc              ; result = success
	rts
release:
	pla
	plp
	jmp ym_release
error:
	pla
	plp
	sec
	rts
.endproc

;-----------------------------------------------------------------
; bas_fmvib
;-----------------------------------------------------------------
; Sets YM2151 LFO freq, PMD/AMD, and set Waveform to Triangle
; inputs: .A = speed (frequency)
;         .X = depth (PMD and AMD)
;-----------------------------------------------------------------
.proc bas_fmvib: near
	phx ; save depth
	ldx #$18 ; LFO freq register
	jsr ym_write
	bcs error1
	inx ; $19, LFO amplitude
	pla ; depth in A
	jsr ym_write ; write PMD or AMD
	bcs error2
	eor #$80
	jsr ym_write ; write the other one
	bcs error2
	ldx #$1B ; LFO waveform
	lda #2 ; Triangle
	jmp ym_write ; write to YM and we're outta here
error1:
	plx
error2:
	; implied sec - carry already set
	rts
.endproc

;-----------------------------------------------------------------
; bas_psgfreq
;-----------------------------------------------------------------
; Sets PSG frequency in Hz
; inputs: .A = voice
;         .X = LSB Hz
;         .Y = MSB Hz
;-----------------------------------------------------------------
.proc bas_psgfreq: near
	cpx #0
	bne hz
	cpy #0
	bne hz
	jmp psg_setvol ; input of 0 means voice off
hz:
	pha
	jsr notecon_freq2psg
	bcs error
	pla
	jmp psg_playfreq
error:
	pla
	; implied sec - carry already set
	rts
.endproc



;-----------------------------------------------------------------
; bas_psgnote
;-----------------------------------------------------------------
; inputs: .A = voice
;         .X = high nybble octave (0-7), low nybble note (1-12)
;              if low nybble is 0, release note
;              if low nybble is 13-15, no-op return
;         .Y = fractional semitone (Like YM2151 KF, 0 = unaltered note)
;-----------------------------------------------------------------
.proc bas_psgnote: near
	pha              ; save voice
	txa
	and #$0F         ; ignore high nybble bits.
	beq release
	cmp #13
	bcs noop
playnote:
	jsr notecon_bas2psg
	bcs error
	pla              ; restore voice
	jmp psg_playfreq
noop:
	pla           
	clc              ; result = success
	rts
release:
	pla
	ldx #$00
	jmp psg_setvol
error:
	pla
	sec
	rts
.endproc

;-----------------------------------------------------------------
; bas_psgwav
;-----------------------------------------------------------------
; Sets PSG waveform and duty cycle
; inputs: .A = voice
;         .X = waveform + duty
;            0-63 pulse wave with ~1%-50% duty cycle
;            64-127 = Sawtooth
;            128-191 = Triangle
;            192-255 = Noise
;-----------------------------------------------------------------
.proc bas_psgwav: near
	and #$0F
	asl
	asl
	clc
	adc #3
	phx
	tax
	pla
	jmp psg_write
.endproc
