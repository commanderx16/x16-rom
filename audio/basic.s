; Code by Barry Yost (a.k.a. ZXeroByte)
; - 2022

; This file is for code that underpins BASIC functions, but re-homed into the
; audio bank for saving storage space in the BASIC bank (4) and giving immediate
; (i.e. non-jsrfar) access to utility functions within the audio ROM.

.export bas_fmnote

.importzp r0, r0L, r0H


.import ym_playnote
.import notecon_bas2fm

; tmp just to get it building:
.import ym_write

; .A = voice, .X = note  .Y was supposed to be octave (unused)
; NOTE: .Y reserved to be "volume?"
; masks voice to range 0-7
; note is bit-stuffed as 0-3=note, 4-6=octave, 7=ignored
.proc bas_fmnote: near
    and #$07 ; mask voice to range 0..7
    sta	r0L  ; raw voice number
    lda #0
    rol      ; get C flag as LSB and store to r0H
    sta r0H
    jsr notecon_bas2fm
    bcc continue
    rts      ;
continue:
    txa      ; get original value from .X again....
    and #$0F ; mask for the note bits
    bne play01
release:
    lda r0L  ; voice number to be released
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
		lda	r0L
	jsr ym_write

	; turn off any playing note
		ldx #$08	; key on/off register
		pla 		; should have 0s in the high 5 bits because of the cmp #8
		sta r0L		; re-use r0L for the channel
	jsr ym_write

	; turn on new note
		clc
		lda #$78
		adc r0L
		; X should have been presevered from the last write
	jsr ym_write
fail:
		rts ; return C set as failed patch write.
success:
    clc
    rts
.endproc
