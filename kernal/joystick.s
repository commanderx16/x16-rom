;----------------------------------------------------------------------
; NES & SNES Controller Driver for 6502
;----------------------------------------------------------------------

nes_data = d2pra
nes_ddr  = d2ddra

bit_latch = $08 ; PB3 (user port pin F): LATCH (both controllers)
bit_data1 = $10 ; PB4 (user port pin H): DATA  (controller #1)
bit_jclk  = $20 ; PB5 (user port pin J): CLK   (both controllers)
bit_data2 = $40 ; PB6 (user port pin K): DATA  (controller #2)

;----------------------------------------------------------------------
; query_joys:
;
; byte 0:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;         NES  | A | B |SEL|STA|UP |DN |LT |RT |
;         SNES | B | Y |SEL|STA|UP |DN |LT |RT |
;
; byte 1:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;         NES  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
;         SNES | A | X | L | R | 1 | 1 | 1 | 1 |
; byte 2:
;         $00 = joystick present
;         $FF = joystick not present
;
; * Presence can be detected by checking byte 2.
; * The type of controller is encoded in bits 0-3 in byte 1:
;   0000: NES
;   0001: keyboard (NES-like)
;   1111: SNES
; * Note that bits 6 and 7 in byte 0 map to different buttons on NES and SNES.
query_joysticks:
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
.assert bit_data2 > bit_data1, error, "bit_data2 must be greater than bit_data1, otherwise swap 1 vs. 2 here"
	cmp #bit_data2
	rol joy2,x
	and #bit_data1
	cmp #bit_data1
	rol joy1,x
	lda #bit_jclk
	sta nes_data
	lda #0
	sta nes_data
	dey
	bne l1
	inx
	cpx #3
	bne l2

; if joy1 is not present, use the keyboard instead
	lda joy1 + 2
	beq :+
	lda joy0
	beq :+       ; keyboard not present
	sta joy1
	ldx #1
	stx joy1 + 1 ; type = keyboard
	dex
	stx joy1 + 2 ; present
:	rts

scancode_to_joystick:
NES_A      = (1 << 7)
NES_B      = (1 << 6)
NES_SELECT = (1 << 5)
NES_START  = (1 << 4)
NES_UP     = (1 << 3)
NES_DOWN   = (1 << 2)
NES_LEFT   = (1 << 1)
NES_RIGHT  = (1 << 0)
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
	bcc :+
	sta 2
	jsr @l5
	ora 2
	bne @l4
:	eor #$ff
	sta 2
	lda joy0
	and 2
@l4:	sta joy0
@l2:	plp
	pla
	rts
; init joy0 the first time a key was pressed
; this way, query_joysticks can know whether a keyboard is attached
@l5:	lda joy0
	bne :+
	lda #$ff
:	rts

