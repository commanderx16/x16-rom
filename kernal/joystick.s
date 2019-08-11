;----------------------------------------------------------------------
; NES & SNES Controller Driver for 6502
;----------------------------------------------------------------------

.ifdef C64
; C64 CIA#2 PB (user port)
nes_data = $dd01
nes_ddr  = $dd03
.else
nes_data = d2ddra
nes_ddr  = d2pra
.endif

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
; * NES vs. SNES can be detected by checking bits 0-3 in byte 1.
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
	rts
