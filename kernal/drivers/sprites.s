;----------------------------------------------------------------------
; VERA Sprites Driver
;----------------------------------------------------------------------

; This code currently supports up to 8 sprites.

.include "../../io.inc"
.include "../../regs.inc"
.include "../../mac.inc"

.export sprite_set_image
.export sprite_set_position

.segment "SPRITES"

;---------------------------------------------------------------
; sprites_set_image
;
;   In:   .A     sprite number
;         .X     data width
;         .Y     data height
;         r0     pointer to pixel data
;         r1     pointer to mask data
;         r2L    data bits per pixel
;---------------------------------------------------------------
sprite_set_image:
	.import mouse_sprite_mask, mouse_sprite_col

	PushB r2H

	lda #<sprite_addr
	sta veralo
	lda #>sprite_addr
	sta veramid
	lda #$10 | (sprite_addr >> 16)
	sta verahi
	ldx #0
@1:	lda #8
	sta r2H
	lda mouse_sprite_mask,x
	ldy mouse_sprite_col,x
@2:	asl
	bcs @3
	stz veradat
	pha
	tya
	asl
	tay
	pla
	bra @4
@3:	pha
	tya
	asl
	tay
	bcc @5
	lda #1  ; white
	bra @6
@5:	lda #16 ; black
@6:	sta veradat
	pla
@4:	dec r2H
	bne @2
	inx
	cpx #32
	bne @1

	PopB r2H

	lda #$00
	sta veralo
	lda #$50
	sta veramid
	lda #$1F
	sta verahi
	lda #<(sprite_addr >> 5)
	sta veradat
	lda #1 << 7 | >(sprite_addr >> 5) ; 8 bpp
	sta veradat
	lda #$06
	sta veralo
	lda #3 << 2 ; z-depth: in front of everything
	sta veradat
	lda #1 << 6 | 1 << 4 ;  16x16 px
	sta veradat
	
	rts

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
	
	and #7 ; mask sprites 0-7
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
	sta veradat ; offset 2: X lo
	lda r0H
	sta veradat ; offset 3: X hi
	lda r1L
	sta veradat ; offset 4: Y lo
	lda r1H
	sta veradat ; offset 5: Y hi
	lda #3 << 2
	sta veradat ; offset 6: set zdepth to 3

	lda #$00
	sta veralo
	lda #$40
	sta veramid
	lda #$1F
	sta verahi
	lda #1
	sta veradat ; enable sprites globally
	rts
