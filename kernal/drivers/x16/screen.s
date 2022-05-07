;----------------------------------------------------------------------
; VERA Text Mode Screen Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "io.inc"
.include "banks.inc"
.include "mac.inc"
.include "regs.inc"

.export screen_init
.export screen_mode
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

cscrmd:	.res 1           ;    X16: current screen mode (argument to screen_mode)
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
	lda #(screen_addr>>9)
	sta VERA_L1_MAPBASE
	lda #((charset_addr>>11)<<2)
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

	lda #$ff
	sta cscrmd      ; force setting color on first mode change
	rts

;NTSC=1


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
; Get/Set screen mode
;
;   In:   .c  =0: set, =1: get
; Set:
;   In:   .a  mode
;             $00: 80x60
;             $01: 80x30
;             $02: 40x60
;             $03: 40x30
;             $04: 40x15
;             $05: 20x30
;             $06: 20x15
;             $80: 320x240@256c + 40x30 text
;             $81: 640x400@16c ; XXX currently unsupported
;   Out:  .c  =0: success, =1: failure
; Get:
;   Out:  .a  mode
;---------------------------------------------------------------
screen_mode:
	bcc @set

; get
	lda cscrmd
	pha
	jsr mode_lookup
	jsr calc_scaled_res
	pla
	rts

@set:
	pha
	jsr mode_lookup
	plx
	bcs @rts

	pha             ; save scale
	txa
	eor cscrmd
	asl             ; C: is it graph/text switch?
	stx cscrmd

	pla             ; scale
	pha

	php             ; save if graph/text switch
	; set VERA scaling
	jsr set_scale

	; Set vertical display stop
	lda #2
	sta VERA_CTRL
	lda #(480/2)
	sta VERA_DC_VSTOP
	stz VERA_CTRL

	lda cscrmd
	bmi @graph

	; text mode: disable layer 0
	lda VERA_DC_VIDEO
	and #$ef
	sta VERA_DC_VIDEO
	lda #6 << 4 | 1 ; blue on white
	bra @cont

@graph:	; graphics mode
	LoadW r0, 0
	jsr GRAPH_init
	lda #$0e ; light blue on translucent
@cont:	plp
	bcc :+
	sta color ; only set color if graph/text switch
:
	; set editor size
	pla
	jsr calc_scaled_res
	jsr scnsiz
	clc
@rts:	rts

mode_lookup:
	ldx #scale-modes
:	cmp modes-1,x
	beq @found
	dex
	bpl :-
	sec ; otherwise: illegal mode
	rts
@found:	lda scale-1,x
	clc
	rts

calc_scaled_res:
	pha
	lsr
	lsr
	lsr
	lsr
	tay
	lda #80
:	cpy #0
	beq @xdone
	lsr
	dey
	bra :-
@xdone:	tax      ; scaled x res
	pla
	and #$0f
	tay
	lda #60
:	cpy #0
	beq @ydone
	lsr
	dey
	bra :-
@ydone:	tay      ; scaled yres
	rts

set_scale:
	pha
	lsr
	lsr
	lsr
	lsr
	tay
	lda #$80
:	cpy #0
	beq @xdone
	lsr
	dey
	bra :-
@xdone:	sta VERA_DC_HSCALE
	pla
	and #$0f
	tay
	lda #$80
:	cpy #0
	beq @ydone
	lsr
	dey
	bra :-
@ydone:	sta VERA_DC_VSCALE
	rts

modes:	.byte   0,   1,   2,   3,   4,   5,   6, $80
scale:	.byte $00, $01, $10, $11, $12, $21, $22, $11 ; hi-nyb: x >> n, lo-nyb: y >> n

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
	clc
	adc #<(>screen_addr)
	sta VERA_ADDR_M
	lda #$10 | ^screen_addr
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
	clc
	adc #<(>screen_addr)
	sta VERA_ADDR_M
	lda #$10 | ^screen_addr
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
	lda pnt
	sta VERA_ADDR_L
	lda pnt+1
	clc
	adc #>screen_addr
	sta VERA_ADDR_M
	lda #$10 | ^screen_addr
	sta VERA_ADDR_H

	lda #1
	sta VERA_CTRL

	;source into addr2
	lda sal
	sta VERA_ADDR_L
	lda sal+1
	clc
	adc #>screen_addr
	sta VERA_ADDR_M
	lda #$10 | ^screen_addr
	sta VERA_ADDR_H

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
	clc
	adc #>screen_addr
	sta VERA_ADDR_M
	lda #$10 | ^screen_addr;auto-increment = 1
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
	ldx #<charset_addr
	stx VERA_ADDR_L
	ldx #>charset_addr
	stx VERA_ADDR_M
	ldx #$10 | ^charset_addr
	stx VERA_ADDR_H
	plx
	stz data
	stz tmp2
	rts
