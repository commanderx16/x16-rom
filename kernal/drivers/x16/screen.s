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
	lda #0
	sta veractl     ;set ADDR1 active

	lda #1
	jsr screen_set_charset

	lda #$1f
	sta verahi

	lda #$00        ;$F2000: layer 0 registers
	sta veralo
	lda #$20
	sta veramid
	stz veradat     ;disable layer 0

	lda #$00        ;$F3000: layer 1 registers
	sta veralo
	lda #$30
	sta veramid
	ldx #0
:	lda tvera_layer1,x
	sta veradat
	inx
	cpx #tvera_layer1_end-tvera_layer1
	bne :-

	lda #$00        ;$F0000: composer registers
	sta veralo
	sta veramid
	ldx #0
:	lda tvera_composer,x
	sta veradat
	inx
	cpx #tvera_composer_end-tvera_composer
	bne :-

	lda #$00        ;$F5000: sprite attributes
	sta veralo
	lda #$50
	sta veramid
	ldx #4
	ldy #0
:	stz veradat     ;clear 128*8 bytes
	iny
	bne :-
	dex
	bne :-

	rts

;NTSC=1

tvera_layer1:
	.byte 0 << 5 | 1  ;mode=0, enabled=1
	.byte 1 << 2 | 2  ;maph=64, mapw=128
	.word mapbas >> 2 ;map_base
	.word tilbas >> 2 ;tile_bas
	.word 0, 0        ;hscroll, vscroll
tvera_layer1_end:

mapbas	=0

.ifdef NTSC
; ***** NTSC (with overscan)
hstart  =46
hstop   =591
vstart  =35
vstop   =444

tvera_composer:
	.byte 2           ;NTSC
	.byte 150, 150    ;hscale, vscale
	.byte 14          ;border color
	.byte <hstart
	.byte <hstop
	.byte <vstart
	.byte <vstop
	.byte (vstop >> 8) << 5 | (vstart >> 8) << 4 | (hstop >> 8) << 2 | (hstart >> 8)
tvera_composer_end
.else
; ***** VGA
hstart  =0
hstop   =640
vstart  =0
vstop   =480

tvera_composer:
	.byte 1           ;VGA
	.byte 128, 128    ;hscale, vscale
	.byte 14          ;border color
	.byte <hstart
	.byte <hstop
	.byte <vstart
	.byte <vstop
	.byte (vstop >> 8) << 5 | (vstart >> 8) << 4 | (hstop >> 8) << 2 | (hstart >> 8)
tvera_composer_end:
.endif

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
; toggle between 40x30 and  80x60
	lda #2
	cmp cscrmd
	bne scrmd1
	lda #0
scrmd1:	sta cscrmd
	cmp #0 ; 40x30
	beq swpp30
	cmp #1 ; 80x30 currently unsupported
	bne scrmd2
scrmd3:	sec
	rts
scrmd2:	cmp #2 ; 80x60
	beq swpp60
	cmp #$80 ; 320x240@256c + 40x30 text
	beq swpp25
	cmp #$81 ; 640x400@16c
	beq scrmd3 ; currently unsupported
	bra scrmd3 ; otherwise: illegal mode

swpp60:	ldx #80
	ldy #60
	lda #128 ; scale = 1.0
	clc
	bra swpp2

swpp25:	jsr grphon
	ldy #25
	sec
	bra swpp3

swpp30:	clc
	ldy #30
swpp3:	ldx #40
	lda #64 ; scale = 2.0
swpp2:	pha
	bcs swppp4
	jsr grphoff
swppp4:	lda #$01
	sta veralo
	lda #$00
	sta veramid
	lda #$1F
	sta verahi
	pla
	sta veradat ; reg $F0001: hscale
	sta veradat ; reg $F0002: vscale
	cpy #25
	bne swpp1
	lda #<400
	bra :+
swpp1:	lda #<480
:	pha
	lda #7 ; vstop_lo
	sta veralo
	pla
	sta veradat
	jsr scnsiz
	clc
	rts

grphon:
	lda #$0e ; light blue
	sta color

	LoadW r0, 0
	jmp GRAPH_init

grphoff:
	lda #$00        ; layer0
	sta veralo
	lda #$20
	sta veramid
	lda #$1F
	sta verahi
	lda #0          ; off
	sta veradat
	rts

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
	sta veralo
	lda pnt+1
	adc #1 ; C=0
	bne ldapnt3
ldapnt1:
	asl
ldapnt2:
	sta veralo
	lda pnt+1
ldapnt3:
	sta veramid
	lda #$10
	sta verahi
	lda veradat
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
	sta veralo
	lda pnt+1
	adc #1 ; C=0
	bne stapnt3
stapnt1:
	asl
stapnt2:
	sta veralo
	lda pnt+1
stapnt3:
	sta veramid
	lda #$10
	sta verahi
	pla
	sta veradat
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
	stx veradat     ;set color
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
	ldx veradat     ;get color
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
	sta verahi
	lda pnt
	sta veralo
	lda pnt+1
	sta veramid

	lda #1
	sta veractl

	;source into addr2
	lda #$10
	sta verahi
	lda sal
	sta veralo
	lda sal+1
	sta veramid

	lda #0
	sta veractl

	ldy llen
	dey
:	lda veradat2    ;character
	sta veradat
	lda veradat2    ;color
	sta veradat
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
	sta veralo      ;set base address
	lda pnt+1
	sta veramid
	lda #$10        ;auto-increment = 1
	sta verahi
:	lda #' '
	sta veradat     ;store space
	lda color       ;always clear to current foregnd color
	sta veradat
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
	lda veractl
	pha
	stz veractl
	lda veralo
	pha
	lda veramid
	pha
	lda verahi
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
	sta verahi
	pla
	sta veramid
	pla
	sta veralo
	pla
	sta veractl
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
	sta veradat
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
	ldx #<tilbas
	stx veralo
	ldx #>tilbas
	stx veramid
	ldx #$10 | (tilbas >> 16)
	stx verahi
	stz data
	stz tmp2
	rts
