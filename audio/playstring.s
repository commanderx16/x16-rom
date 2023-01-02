; Code by MooingLemur
; - 2022
; This file is for code dealing with the blocking note playback via
; string

.setcpu "65c02"

.include "io.inc" ; for YM2151 addresses

.import playstring_len
.import playstring_notelen
.import playstring_octave
.import playstring_pos
.import playstring_tempo
.import playstring_voice
.import playstring_art

.import playstring_tmp1
.import playstring_tmp2
.import playstring_tmp3
.import playstring_tmp4
.import playstring_ymcnt

.import audio_bank_refcnt, audio_prev_bank

.importzp azp0, azp0L, azp0H

.import notecon_midi2fm
.import notecon_midi2psg

.import ym_release
.import ym_playnote
.import ym_setatten
.import ym_setpan

.import psg_setvol
.import psg_playfreq
.import psg_setatten
.import psg_setpan

.export bas_fmplaystring
.export bas_psgplaystring
.export bas_playstringvoice

.macro PRESERVE_AND_SET_BANK
.scope
	ldy ram_bank
	stz ram_bank
	beq skip_preserve
	sty audio_prev_bank
skip_preserve:
	inc audio_bank_refcnt
.endscope
.endmacro

.macro RESTORE_BANK
.scope
	dec audio_bank_refcnt
	bne skip_restore
	ldy audio_prev_bank
	stz audio_prev_bank
	sty ram_bank
skip_restore:
.endscope
.endmacro


;-----------------------------------------------------------------
; parsestring
;-----------------------------------------------------------------
; Internal routine that reads and processes the scripted note string
; and returns control after finding a note
; 
; This routine sets up other state in playstring_* variables as
; it reads the script data such as octave and tempo
;
; inputs: none
; affects: .A .X .Y
; returns: .A = 0 = rest, 12+ midi note
;-----------------------------------------------------------------
.proc parsestring: near
	; all registers can be used
	; all tmp[1-4] temp variables are also fair game right now
	ldy playstring_pos
	cpy playstring_len
	bcc :+
	jmp fail
:	lda (azp0),y
	inc playstring_pos
	iny

note_c:
	cmp #'C'
	bne note_d
	ldx #12
	jmp finish_note

note_d:
	cmp #'D'
	bne note_e
	ldx #14
	jmp finish_note

note_e:
	cmp #'E'
	bne note_f
	ldx #16
	jmp finish_note

note_f:
	cmp #'F'
	bne note_g
	ldx #17
	jmp finish_note

note_g:
	cmp #'G'
	bne note_a
	ldx #19
	jmp finish_note

note_a:
	cmp #'A'
	bne note_b
	ldx #21
	jmp finish_note

note_b:
	cmp #'B'
	bne rest_r
	ldx #23
	jmp finish_note

rest_r:
	cmp #'R'
	bne length_l
	ldx #0
	jsr check_notelen
	txa
	bra done

length_l:
	cmp #'L'
	bne tempo_t
	ldx #0
	jsr check_notelen
	jmp parsestring

tempo_t:
	cmp #'T'
	bne octave_o
	jmp check_tempo

octave_o:
	cmp #'O'
	bne octave_down
	jmp check_octave

octave_down:
	cmp #'<'
	bne octave_up
	lda playstring_octave
	dec
	bpl :+
	lda #0
:	sta playstring_octave
	jmp parsestring

octave_up:
	cmp #'>'
	bne volume_v
	lda playstring_octave
	inc
	cmp #8
	bcc :+
	lda #7
:	sta playstring_octave
	jmp parsestring

volume_v:
	cmp #'V'
	bne panning_p
	jsr parse_number
	ldx playstring_tmp2 ; digit count, we don't want to process
						; a bare V with no number after it, but
						; if someone says V0, we do want it
	bne :+
	jmp parsestring
:	tax
	lda #1
	rts ; returns parsed volume in X

