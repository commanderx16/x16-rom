;----------------------------------------------------------------------
; C64 Joystick Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.export joystick_get, joystick_scan

.segment "JOYSTICK"

;---------------------------------------------------------------
; joystick_scan
;
; Function:  Scan all joysticks
;
;---------------------------------------------------------------
joystick_scan:
	; nothing to do on the C64
	rts

;---------------------------------------------------------------
; joystick_get
;
; Function:  Return the state of a given joystick.
;
; Pass:      a    number of joystick (0-3)
; Return:    a    byte 0:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;                         SNES | B | Y |SEL|STA|UP |DN |LT |RT |
;
;            x    byte 1:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;                         SNES | A | X | L | R | 1 | 1 | 1 | 1 |
;            y    byte 2:
;                         $00 = joystick present
;                         $FF = joystick not present
;
; Note:      * Presence can be detected by checking byte 2.
;---------------------------------------------------------------
joystick_get: ; XXX
	; C64 joystick button layout:
	; | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
	; |   |   |   | A |RT |LT |DN |UP |
	cpx #2
	bcc :+
	lda #0
	ldx #0
	ldy #$ff
	rts

:	txa
	eor #1 ; $dc00 is port 2, $dc01 is port 1
	tax
	lda $dc00,x
	eor #$ff
	pha
	and #$0f
	tax
	pla
	cmp #$10      ; set .C if fire button down
	lda convtab,x
	ror           ; fire button to MSB
	eor #$ff
	ldx #$08      ; 1000: C64
	ldy #$ff
	rts

convtab:
	.byte $00,$10,$08,$18,$04,$14,$0c,$1c,$02,$12,$0a,$1a,$06,$16,$0e,$1e
