;----------------------------------------------------------------------
; VERA 320x200@256c Graphics Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "mac.inc"
.include "regs.inc"
.include "io.inc"

.export FB_VERA

.segment "ZPKERNAL" : zeropage
ptr_fg:	.res 2

.segment "VERA_DRV"

FB_VERA:
	.word FB_init
	.word FB_get_info
	.word FB_set_palette
	.word FB_cursor_position
	.word FB_cursor_next_line
	.word FB_get_pixel
	.word FB_get_pixels
	.word FB_set_pixel
	.word FB_set_pixels
	.word FB_set_8_pixels
	.word FB_set_8_pixels_opaque
	.word FB_fill_pixels
	.word FB_filter_pixels
	.word FB_move_pixels

;---------------------------------------------------------------
; FB_init
;
; Pass:      -
;---------------------------------------------------------------
FB_init:
	lda #$00 ; layer0
	sta veralo
	lda #$20
	sta veramid
	lda #$1F
	sta verahi
	lda #7 << 5 | 1; 256c bitmap
	sta veradat
	lda #0
	sta veradat; tile_w=320px
	sta veradat; map_base_lo: ignore
	sta veradat; map_base_hi: ignore
	lda #<(tile_base >> 2)
	sta veradat; tile_base_lo
	lda #>(tile_base >> 2)
	sta veradat; tile_base_hi

	lda #$00        ;$F0000: composer registers
	sta veralo
	sta veramid
	ldx #0
px5a:	lda tvera_composer_g,x
	sta veradat
	inx
	cpx #tvera_composer_g_end-tvera_composer_g
	bne px5a
	rts

tile_base = $10000
hstart  =0
hstop   =640
vstart  =0
vstop   =480

tvera_composer_g:
	.byte 7 << 5 | 1  ;256c bitmap, VGA
	.byte 64, 64      ;hscale, vscale
	.byte 0           ;border color
	.byte <hstart
	.byte <hstop
	.byte <vstart
	.byte <vstop
	.byte (vstop >> 8) << 5 | (vstart >> 8) << 4 | (hstop >> 8) << 2 | (hstart >> 8)
tvera_composer_g_end:

;---------------------------------------------------------------
; FB_get_info
;
; Return:    r0       width
;            r1       height
;            a        color depth
;---------------------------------------------------------------
FB_get_info:
	LoadW r0, 320
	LoadW r1, 200
	lda #8
	rts

;---------------------------------------------------------------
; FB_set_palette
;
; Return:    r0       pointer
;            a        start index
;            x        count
;---------------------------------------------------------------
FB_set_palette:
	; TODO
	rts

;---------------------------------------------------------------
; FB_cursor_position
;
; Function:  Sets up the VRAM ptr
; Pass:      r0     x pos
;            r1     y pos
;---------------------------------------------------------------
FB_cursor_position:
; ptr_fg = y * 320
	stz ptr_fg+1
	lda r1L
	asl
	rol ptr_fg+1
	asl
	rol ptr_fg+1
	asl
	rol ptr_fg+1
	asl
	rol ptr_fg+1
	asl
	rol ptr_fg+1
	asl
	rol ptr_fg+1
	sta ptr_fg
	lda r1L
	clc
	adc ptr_fg+1
	sta ptr_fg+1

	lda #$11
	sta verahi

; ptr_fg += x
	lda r0L
	clc
	adc ptr_fg
	sta ptr_fg
	sta veralo
	lda r0H
	adc ptr_fg+1
	sta ptr_fg+1
	sta veramid

	rts

;---------------------------------------------------------------
; FB_cursor_next_line
;
; Function:  Advances VRAM ptr to next line
; Pass:      r0     additional x pos
;---------------------------------------------------------------
FB_cursor_next_line:
	lda #<320
	clc
	adc ptr_fg
	sta ptr_fg
	sta veralo
	lda #>320
	adc ptr_fg+1
	sta ptr_fg+1
	sta veramid
	rts

;---------------------------------------------------------------
; FB_set_pixel
;
; Function:  Stores a color in VRAM/BG and advances the pointer
; Pass:      a   color
;---------------------------------------------------------------
FB_set_pixel:
	sta veradat
	rts

;---------------------------------------------------------------
; FB_get_pixel
;
; Pass:      r0   x pos
;            r1   y pos
; Return:    a    color of pixel
;---------------------------------------------------------------
FB_get_pixel:
	lda veradat
	rts

;---------------------------------------------------------------
; FB_set_pixels
;
; Function:  Stores an array of color values in VRAM/BG and
;            advances the pointer
; Pass:      r0  pointer
;            r1  count
;---------------------------------------------------------------
FB_set_pixels:
	PushB r0H
	PushB r1H

	lda r1H
	beq @a

	ldx #0
@c:	jsr @b
	inc r0H
	dec r1H
	bne @c

@a:	ldx r1L
@b:	ldy #0
:	lda (r0),y
	sta veradat
	iny
	dex
	bne :-
	PopB r1H
	PopB r0H
	rts

;---------------------------------------------------------------
; FB_get_pixels
;
; Function:  Fetches an array of color values from VRAM/BG and
;            advances the pointer
; Pass:      r0  pointer
;            r1  count
;---------------------------------------------------------------
FB_get_pixels:
	PushB r0H
	PushB r1H
	jsr get_pixels_FG
	PopB r1H
	PopB r0H
	rts

get_pixels_FG:
	lda r1H
	beq @a

	ldx #0
@c:	jsr @b
	inc r0H
	dec r1H
	bne @c

@a:	ldx r1L
@b:	ldy #0
:	lda veradat
	sta (r0),y
	iny
	dex
	bne :-
	rts

