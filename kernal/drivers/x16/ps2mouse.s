;----------------------------------------------------------------------
; PS/2 Mouse Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "banks.inc"
.include "io.inc"
.include "regs.inc"
.include "mac.inc"

; code
.import i2c_read_first_byte, i2c_read_next_byte, i2c_read_stop
.import screen_save_state
.import screen_restore_state

.import sprite_set_image, sprite_set_position

.export mouse_config, mouse_scan, mouse_get

.segment "KVARSB0"

msepar:	.res 1           ;    $80: mouse on; 1/2: scale
mousemx:
	.res 2           ;    max x coordinate
mousemy:
	.res 2           ;    max y coordinate
mousex:	.res 2           ;    cur x coordinate
mousey:	.res 2           ;    cur y coordinate
mousebt:
	.res 1           ;    cur buttons (1: left, 2: right, 4: third)

I2C_ADDRESS = $42
I2C_GET_MOUSE_MOVEMENT_OFFSET = $21

.segment "PS2MOUSE"

; "MOUSE" KERNAL call
; A: $00 hide mouse
;    n   show mouse, set mouse cursor #n
;    $FF show mouse, don't configure mouse cursor
; X: width in 8px
; Y: height in 8px
;    X==0 && Y==0: leave as-is
mouse_config:
	KVARS_START
	jsr _mouse_config
	KVARS_END
	rts
_mouse_config:
	pha
	cpx #0
	beq @skip

	; scale
	lda #1
	cpx #40
	bne :+
	lda #2
:	sta msepar ;  set scale
	pha

	; width * x
	txa
	stz mousemx+1
	asl
	asl
	rol mousemx+1
	asl
	rol mousemx+1
	sta mousemx
	; height * x
	tya
	stz mousemy+1
	asl
	asl
	asl
	rol mousemy+1
	sta mousemy

	; 320w and less: double the size
	pla
	dec
	beq @skip2
	asl mousemx
	rol mousemx+1
	asl mousemy
	rol mousemy+1
@skip2:
	DecW mousemx
	DecW mousemy

@skip:
	pla
	cmp #0
	bne mous2
; hide mouse, disable sprite #0
	lda msepar
	and #$7f
	sta msepar

	PushW r0H
	lda #$ff
	sta r0H
	inc
	jsr sprite_set_position
	PopW r0H
	rts

; show mouse
mous2:	cmp #$ff
	beq mous3

	; we ignore the cursor #, always set std pointer
	PushW r0
	PushW r1
	LoadW r0, mouse_sprite_col
	LoadW r1, mouse_sprite_mask
	LoadB r2L, 1 ; 1 bpp
	ldx #16      ; width
	ldy #16      ; height
	lda #0       ; sprite 0
	sec          ; apply mask
	jsr sprite_set_image
	PopW r1
	PopW r0

mous3:	lda msepar
	ora #$80 ; flag: mouse on
	sta msepar

	jmp mouse_update_position

mouse_scan:
	KVARS_START
	jsr _mouse_scan
	KVARS_END
	rts

_mouse_scan:
	bit msepar ; do nothing if mouse is off
	bpl @a
	
	ldx #I2C_ADDRESS
	ldy #I2C_GET_MOUSE_MOVEMENT_OFFSET
	jsr i2c_read_first_byte
	bcs @a ; error
	bne @b ; no data
	jmp i2c_read_stop
@a:	rts
@b:
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
	bne @a
	txa
.endif
	sta mousebt

	jsr i2c_read_next_byte
	clc
	adc mousex
	sta mousex

	lda mousebt
	and #$10
	beq :+
	lda #$ff
:	adc mousex+1
	sta mousex+1

	jsr i2c_read_next_byte
	pha                     ; Push low 8 bits onto stack
	jsr i2c_read_stop       ; Stop I2C transfer
	ply                     ; Pop low 8 bits to Y
	lda mousebt             ; Load flags
	and #$20                ; Check sign bit
	beq :+                  ; set?
	lda #$ff                ; sign extend into all of A
:	eor #$ff                ; invert high 8 bits
	tax                     ; High 8 bits in X
	tya                     ; Low 8 bits in A
	eor #$ff                ; invert low 8 bits
	; At this point X:A = ~dY (not negative dY, bitwise not)
	sec                     ; Add 1 to low 8 bits
	adc mousey              ; Add low 8 bits to mousey
	sta mousey              ; mousey = result
	txa                     ; High 8 bits in A
	adc mousey+1            ; Add high 8 bits to mousey+1
	sta mousey+1            ; mousey+1 = result

	lda mousebt
	and #7
	sta mousebt

; check bounds
	ldy #0
	ldx #0
	lda mousex+1
	bmi @2
	cpx mousex+1
	bne @1
	cpy mousex
@1:	bcc @3
	beq @3
@2:	sty mousex
	stx mousex+1
@3:	ldy mousemx
	ldx mousemx+1
	cpx mousex+1
	bne @4
	cpy mousex
@4:	bcs @5
	sty mousex
	stx mousex+1
@5:	ldy #0
	ldx #0
	lda mousey+1
	bmi @2a
	cpx mousey+1
	bne @1a
	cpy mousey
@1a:	bcc @3a
	beq @3a
@2a:	sty mousey
	stx mousey+1
@3a:	ldy mousemy
	ldx mousemy+1
	cpx mousey+1
	bne @4a
	cpy mousey
@4a:	bcs @5a
	sty mousey
	stx mousey+1
@5a:

; set the mouse sprite position
mouse_update_position:
	jsr screen_save_state

	PushW r0
	PushW r1

	ldx #r0
	jsr mouse_get
	lda #0
	jsr sprite_set_position

	PopW r1
	PopW r0

	jsr screen_restore_state
	rts ; NB: call above does not support tail call optimization

mouse_get:
	KVARS_START
	jsr _mouse_get
	KVARS_END
	rts

_mouse_get:
	lda msepar
	and #$7f
	cmp #2 ; scale
	beq :+

	lda mousex
	sta 0,x
	lda mousex+1
	sta 1,x
	lda mousey
	sta 2,x
	lda mousey+1
	sta 3,x
	bra @s1
:
	lda mousex+1
	lsr
	sta 1,x
	lda mousex
	ror
	sta 0,x
	lda mousey+1
	lsr
	sta 3,x
	lda mousey
	ror
	sta 2,x
@s1:	lda mousebt
	rts

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