panning_p:
	cmp #'P'
	bne articulation_s
	jsr parse_number
	tax
	lda #2
	rts ; returns parsed pan in X

articulation_s:
	cmp #'S'
	beq check_articulation
	jmp parsestring

done: ; we're returning a note or rest
	clc
	rts

fail: ; string is completely parsed
	sec
	rts

finish_note:
	jsr check_accidental
	jsr check_notelen
	txa
	ldy playstring_octave
:
	beq done
	clc
	adc #12
	dey
	bra :-

check_articulation:
	cpy playstring_len
	beq @end

	lda (azp0),y
	cmp #'0'
	bcs :+
	jmp parsestring ; O followed by PETSCII value < '0'
:	cmp #('9'+1)
	bcc :+
	jmp parsestring ; O followed by PETSCII value > '9'
:	sbc #('0'-1) ; carry is clear so subtracting takes and extra one away
	cmp #8
	bcc :+
	lda #7 ; clamp to octave 7
:	sta playstring_art
	inc playstring_pos ; advance to next byte in string
@end:
	jmp parsestring


check_octave:
	cpy playstring_len
	beq @end

	lda (azp0),y
	cmp #'0'
	bcs :+
	jmp parsestring ; O followed by PETSCII value < '0'
:	cmp #('9'+1)
	bcc :+
	jmp parsestring ; O followed by PETSCII value > '9'
:	sbc #('0'-1) ; carry is clear so subtracting takes and extra one away
	cmp #8
	bcc :+
	lda #7 ; clamp to octave 7
:	sta playstring_octave
	inc playstring_pos ; advance to next byte in string
@end:
	jmp parsestring

check_accidental:
	cpy playstring_len
	bcs @end
@acc_loop:
	lda (azp0),y
	cmp #'+'
	bne :+
	inx
	iny
	inc playstring_pos
	bra @acc_loop
:	cmp #'#'
	bne :+
	inx
	iny
	inc playstring_pos
	bra @acc_loop
:	cmp #'-'
	bne @end
	dex
	iny
	inc playstring_pos
	bra @acc_loop
@end:
	rts

check_tempo:
	jsr parse_number
	beq @end

	sta playstring_tempo

@end:
	jmp parsestring

check_notelen:
	; notelen = 240, whole note, divided by what we get back here
	jsr parse_number
	beq @nonum

	sta playstring_tmp1 ; denominator
	lda #240
	sta playstring_notelen ; numerator

	lda #0
	ldy #8
	asl playstring_notelen
@l1:
	rol
	cmp playstring_tmp1
	bcc @l2
	sbc playstring_tmp1
@l2:
	rol playstring_notelen
	dey
	bne @l1
	
@nonum:
	; now check for dots
	lda playstring_notelen
@dotloop:
	lsr
	sta playstring_tmp1 ; value of dot is half of what we last looked at

	ldy playstring_pos
	cpy playstring_len
	bcs @end

	lda (azp0),y
	cmp #'.'
	bne @end

	lda playstring_tmp1
	clc
	adc playstring_notelen
	sta playstring_notelen

	inc playstring_pos

	lda playstring_tmp1
	bra @dotloop

@end:
	rts


parse_number:
	stz playstring_tmp1 ; temp space
	stz playstring_tmp2 ; temp for digit count
@loop:
	ldy playstring_pos
	cpy playstring_len
	bcs @done

	lda (azp0),y
	cmp #'0' ; less than PETSCII '0'?
	bcc @done

	cmp #('9'+1) ; greater than PETSCII '9'?
	bcs @done

	sbc #('0'-1) ; carry is clear so subtracting takes and extra one away
	pha ; stash the value

	inc playstring_tmp2 ; found a digit

	; multiply the existing value by 10, comments are example with "3"
	asl playstring_tmp1  ; 3 -> 6
	lda playstring_tmp1  ; 
	asl                  ; 6 -> 12
	asl                  ; 12 -> 24
	clc
	adc playstring_tmp1  ; 24+6 = 30
	sta playstring_tmp1
	pla
	adc playstring_tmp1  ; 30 + value we just got
	sta playstring_tmp1

	inc playstring_pos
	bra @loop
