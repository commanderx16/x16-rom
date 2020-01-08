;----------------------------------------------------------------------
; VIC-II Text Mode Screen Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.import scnsiz, color
.export screen_clear_line, screen_copy_line, screen_get_char, screen_get_char_color, screen_get_color, screen_init, screen_restore_state, screen_save_state, screen_set_char, screen_set_char_color, screen_set_charset, screen_set_color, screen_set_mode, screen_set_position

scrram = $0400
colram = $d800

.segment "ZPKERNAL" : zp

pnt:	.res 2           ;$D1 pointer to row
pntcol:	.res 2

.segment "SCREEN"

;---------------------------------------------------------------
; Initialize screen
;
;---------------------------------------------------------------
screen_init:
	ldx #vic_data_end-vic_data
:	lda vic_data-1,x
	sta $d000-1,x
	dex
	bne :-

	ldx #40
	ldy #25
	jmp scnsiz

vic_data:
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte $1b,0,0,0,0,$08,0,$14,$0f,0,0,0,0,0,0
	.byte 14,6,1,2,3,4,0,1,2,3,4,5,6,7
vic_data_end:

;---------------------------------------------------------------
; Set screen mode
;
;   In:   .a  mode
;---------------------------------------------------------------
screen_set_mode:
	rts ; XXX

;---------------------------------------------------------------
; Calculate start of line
;
;   In:   .x   line
;   Out:  pnt  line location
;---------------------------------------------------------------
screen_set_position:
	; * 40 = %101000
	txa
	stz pnt+1

	asl       ; calc line * 8 (max 192 i.e. single byte)
	asl
	asl
	sta pnt

	asl       ; calc line * 32
	rol pnt+1
	asl
	rol pnt+1

	clc       ; add line * 8
	adc pnt
	sta pnt
	sta pntcol
	lda pnt+1
	adc #>scrram
	sta pnt+1
	clc
	adc #(>colram)-(>scrram)
	sta pntcol+1
	rts

;---------------------------------------------------------------
; Get single color
;
;   In:   .y       column
;         pnt      line location
;   Out:  .a       PETSCII/ISO
;---------------------------------------------------------------
screen_get_color:
	lda (pntcol),y
	rts

;---------------------------------------------------------------
; Get single character
;
;   In:   .y       column
;         pnt      line location
;   Out:  .a       PETSCII/ISO
;---------------------------------------------------------------
screen_get_char:
	lda (pnt),y
	rts

;---------------------------------------------------------------
; Set single color
;
;   In:   .a       color
;         .y       column
;         pnt      line location
;   Out:  -
;---------------------------------------------------------------
screen_set_color:
	sta (pntcol),y
	rts

;---------------------------------------------------------------
; Set single character
;
;   In:   .a       PETSCII/ISO
;         .y       column
;         pnt      line location
;   Out:  -
;---------------------------------------------------------------
screen_set_char:
	sta (pnt),y
	rts

;---------------------------------------------------------------
; Set single character and color
;
;   In:   .a       PETSCII/ISO
;         .x       color
;         .y       column
;         pnt      line location
;   Out:  -
;---------------------------------------------------------------
screen_set_char_color:
	sta (pnt),y
	txa
	sta (pntcol),y
	rts

;---------------------------------------------------------------
; Get single character and color
;
;   In:   .y       column
;         pnt      line location
;   Out:  .a       PETSCII/ISO
;         .x       color
;---------------------------------------------------------------
screen_get_char_color:
	lda (pntcol),y
	tax
	lda (pnt),y
	rts

;---------------------------------------------------------------
; Copy line
;
;   In:   x    source line
;         pnt  target line location
;   Out:  -
;---------------------------------------------------------------
screen_copy_line:
	rts ; XXX

;---------------------------------------------------------------
; Clear line
;
;   In:   .x  line
;---------------------------------------------------------------
screen_clear_line:
	jsr screen_set_position
	ldy #39
:	lda #' '
	sta (pnt),y
	lda color
	sta (pntcol),y
	dey
	bpl :-
	rts

;---------------------------------------------------------------
; Save state of the video hardware
;
; Function:  screen_save_state and screen_restore_state must be
;            called before and after any interrupt code that
;            calls any of the functions in this driver.
;---------------------------------------------------------------
screen_save_state:
	rts

;---------------------------------------------------------------
; Restore state of the video hardware
;
;---------------------------------------------------------------
screen_restore_state:
	rts

;---------------------------------------------------------------
; Set charset
;
; Function: Activate a 256 character 8x8 charset.
;
;   In:   .a     charset
;                0: use pointer in .x/.y
;                1: ISO
;                2: PET upper/graph
;                3: PET upper/lower
;         .x/.y  pointer to charset
;---------------------------------------------------------------
screen_set_charset:
	rts
