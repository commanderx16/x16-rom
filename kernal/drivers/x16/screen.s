;----------------------------------------------------------------------
; VERA Text Mode Screen Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "io.inc"
.include "banks.inc"
.include "mac.inc"
.include "regs.inc"

.export screen_init
.export screen_set_mode
.export screen_set_charset
.export screen_get_color
.export screen_set_color
.export screen_get_char
.export screen_set_char
.export screen_set_char_color
.export screen_get_char_color
.export screen_set_position
.export screen_copy_line
.export screen_clear_line
.export screen_save_state
.export screen_restore_state

; for monitor
.export pnt

; kernal var
.importzp sal, sah ; reused temps from load/save
.importzp tmp2
.import color
.import llen
.import data

; kernal call
.import scnsiz
.import jsrfar

.import fetch, fetvec; [routines]

.import GRAPH_init

.segment "KVAR"

cscrmd:	.res 1           ;    X16: current screen mode (argument to screen_set_mode)
pnt:	.res 2           ;$D1 pointer to row

.segment "SCREEN"

;---------------------------------------------------------------
; Initialize screen
;
;---------------------------------------------------------------
screen_init:
	stz VERA_CTRL   ;set ADDR1 active

	lda #2
	jsr screen_set_charset

	; Layer 1 configuration
	lda #((1<<6)|(2<<4)|(0<<0))
	sta VERA_L1_CONFIG
	lda #(mapbas>>9)
	sta VERA_L1_MAPBASE
	lda #((tilbas>>11)<<2)
	sta VERA_L1_TILEBASE
	stz VERA_L1_HSCROLL_L
	stz VERA_L1_HSCROLL_H
	stz VERA_L1_VSCROLL_L
	stz VERA_L1_VSCROLL_H

	; Display composer configuration
	lda #2
	sta VERA_CTRL
	stz VERA_DC_HSTART
	lda #(640>>2)
	sta VERA_DC_HSTOP
	stz VERA_DC_VSTART
	lda #(480>>2)
	sta VERA_DC_VSTOP

	stz VERA_CTRL
	lda #$21
	sta VERA_DC_VIDEO
	lda #128
	sta VERA_DC_HSCALE
	sta VERA_DC_VSCALE
	stz VERA_DC_BORDER

	; Clear sprite attributes ($1FC00-$1FFFF)
	stz VERA_ADDR_L
	lda #$FC
	sta VERA_ADDR_M
	lda #$11
	sta VERA_ADDR_H

	ldx #4
	ldy #0
:	stz VERA_DATA0     ;clear 128*8 bytes
	iny
	bne :-
	dex
	bne :-

	rts

;NTSC=1


mapbas	=0

; .ifdef NTSC
; ***** NTSC (with overscan)
; hstart  =46
; hstop   =591
; vstart  =35
; vstop   =444

; tvera_composer:
; 	.byte 2           ;NTSC
; 	.byte 150, 150    ;hscale, vscale
; 	.byte 14          ;border color
; 	.byte <hstart
; 	.byte <hstop
; 	.byte <vstart
; 	.byte <vstop
; 	.byte (vstop >> 8) << 5 | (vstart >> 8) << 4 | (hstop >> 8) << 2 | (hstart >> 8)
; tvera_composer_end
; .else
; ; ***** VGA
; hstart  =0
; hstop   =640
; vstart  =0
; vstop   =480

; tvera_composer:
; 	.byte 1           ;VGA
; 	.byte 128, 128    ;hscale, vscale
; 	.byte 14          ;border color
; 	.byte <hstart
; 	.byte <hstop
; 	.byte <vstart
; 	.byte <vstop
; 	.byte (vstop >> 8) << 5 | (vstart >> 8) << 4 | (hstop >> 8) << 2 | (hstart >> 8)
; tvera_composer_end:
; .endif

