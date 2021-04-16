;----------------------------------------------------------------------
; NES & SNES Controller Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "banks.inc"
.include "io.inc"

; KERNAL API
.export joystick_scan
.export joystick_get
; called by ps2 keyboard driver
.export joystick_from_ps2

nes_data = d1pra
nes_ddr  = d1ddra

bit_latch = $04 ; PA2 LATCH (both controllers)
bit_jclk  = $08 ; PA3 CLK   (both controllers)
bit_data4 = $10 ; PA4 DATA  (controller #4)
bit_data3 = $20 ; PA5 DATA  (controller #3)
bit_data2 = $40 ; PA6 DATA  (controller #2)
bit_data1 = $80 ; PA7 DATA  (controller #1)

.segment "KVARSB0"

j0tmp:	.res 1           ;    keyboard joystick temp
joy0:	.res 1           ;    keyboard joystick temp
joy1:	.res 3           ;    joystick 1 status
joy2:	.res 3           ;    joystick 2 status
joy3:	.res 3           ;    joystick 3 status
joy4:	.res 3           ;    joystick 4 status

.segment "JOYSTICK"

;---------------------------------------------------------------
; joystick_scan
;
; Function:  Scan all joysticks
;
;---------------------------------------------------------------
joystick_scan:
	KVARS_START_TRASH_A_NZ

	lda #$ff-bit_data1-bit_data2
	sta nes_ddr
	lda #$00
	sta nes_data

	; pulse latch
	lda #bit_latch
	sta nes_data
	lda #0
	sta nes_data

	; read 3x 8 bits
	ldx #0
l2:	ldy #8
l1:	lda nes_data
	rol
	rol joy1,x ;If top bit was set, carry will be set rotate that into joy1
	rol
	rol joy2,x ;rol into joy2
	rol
	rol joy3,x
	rol
	rol joy4,x

	lda #bit_jclk
	sta nes_data
	lda #0
	sta nes_data
	dey
	bne l1
	inx
	cpx #3
	bne l2

	KVARS_END_TRASH_A_NZ
	rts

;---------------------------------------------------------------
; joystick_get
;
; Function:  Return the state of a given joystick.
;
; Pass:      a    number of joystick (0 or 1)
; Return:    a    byte 0:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;                         NES  | A | B |SEL|STA|UP |DN |LT |RT |
;                         SNES | B | Y |SEL|STA|UP |DN |LT |RT |
;
;            x    byte 1:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;                         NES  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
;                         SNES | A | X | L | R | 1 | 1 | 1 | 1 |
;            y    byte 2:
;                         $00 = joystick present
;                         $FF = joystick not present
;
; Notes:     * Presence can be detected by checking byte 2.
;            * The type of controller is encoded in bits 0-3 in
;              byte 1:
;              0000: NES
;              0001: keyboard (NES-like)
;              1111: SNES
;            * Bits 6 and 7 in byte 0 map to different buttons
;              on NES and SNES.
;---------------------------------------------------------------
joystick_get:
	KVARS_START_TRASH_X_NZ
	tax
	beq @1       ; -> joy1
	dex
	beq @2       ; -> joy2
	dex
	beq @3       ; -> joy3
	dex
	beq @4       ; -> joy4


@1:
; joy1
	lda joy1
	ldx joy1+1
	ldy joy1+2
	beq @5      ; present

; joy1 not present, return keyboard
	lda joy0
	ldx #1       ; type = keyboard
	ldy #0       ; present
	bra @5

; joy 2
@2:
	lda joy2
	ldx joy2+1
	ldy joy2+2
	bra @5

@3:
	lda joy3
	ldx joy3+1
	ldy joy3+2
	bra @5

@4:
	lda joy4
	ldx joy4+1
	ldy joy4+2


@5:	KVARS_END
	rts

;----------------------------------------------------------------------
; joystick_from_ps2:
;
;  convert PS/2 scancode into NES joystick state (internal)
;
; Note: This is called from the ps2kbd driver while bank 0 is active,
;       no bank switching is performed.
;
joystick_from_ps2:
NES_A      = (1 << 7)
NES_B      = (1 << 6)
NES_SELECT = (1 << 5)
NES_START  = (1 << 4)
NES_UP     = (1 << 3)
NES_DOWN   = (1 << 2)
NES_LEFT   = (1 << 1)
NES_RIGHT  = (1 << 0)
	ldy joy0   ; init joy0 the first time a key was pressed
	bne :+     ; this way, XXX can know
	dec joy0   ; whether a keyboard is attached
:
	pha
	php
	cpx #0
	bne @l1
	cmp #$14; A [Ctrl]
	bne :+
	lda #NES_A
	bne @l3
:	cmp #$11; B [Alt]
	bne :+
	lda #NES_B
	bne @l3
:	cmp #$29; SELECT [Space]
	bne :+
	lda #NES_SELECT
	bne @l3
:	cmp #$5a; START [Enter]
	bne :+
	lda #NES_START
	bne @l3
@l1:	cpx #$e0
	bne @l2
	cmp #$6b ; LEFT
	bne :+
	lda #NES_LEFT
	bne @l3
:	cmp #$74 ; RIGHT
	bne :+
	lda #NES_RIGHT
	bne @l3
:	cmp #$75 ; UP
	bne :+
	lda #NES_UP
	bne @l3
:	cmp #$72 ; DOWN
	bne @l2
	lda #NES_DOWN
@l3:
	plp ; C: 0 = down, 1 = up
	php
	bcc @l5    ; down
	sta j0tmp
	lda joy0   ; init joy0 the first time a key was pressed
	ora j0tmp
	bra @l4
@l5:	eor #$ff
	sta j0tmp
	lda joy0
	and j0tmp
@l4:	sta joy0
@l2:	plp
	pla
	rts
