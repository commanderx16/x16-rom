; PS/2 mouse

sprite_addr = 60 * 256 ; after text screen

mseinit:
	lda #0
	sta mousel
	sta mousel+1
	sta mouset
	sta mouset+1
	lda #<640
	sta mouser
	lda #>640
	sta mouser+1
	lda #<480
	sta mouseb
	lda #>480
	sta mouseb+1
	rts

; "MOUSE" KERNAL call
; A: $00 hide mouse
;    n   show mouse, set mouse cursor #n
;    $FF show mouse, don't configure mouse cursor
; X: $00 no-op
;    $01 set scale to 1
;    $02 set scale to 2
mouse:
	cpx #0
	beq mous1
;  set scale
	stx msepar
mous1:	cmp #0
	bne mous2
; hide mouse, disable sprite #0
	lda msepar
	and #$7f
	sta msepar
	lda #$06
	sta veralo
	lda #$50
	sta veramid
	lda #$1F
	sta verahi
	lda #0
	sta veradat
	rts
; show mouse
mous2:	cmp #$ff
	beq mous3
	; we ignore the cursor #, always set std pointer
	lda #<sprite_addr
	sta veralo
	lda #>sprite_addr
	sta veramid
	lda #$10 | (sprite_addr >> 16)
	sta verahi
	ldx #0
@1:	lda #8
	sta 0
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
	.byte $2c
@5:	lda #16 ; black
	sta veradat
	pla
@4:	dec 0
	bne @2
	inx
	cpx #32
	bne @1

mous3:	lda msepar
	ora #$80 ; flag: mouse on
	sta msepar
	lda #$00
	sta veralo
	lda #$40
	sta veramid
	lda #$1F
	sta verahi
	lda #1
	sta veradat ; enable sprites

	lda #$00
	sta veralo
	lda #$50
	sta veramid
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

msescn:
	ldx #0
	jsr receive_byte
	bcs scnms1 ; parity error
	bne scnms2 ; no data
scnms1:	rts
scnms2:
.if 0
	; heuristic to test we're not out
	; of sync:
	; * overflow needs to be 0
	; * bit #3 needs to be 1
	; The following codes sent by
	; the mouse will also be skipped
	; by this logic:
	; * $aa: self-test passed
	; * $fa: command acknowledged
	tax
	and #$c8
	cmp #$08
	bne scnms1
	txa
.endif
	sta mousebt

	ldx #0
	jsr receive_byte
	clc
	adc mousex
	sta mousex

	lda mousebt
	and #$10
	beq :+
	lda #$ff
:	adc mousex+1
	sta mousex+1

	ldx #0
	jsr receive_byte
	clc
	adc mousey
	sta mousey

	lda mousebt
	and #$20
	beq :+
	lda #$ff
:	adc mousey+1
	sta mousey+1

	lda mousebt
	and #7
	sta mousebt

; check bounds
	ldy mousel
	ldx mousel+1
	lda mousex+1
	bmi @2
	cpx mousex+1
	bne @1
	cpy mousex
@1:	bcc @3
	beq @3
@2:	sty mousex
	stx mousex+1
@3:	ldy mouser
	ldx mouser+1
	cpx mousex+1
	bne @4
	cpy mousex
@4:	bcs @5
	sty mousex
	stx mousex+1
@5:	ldy mouset
	ldx mouset+1
	lda mousey+1
	bmi @2a
	cpx mousey+1
	bne @1a
	cpy mousey
@1a:	bcc @3a
	beq @3a
@2a:	sty mousey
	stx mousey+1
@3a:	ldy mouseb
	ldx mouseb+1
	cpx mousey+1
	bne @4a
	cpy mousey
@4a:	bcs @5a
	sty mousey
	stx mousey+1
@5a:

; update sprite
	lda msepar
	bpl @s2 ; don't update sprite pos
	ldx #$02
	stx veralo
	ldx #$50
	stx veramid
	ldx #$1F
	stx verahi
	and #$7f
	cmp #2 ; scale
	beq :+
	lda mousex
	ldx mousex+1
	sta veradat
	stx veradat
	lda mousey
	ldx mousey+1
	bra @s1
:	lda mousex+1
	lsr
	tax
	lda mousex
	ror
	sta veradat
	stx veradat
	lda mousey+1
	lsr
	tax
	lda mousey
	ror
@s1:	sta veradat
	stx veradat

@s2:	rts

; This is the Susan Kare mouse pointer
mouse_sprite_col: ; 0: black, 1: white
.byte %11000000,%00000000
.byte %10100000,%00000000
.byte %10010000,%00000000
.byte %10001000,%00000000
.byte %10000100,%00000000
.byte %10000010,%00000000
.byte %10000001,%00000000
.byte %10000000,%10000000
.byte %10000000,%01000000
.byte %10000011,%11100000
.byte %10010010,%00000000
.byte %10101001,%00000000
.byte %11001001,%00000000
.byte %10000100,%10000000
.byte %00000100,%10000000
.byte %00000011,%10000000
mouse_sprite_mask: ; 0: transparent, 1: opaque
.byte %11000000,%00000000
.byte %11100000,%00000000
.byte %11110000,%00000000
.byte %11111000,%00000000
.byte %11111100,%00000000
.byte %11111110,%00000000
.byte %11111111,%00000000
.byte %11111111,%10000000
.byte %11111111,%11000000
.byte %11111111,%11100000
.byte %11111110,%00000000
.byte %11101111,%00000000
.byte %11001111,%00000000
.byte %10000111,%10000000
.byte %00000111,%10000000
.byte %00000011,%10000000