;---------------------------------------------------------------
; Set screen mode
;
;   In:   .a  mode
;             $00: 40x30
;             $01: 80x30 ; XXX currently unsupported
;             $02: 80x60
;             $80: 320x240@256c + 40x30 text
;                 (320x200@256c + 40x25 text, currently)
;             $81: 640x400@16c ; XXX currently unsupported
;             $ff: toggle between $00 and $02
;---------------------------------------------------------------
screen_set_mode:
	cmp #$ff
	bne scrmd1

	; Toggle between 40x30 and 80x60
	lda #2
	cmp cscrmd
	bne scrmd1
	lda #0

scrmd1:	sta cscrmd

	cmp #0 ; 40x30
	beq mode_40x30

	cmp #1 ; 80x30 currently unsupported
	bne scrmd2
mode_unsupported:
	sec
	rts

scrmd2:	cmp #2 ; 80x60
	beq mode_80x60
	cmp #$80 ; 320x240@256c + 40x30 text
	beq mode_320x240
	cmp #$81 ; 640x400@16c
	beq mode_unsupported ; currently unsupported
	bra mode_unsupported ; otherwise: illegal mode

mode_80x60:
	ldx #80
	ldy #60
	lda #128 ; scale = 1.0
	clc
	bra swpp2

mode_320x240:
	jsr grphon
	ldy #25
	sec
	bra swpp3

mode_40x30:
	clc
	ldy #30
swpp3:	ldx #40
	lda #64 ; scale = 2.0

swpp2:	pha
	bcs swppp4
	stz VERA_L0_CONFIG	; Disable layer 0

swppp4:	pla
	sta VERA_DC_HSCALE
	sta VERA_DC_VSCALE

	; Set vertical display stop
	cpy #25
	bne swpp1
	lda #(400/2)
	bra :+
swpp1:	lda #(480/2)
:	pha
	lda #2
	sta VERA_CTRL
	pla
	sta VERA_DC_VSTOP
	stz VERA_CTRL
	jsr scnsiz
	clc
	rts

grphon:
	lda #$0e ; light blue
	sta color

	LoadW r0, 0
	jmp GRAPH_init

;---------------------------------------------------------------
; Calculate start of line
;
;   In:   .x   line
;   Out:  pnt  line location
;---------------------------------------------------------------
screen_set_position:
	stz pnt
	stx pnt+1
	rts

;---------------------------------------------------------------
; Get single color
;
;   In:   .y       column
;         pnt      line location
;   Out:  .a       PETSCII/ISO
;---------------------------------------------------------------
screen_get_color:
	tya
	sec
	rol
	bra ldapnt2

;---------------------------------------------------------------
; Get single character
;
;   In:   .y       column
;         pnt      line location
;   Out:  .a       PETSCII/ISO
;---------------------------------------------------------------
screen_get_char:
	tya
	cmp llen
	bcc ldapnt1
	sec
	sbc llen
	asl
	sta VERA_ADDR_L
	lda pnt+1
	adc #1 ; C=0
	bne ldapnt3
ldapnt1:
	asl
ldapnt2:
	sta VERA_ADDR_L
	lda pnt+1
ldapnt3:
	sta VERA_ADDR_M
	lda #$10
	sta VERA_ADDR_H
	lda VERA_DATA0
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
	pha
	tya
	sec
	rol
	bra stapnt2

;---------------------------------------------------------------
; Set single character
;
;   In:   .a       PETSCII/ISO
;         .y       column
;         pnt      line location
;   Out:  -
;---------------------------------------------------------------
screen_set_char:
	pha
	tya
	cmp llen
	bcc stapnt1
	sec
	sbc llen
	asl
	sta VERA_ADDR_L
	lda pnt+1
	adc #1 ; C=0
	bne stapnt3
stapnt1:
	asl
stapnt2:
	sta VERA_ADDR_L
	lda pnt+1
stapnt3:
	sta VERA_ADDR_M
	lda #$10
	sta VERA_ADDR_H
	pla
	sta VERA_DATA0
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
	jsr screen_set_char
	stx VERA_DATA0     ;set color
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
	jsr screen_get_char
	ldx VERA_DATA0     ;get color
	rts