;---------------------------------------------------------------
; FB_set_8_pixels
;
; Note: Always advances the pointer by 8 pixels.
;
; Pass:      a        pattern
;            x        color
;---------------------------------------------------------------
FB_set_8_pixels:
; this takes about 120 cycles, independently of the pattern
	sec
	rol
	bcs @2
	inc veralo
	bne @1
	inc veramid
@1:	asl
	bcs @2
	inc veralo
	bne @1
	inc veramid
	bra @1
@2:	beq @3
	stx veradat
	bra @1
@3:	rts

;---------------------------------------------------------------
; FB_set_8_pixels_opaque
;
; Note: Always advances the pointer by 8 pixels.
;
; Pass:      a        mask
;            r0L      pattern
;            x        color
;            y        color
;---------------------------------------------------------------
FB_set_8_pixels_opaque:
; opaque drawing with fg color .x and bg color .y
	sec
	rol
	bcc @3
	beq @4
	asl r0L
	bcs @2
	sty veradat
@1:	asl
	bcc @3
	beq @4
	asl r0L
	bcs @2
	sty veradat
	bra @1
@2:	stx veradat
	bra @1
@3:	asl r0L
	inc veralo
	bne @1
	inc veramid
	bra @1
@4:	rts

;---------------------------------------------------------------
; FB_fill_pixels
;
; Pass:      r0   number of pixels
;            r1   step size
;            a    color
;---------------------------------------------------------------
FB_fill_pixels:
	ldx r1H
	bne fill_pixels_with_step
	ldx r1L
	cpx #2
	bcs fill_pixels_with_step

; step 1
	ldx r0H
	beq @2

; full blocks, 8 bytes at a time
	ldy #$20
@1:	jsr fill_y
	dex
	bne @1

; partial block, 8 bytes at a time
@2:	pha
	lda r0L
	lsr
	lsr
	lsr
	beq @6
	tay
	pla
	jsr fill_y

; remaining 0 to 7 bytes
	pha
@6:	lda r0L
	and #7
	beq @5
	tay
	pla
@3:	sta veradat
	dey
	bne @3
@4:	rts

@5:	pla
	rts

fill_y:	sta veradat
	sta veradat
	sta veradat
	sta veradat
	sta veradat
	sta veradat
	sta veradat
	sta veradat
	dey
	bne fill_y
	rts

; XXX TODO support other step sizes
fill_pixels_with_step:
	ldx #$71    ; increment in steps of $40
	stx verahi
	ldx r0L
:	sta veradat
	inc veramid ; increment hi -> add $140 = 320
	dex
	bne :-
	rts

;---------------------------------------------------------------
; FB_filter_pixels
;
; Pass:      r0   number of pixels
;            r1   pointer to filter routine:
;                 Pass:    a  color
;                 Return:  a  color
;---------------------------------------------------------------
FB_filter_pixels:
	; build a JMP instruction
	LoadB r14H, $4c
	MoveW r1, r15

	lda veralo
	ldx veramid
	inc veractl ; 1
	sta veralo
	stx veramid
	lda #$11
	sta verahi
	stz veractl ; 0
	sta verahi

	ldx r0H
	beq @2

; full blocks, 8 bytes at a time
	ldy #$20
@1:	jsr filter_y
	dex
	bne @1

; partial block, 8 bytes at a time
@2:	lda r0L
	lsr
	lsr
	lsr
	beq @6
	tay
	jsr filter_y

; remaining 0 to 7 bytes
@6:	lda r0L
	and #7
	beq @4
	tay
@3:	lda veradat
	jsr r14H
	sta veradat2
	dey
	bne @3
@4:	rts

filter_y:
	lda veradat
	jsr r14H
	sta veradat2
	lda veradat
	jsr r14H
	sta veradat2
	lda veradat
	jsr r14H
	sta veradat2
	lda veradat
	jsr r14H
	sta veradat2
	lda veradat
	jsr r14H
	sta veradat2
	lda veradat
	jsr r14H
	sta veradat2
	lda veradat
	jsr r14H
	sta veradat2
	lda veradat
	jsr r14H
	sta veradat2
	dey
	bne filter_y
	rts

;---------------------------------------------------------------
; FB_move_pixels
;
; Pass:      r0   source x
;            r1   source y
;            r2   target x
;            r3   target y
;            r4   number of pixels
;---------------------------------------------------------------
FB_move_pixels:
; XXX sy == ty && sx < tx && sx + c > tx -> backwards!

	lda #1
	sta veractl
	jsr FB_cursor_position
	stz veractl
	PushW r0
	PushW r1
	MoveW r2, r0
	MoveW r3, r1
	jsr FB_cursor_position
	PopW r1
	PopW r0

	ldx r4H
	beq @2

; full blocks, 8 bytes at a time
	ldy #$20
@1:	jsr copy_y
	dex
	bne @1

; partial block, 8 bytes at a time
@2:	lda r4L
	lsr
	lsr
	lsr
	beq @6
	tay
	jsr copy_y

; remaining 0 to 7 bytes
@6:	lda r4L
	and #7
	beq @4
	tay
@3:	lda veradat2
	sta veradat
	dey
	bne @3
@4:	rts

copy_y:	lda veradat2
	sta veradat
	lda veradat2
	sta veradat
	lda veradat2
	sta veradat
	lda veradat2
	sta veradat
	lda veradat2
	sta veradat
	lda veradat2
	sta veradat
	lda veradat2
	sta veradat
	lda veradat2
	sta veradat
	dey
	bne copy_y
	rts
