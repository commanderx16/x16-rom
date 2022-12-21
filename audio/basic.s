; Code by Barry Yost (a.k.a. ZeroByte)
; - 2022

; This file is for code that underpins BASIC functions, but re-homed into the
; audio bank for saving storage space in the BASIC bank (4) and giving immediate
; (i.e. non-jsrfar) access to utility functions within the audio ROM.

.export bas_fmnote

.importzp azp0, azp0L, azp0H


.import ym_playnote
.import ym_release
.import notecon_bas2fm

; tmp just to get it building:
.import ym_write

;-----------------------------------------------------------------
; bas_fmnote
;-----------------------------------------------------------------
; inputs: .A = voice, .X = note  .Y = octave  .C set = no retrigger
;-----------------------------------------------------------------
; If note = 0, this is interpreted as a release.
; If note > 12, this is a no-op and returns w/o error
; Else, note and octave are packed into a single byte and the fm routines are
; used to play the specified note.
;
.proc bas_fmnote: near
  php              ; store the C flag on the stack...
  sta azp0L        ; voice
  txa
  and #$0F         ; ignore high nybble bits.
  cmp #13
  bcs noop
  cmp #0
  bne playnote
  lda azp0L
  plp              ; clear the stack (C irrelevant to ym_release)
  jmp ym_release   ; note was 0. Just release the voice
playnote:
  ; combine note and oct into single byte
  sta azp0H        ; note nybble
  tya
  asl
  asl
  asl
  asl              ; oct << 4
  ora azp0H
  ; convert note byte into YM note values
  tax
  jsr notecon_bas2fm
  lda azp0L        ; voice #
  plp              ; retreive C flag from stack
  jmp ym_playnote
noop:
  plp              ; clear the stack
  clc              ; result = success
  rts
.endproc

; disable original code - kept here for reference purposes....
.if 0
.proc bas_fmnote: near
	and #$07 ; mask voice to range 0..7
	sta	azp0L  ; raw voice number
	lda #0
	rol      ; get C flag as LSB and store to azp0H
	sta azp0H
	jsr notecon_bas2fm
	bcc continue
	rts      ;
continue:
	txa      ; get original value from .X again....
	and #$0F ; mask for the note bits
	bne play01
release:
	lda azp0H  ; voice number to be released
	ldx #08  ; select the KCONTROL register
	jmp ym_write
play01:
	cmp #13  ; note values >= 13 are NOP. Just return.
	bcc play02
	rts
play02:
	; convert 1-12 note index into native YM indexing
	dex ; range now 0..11
	; add spacing for notes 4, 8, and 12
	cmp #12
	bcs inc3
	cmp #8
	bcs inc2
	cmp #4
	bcs inc1
	bra inc0
inc3:
	inx
inc2:
	inx
inc1:
	inx
inc0:
	phx
	adc	#$28 ; register for the selected voice
	tax
	lda	azp0H
	jsr ym_write

	; turn off any playing note
	ldx #$08	; key on/off register
	pla 		; should have 0s in the high 5 bits because of the cmp #8
	sta azp0H		; re-use azp0H for the channel
	jsr ym_write

	; turn on new note
	clc
	lda #$78
	adc azp0H
	; X should have been presevered from the last write
	jsr ym_write
fail:
	rts ; return C set as failed patch write.
success:
	clc
	rts
.endproc
.endif