;---------------------------------------------------------------
; Copy line
;
;   In:   x    source line
;         pnt  target line location
;   Out:  -
;---------------------------------------------------------------
screen_copy_line:
	lda sal
	pha
	lda sah
	pha

	lda #0          ;set from addr
	sta sal
	stx sal+1

	;destination into addr1
	lda #$10
	sta VERA_ADDR_H
	lda pnt
	sta VERA_ADDR_L
	lda pnt+1
	sta VERA_ADDR_M

	lda #1
	sta VERA_CTRL

	;source into addr2
	lda #$10
	sta VERA_ADDR_H
	lda sal
	sta VERA_ADDR_L
	lda sal+1
	sta VERA_ADDR_M

	lda #0
	sta VERA_CTRL

	ldy llen
	dey
:	lda VERA_DATA1    ;character
	sta VERA_DATA0
	lda VERA_DATA1    ;color
	sta VERA_DATA0
	dey
	bpl :-

	pla             ;restore old indirects
	sta sah
	pla
	sta sal
	rts

;---------------------------------------------------------------
; Clear line
;
;   In:   .x  line
;---------------------------------------------------------------
screen_clear_line:
	ldy llen
	jsr screen_set_position
	lda pnt
	sta VERA_ADDR_L      ;set base address
	lda pnt+1
	sta VERA_ADDR_M
	lda #$10        ;auto-increment = 1
	sta VERA_ADDR_H
:	lda #' '
	sta VERA_DATA0     ;store space
	lda color       ;always clear to current foregnd color
	sta VERA_DATA0
	dey
	bne :-
	rts

;---------------------------------------------------------------
; Save state of the video hardware
;
; Function:  screen_save_state and screen_restore_state must be
;            called before and after any interrupt code that
;            calls any of the functions in this driver.
;---------------------------------------------------------------
; XXX make this a machine API? "io_save_state"?
screen_save_state:
	plx
	ply
	lda VERA_CTRL
	pha
	stz VERA_CTRL
	lda VERA_ADDR_L
	pha
	lda VERA_ADDR_M
	pha
	lda VERA_ADDR_H
	pha
	phy
	phx
	rts

;---------------------------------------------------------------
; Restore state of the video hardware
;
;---------------------------------------------------------------
screen_restore_state:
	plx
	ply
	pla
	sta VERA_ADDR_H
	pla
	sta VERA_ADDR_M
	pla
	sta VERA_ADDR_L
	pla
	sta VERA_CTRL
	phy
	phx
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
	jsr inicpy
	cmp #0
	beq cpycustom
	cmp #1
	beq cpyiso
	cmp #2
	beq cpypet1
	cmp #3
	beq cpypet2
	rts ; ignore unsupported values

; 0: custom character set
cpycustom:
	stx tmp2
	sty tmp2+1
	ldx #8
copyv:	ldy #0
	lda #tmp2
	sta fetvec
@l1:	phx
@l2:	ldx #BANK_CHARSET
	jsr fetch
	eor data
	sta VERA_DATA0
	iny
	bne @l2
	inc tmp2+1
	plx
	dex
	bne @l1
	rts

; 1: ISO character set
cpyiso:	lda #$c8
	sta tmp2+1       ;character data at ROM 0800
	ldx #8
	jmp copyv

; 2: PETSCII upper/graph character set
cpypet1:
	lda #$c0
	sta tmp2+1       ;character data at ROM 0000
	ldx #4
	jsr copyv
	dec data
	lda #$c0
	sta tmp2+1       ;character data at ROM 0000
	ldx #4
	jmp copyv

; 3: PETSCII upper/lower character set
cpypet2:
	lda #$c4
	sta tmp2+1       ;character data at ROM 0400
	ldx #4
	jsr copyv
	dec data
	lda #$c4
	sta tmp2+1       ;character data at ROM 0400
	ldx #4
	jmp copyv

inicpy:
	phx
	ldx #<tilbas
	stx VERA_ADDR_L
	ldx #>tilbas
	stx VERA_ADDR_M
	ldx #$10 | (tilbas >> 16)
	stx VERA_ADDR_H
	plx
	stz data
	stz tmp2
	rts
