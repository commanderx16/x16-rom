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
joystick_get: ; XXX
	lda #0
	ldx #0
	ldy #$ff
	rts
