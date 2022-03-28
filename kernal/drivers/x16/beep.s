.include "io.inc"

.segment "BEEP"

.export beep

psg_address = $1f9c0

frequency = 1181 ; 440 Hz

beep:
	lda #<psg_address
	sta VERA_ADDR_L
	lda #>psg_address
	sta VERA_ADDR_M
	lda #$10 | ^psg_address
	sta VERA_ADDR_H

	lda #<frequency
	sta VERA_DATA0
	lda #>frequency
	sta VERA_DATA0
	lda #%11111111 ; max volume, output left & right
	sta VERA_DATA0
	lda #%00111111 ; pulse, max width
	sta VERA_DATA0

	lda #4
	ldy #0
	ldx #0
:	dex
	bne :-
	dey
	bne :-
	dec
	bne :-

	lda #<psg_address + 2
	sta VERA_ADDR_L
	stz VERA_DATA0 ; disable voice 0
	rts