@done:
	lda playstring_tmp1
	clc
	rts
.endproc

;-----------------------------------------------------------------
; playstring_wait
;-----------------------------------------------------------------
; Internal routine that waits a calculated number of ticks based
; on the note length.  Uses the WAI instruction, thus depends on
; the VBLANK interrupt being enabled and it being acknowledged.
;  
; The value of playstring_art is used to determine the proportion of
; playstring_notelen used for the note playback, and also that for the
; space in between notes. The carry flag is used to determine which
; part of the note (playback or space) we're delaying on
;
; inputs: .C clear = wait for playback portion
;         .C set = wait for space-in-between notes portion
; affects: .A .X .Y
; returns: none
;-----------------------------------------------------------------
.proc playstring_wait: near
	php ; store carry flag
	lda playstring_notelen
	; frames to wait will be 60*notelen (60=quarter, 240=whole) / tempo
	sta playstring_tmp1
	lda #0

	; multiply by 60
	asl playstring_tmp1
	rol ; x2
	asl playstring_tmp1
	rol ; x4
	sta playstring_tmp2
	sta playstring_tmp4 ; save high byte x4
	lda playstring_tmp1
	sta playstring_tmp3 ; save low byte x4
	asl
	rol playstring_tmp2 ; x8
	asl
	rol playstring_tmp2 ; x16
	asl
	rol playstring_tmp2 ; x32
	asl
	rol playstring_tmp2 ; x64

	sec
	sbc playstring_tmp3 ; subtract the x4
	sta playstring_tmp1
	lda playstring_tmp2
	sbc playstring_tmp4
	;sta playstring_tmp2 
	; tmp1+accumulator holds notelen * 60

	; divide by tempo
	; would normally low high bits of the numerator here
	; but it's already loaded
	ldx #8
	asl playstring_tmp1
l1:
	rol
	bcs l2
	cmp playstring_tempo
	bcc l3
l2:
	sbc playstring_tempo
	sec
l3:
	rol playstring_tmp1
	dex
	bne l1

	; now we calculate the delays for different parts of the articulation
	; of the note, for instance if playstring_art = 1, the note is 7 ticks on
	; and one part off.

	plp ; retrieve carry flag
	bcs calc_rest
	lda #8
	sec
	sbc playstring_art
	bra do_mult
calc_rest:
	lda playstring_art
do_mult:
	stz playstring_tmp3
	stz playstring_tmp4
	tay
	beq mult_done
mult_loop:
	lda playstring_tmp1
	clc
	adc playstring_tmp3
	sta playstring_tmp3
	lda #0
	adc playstring_tmp4
	sta playstring_tmp4
	dey
	bne mult_loop
mult_done:
	lsr playstring_tmp4
	ror playstring_tmp3
	lsr playstring_tmp4
	ror playstring_tmp3
	lsr playstring_tmp4
	ror playstring_tmp3

	ldy playstring_tmp3
	cpy #0
	beq endwait
waitloop:
	wai
	dey
	bne waitloop
endwait:
	rts
.endproc

;-----------------------------------------------------------------
; bas_fmplaystring
;-----------------------------------------------------------------
; Takes a string of scripted notes, which plays in full before
; returning control to BASIC. Notes play on YM2151
; preparatory routines: bas_playstringvoice
; inputs: .A = string length
;         .X .Y = pointer to string
; affects: .A .X .Y
; returns: none
;-----------------------------------------------------------------
.proc bas_fmplaystring
	stx azp0L
	sty azp0H

	PRESERVE_AND_SET_BANK

	sta playstring_len
	stz playstring_pos
	stz playstring_ymcnt
	
	; azp0 now points to our note string
