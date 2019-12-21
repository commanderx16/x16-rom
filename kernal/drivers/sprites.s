;----------------------------------------------------------------------
; VERA Sprites Driver
;----------------------------------------------------------------------

; This code supports up to 32 sprites.

.include "../../io.inc"
.include "../../regs.inc"

.export sprite_set_image
.export sprite_set_position

.segment "SPRITES"

;---------------------------------------------------------------
; sprites_set_image
;
;   In:   .A     sprite number
;         .X     data width
;         .Y     data height
;         r0     pointer to data
;         r1L    data bits per pixel
;---------------------------------------------------------------
sprite_set_image:
	brk
	
;---------------------------------------------------------------
; sprites_set_position
;
;   In:   .A     sprite number
;         r0     x coordinate
;         r1     y coordinate
;
; Note: A negative x coordinate turns the sprite off.
;---------------------------------------------------------------
sprite_set_position:
	; VERA: sprites @$1F5000
	ldx #$50
	stx veramid
	ldx #$1F
	stx verahi
	asl
	asl
	asl ; *8
	clc

	ldx r0H
	bpl @1

; disable sprite
	adc #$06
	sta veralo
	stz veradat ; set zdepth to 0
	rts
	
@1:	adc #$02
	sta veralo
	lda r0L
	sta veradat
	lda r0H
	sta veradat
	lda r1L
	sta veradat
	lda r1H
	sta veradat
	lda #3 << 2
	sta veradat ; set zdepth to 3
	rts
