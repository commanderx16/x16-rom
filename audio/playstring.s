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

.import audio_bank_refcnt, audio_prev_bank

.importzp azp0, azp0L, azp0H

.import notecon_midi2fm
.import notecon_midi2psg

.import ym_release
.import ym_playnote

.import psg_setvol
.import psg_playfreq

.export bas_ymplaystring
.export bas_psgplaystring

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


.proc parsestring: near
	; all registers can be used, interrupts are disabled
	; temp variables are also fair game right now
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
	bne tempo_t
	ldx #0
	jsr check_notelen
	txa
	bra done

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
	bne articulation_s
	lda playstring_octave
	inc
	cmp #8
	bcc :+
	lda #7
:	sta playstring_octave
	jmp parsestring

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

	lda (azp0),y
	cmp #'+'
	bne :+
	inx
	iny
	inc playstring_pos
:	cmp #'-'
	bne @end
	dex
	iny
	inc playstring_pos
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
	lda #192
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

.proc bas_ymplaystring
; inputs: .A = voice, .X .Y = pointer to CBM BASIC style string structure
;
; string structure: Byte 0: <string length>
;                   Byte 1: <string pointer LSB>
;                   Byte 2: <string pointer MSB>
;
; affects: .A .X .Y
; returns: C set on error
	phy
	PRESERVE_AND_SET_BANK
	ply

	sta playstring_voice
	stx azp0L
	sty azp0H

	lda (azp0)
	sta playstring_len
	stz playstring_pos

	ldy #1
	lda (azp0),y ; string ptr LSB
	tax
	iny
	lda (azp0),y ; string ptr MSB

	stx azp0L ; string ptr LSB
	sta azp0H ; string ptr MSB
	
	; azp0 now points to our note string
noteloop:
	jsr parsestring
    bcc :+
	jmp end
:	ora #0
	beq rest

	tax
	ldy #0
	jsr notecon_midi2fm
	lda playstring_voice

	clc
	jsr ym_playnote
	bra wait
rest:
	lda playstring_voice
	jsr ym_release
wait:
    clc
    jsr playstring_wait
	lda playstring_voice
	jsr ym_release
    sec
    jsr playstring_wait
    bra noteloop
fail:
	RESTORE_BANK
	sec
	rts
end:
	lda playstring_voice
	jsr ym_release
	RESTORE_BANK
	clc
	rts
.endproc

.proc bas_psgplaystring
; inputs: .A = voice, .X .Y = pointer to CBM BASIC style string structure
;
; string structure: Byte 0: <string length>
;                   Byte 1: <string pointer LSB>
;                   Byte 2: <string pointer MSB>
;
; affects: .A .X .Y
; returns: C set on error
	phy
	PRESERVE_AND_SET_BANK
	ply

	sta playstring_voice
	stx azp0L
	sty azp0H

	lda (azp0)
	sta playstring_len
	stz playstring_pos

	ldy #1
	lda (azp0),y ; string ptr LSB
	tax
	iny
	lda (azp0),y ; string ptr MSB

	stx azp0L ; string ptr LSB
	sta azp0H ; string ptr MSB
	
	; azp0 now points to our note string
noteloop:
	jsr parsestring
    bcc :+
	jmp end
:	ora #0
	beq rest

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
	lda playstring_voice
	ldx #0
    jsr psg_setvol
    sec
    jsr playstring_wait
    bra noteloop
fail:
	RESTORE_BANK
	sec
	rts
end:
	lda playstring_voice
	ldx #0
    jsr psg_setvol
	RESTORE_BANK
	clc
	rts
.endproc

