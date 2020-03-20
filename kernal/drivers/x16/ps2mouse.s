;----------------------------------------------------------------------
; PS/2 Mouse Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "banks.inc"
.include "io.inc"
.include "regs.inc"
.include "mac.inc"

; code
.import ps2_receive_byte; [ps2]
.import ps2_peek_byte, ps2_remove_bytes
.import ps2ena, ps2dis

.import screen_save_state
.import screen_restore_state

.import sprite_set_image, sprite_set_position

.export mouse_init, mouse_config, mouse_scan, mouse_get, mouse_update_position

.segment "KVARSB0"

msepar:	.res 1           ;    $80=on; 1/2: scale
mousel:	.res 2           ;    min x coordinate
mouser:	.res 2           ;    max x coordinate
mouset:	.res 2           ;    min y coordinate
mouseb:	.res 2           ;    max y coordinate
mousex:	.res 2           ;    x coordinate
mousey:	.res 2           ;    y coordinate
mousebt:
	.res 1           ;    buttons (1: left, 2: right, 4: third)

tmp_byte0:
	.res 1
tmp_byte1:
	.res 1
tmp_byte2:
	.res 1

.segment "PS2MOUSE"

mouse_init:
	KVARS_START
	jsr _mouse_init
	KVARS_END
	rts
_mouse_init:
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

	ldx #0
	jmp ps2dis

; "MOUSE" KERNAL call
; A: $00 hide mouse
;    n   show mouse, set mouse cursor #n
;    $FF show mouse, don't configure mouse cursor
; X: $00 no-op
;    $01 set scale to 1
;    $02 set scale to 2
mouse_config:
	KVARS_START
	jsr _mouse_config
	KVARS_END
	rts
_mouse_config:
	; init mouse if necessary
	pha
	lda mouser
	ora mouser+1
	ora mouseb
	ora mouseb+1
	bne :+
	jsr mouse_init
:	pla

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

	ldx #0 ; PB: mouse
	jsr ps2dis

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

	ldx #0 ; PB: mouse
	jsr ps2ena

	jmp mouse_update_position

mouse_scan:
	KVARS_START
	jsr _mouse_scan
	KVARS_END
	rts

not_enough_data:
	rts


remove3:
	ldy #3 ; ; error in byte #2
	bra error
remove2:
	ldy #2 ; error in byte #1
	bra error
remove1:
	ldy #1 ; error in byte #0
error:	jmp ps2_remove_bytes

_mouse_scan:
	ldx #0
	ldy #0
	jsr ps2_peek_byte ; byte #0
	bcs remove1 ; error
	beq not_enough_data
	sta tmp_byte0

	ldx #0
	ldy #1
	jsr ps2_peek_byte ; byte #1
	bcs remove2 ; error
	beq not_enough_data
	sta tmp_byte1

	ldx #0
	ldy #2
	jsr ps2_peek_byte ; byte #2
	bcs remove3 ; error
	beq not_enough_data
	sta tmp_byte2

	jsr remove3 ; remove 3 bytes from queue

	lda tmp_byte1
	clc
	adc mousex
	sta mousex

	lda tmp_byte0
	and #$10
	beq :+
	lda #$ff
:	adc mousex+1
	sta mousex+1

	lda tmp_byte2
	clc
	adc mousey
	sta mousey

	lda tmp_byte0
	and #$20
	beq :+
	lda #$ff
:	adc mousey+1
	sta mousey+1

	lda tmp_byte0
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

	; check for another packet
	jmp _mouse_scan


.if 0
	; heuristic to test we're not out
	; of sync (on byte 0):
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



mouse_update_position:
	KVARS_START
	jsr screen_save_state
	
	PushW r0
	PushW r1
	
	lda msepar
	and #$7f
	cmp #2 ; scale
	beq :+

	lda mousex
	ldx mousex+1
	sta r0L
	stx r0H
	lda mousey
	ldx mousey+1
	bra @s1
:
	lda mousex+1
	lsr
	tax
	lda mousex
	ror
	sta r0L
	stx r0H
	lda mousey+1
	lsr
	tax
	lda mousey
	ror
@s1:	sta r1L
	stx r1H
	lda #0
	jsr sprite_set_position

	PopW r1
	PopW r0

	jsr screen_restore_state
	KVARS_END
	rts

mouse_get:
	KVARS_START
	lda mousex
	sta 0,x
	lda mousex+1
	sta 1,x
	lda mousey
	sta 2,x
	lda mousey+1
	sta 3,x
	lda mousebt
	KVARS_END
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