noteloop:
	jsr parsestring
	bcc :+
	jmp end
:	ora #0
	beq rest
	cmp #1
	beq volume
	cmp #2
	beq panning

	tax
	ldy #0
	jsr notecon_midi2fm
	
	; if legato, skip retrigger, unless it's the first note

	clc ; set up no trigger state
	lda playstring_art
	bne retrigger
	lda playstring_ymcnt
	beq retrigger
no_retrigger:
	sec
retrigger:
	lda playstring_voice
	jsr ym_playnote
	bra wait
rest:
	lda playstring_voice
	jsr ym_release
	lda #$FF
	sta playstring_ymcnt
wait:
	clc
	jsr playstring_wait
	inc playstring_ymcnt
	lda playstring_art
	beq noteloop ; legato, short circuit
	lda playstring_voice
	jsr ym_release
	stz playstring_ymcnt
	sec
	jsr playstring_wait
	bra noteloop
end:
	lda playstring_voice
	jsr ym_release
	RESTORE_BANK
	clc
	rts
volume:
	txa ; volume comes out of parsing in .X
	cmp #$40
	bcc :+
	lda #$3F ; clamp response to $3F
:	ora #0
	bne :+
	lda #$40
:	eor #$3F ; $3F - A, except when A = 0, then $7F
	tax
	lda playstring_voice
	jsr ym_setatten
	jmp noteloop
panning:
	txa ; panning comes out in .X
	and #3
	bne :+
	jmp noteloop ; panning 0 forbidden
:	tax
	lda playstring_voice
	jsr ym_setpan
	jmp noteloop

.endproc

;-----------------------------------------------------------------
; bas_psgplaystring
;-----------------------------------------------------------------
; Takes a string of scripted notes, which plays in full before
; returning control to BASIC. Notes play on the VERA PSG
; preparatory routines: bas_playstringvoice
; inputs: .A = string length
;         .X .Y = pointer to string
; affects: .A .X .Y
; returns: none
;-----------------------------------------------------------------
.proc bas_psgplaystring
	stx azp0L
	sty azp0H

	PRESERVE_AND_SET_BANK

	sta playstring_len
	stz playstring_pos
	
	; azp0 now points to our note string
noteloop:
	jsr parsestring
	bcc :+
	jmp end
:	ora #0
	beq rest
	cmp #1
	beq volume
	cmp #2
	beq panning

	tax
	ldy #0
	jsr notecon_midi2psg
	lda playstring_voice

	clc
	jsr psg_playfreq
	bra wait
rest:
	lda playstring_voice
	ldx #0
	jsr psg_setvol
wait:
	clc
	jsr playstring_wait
	lda playstring_art
	beq noteloop ; legato, short circuit
	lda playstring_voice
	ldx #0
	jsr psg_setvol
	sec
	jsr playstring_wait
	bra noteloop
end:
	lda playstring_voice
	ldx #0
	jsr psg_setvol
	stz playstring_len
	RESTORE_BANK
	clc
	rts
volume:
	txa ; volume comes out of parsing in .X
	cmp #$40
	bcc :+
	lda #$3F ; clamp response to $3F
:	eor #$3F ; $3F - A
	tax
	lda playstring_voice
	jsr psg_setatten
	bra noteloop
panning:
	txa ; panning comes out in .X
	and #3
	beq noteloop ; panning 0 forbidden
	tax
	lda playstring_voice
	jsr psg_setpan
	bra noteloop
.endproc

;-----------------------------------------------------------------
; bas_playstringvoice
;-----------------------------------------------------------------
; Sets the voice number for a subsequent bas_psgplaystring or
;   bas_ymplaystring
; inputs: .A = psg/fm voice number
; affects: .Y
; returns: none
;-----------------------------------------------------------------
.proc bas_playstringvoice: near
	PRESERVE_AND_SET_BANK
	sta playstring_voice
	RESTORE_BANK
	rts
.endproc
