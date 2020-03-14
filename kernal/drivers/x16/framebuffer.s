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
	; Layer 0, 256c bitmap
	lda #$07
	sta VERA_L0_CONFIG
	stz VERA_L0_HSCROLL_H  ; Clear palette offset
	lda #((tile_base >> 9) & $FC)
	sta VERA_L0_TILEBASE

	; Enable layer 0
	lda VERA_DC_VIDEO
	ora #$10
	sta VERA_DC_VIDEO

	; Display composer: scale for 320x240
	stz VERA_CTRL
	lda #64
	sta VERA_DC_HSCALE
	sta VERA_DC_VSCALE
	rts

tile_base = $10000

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
	sta VERA_ADDR_H

; ptr_fg += x
	lda r0L
	clc
	adc ptr_fg
	sta ptr_fg
	sta VERA_ADDR_L
	lda r0H
	adc ptr_fg+1
	sta ptr_fg+1
	sta VERA_ADDR_M

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
	sta VERA_ADDR_L
	lda #>320
	adc ptr_fg+1
	sta ptr_fg+1
	sta VERA_ADDR_M
	rts

;---------------------------------------------------------------
; FB_set_pixel
;
; Function:  Stores a color in VRAM/BG and advances the pointer
; Pass:      a   color
;---------------------------------------------------------------
FB_set_pixel:
	sta VERA_DATA0
	rts

;---------------------------------------------------------------
; FB_get_pixel
;
; Pass:      r0   x pos
;            r1   y pos
; Return:    a    color of pixel
;---------------------------------------------------------------
FB_get_pixel:
	lda VERA_DATA0
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
	sta VERA_DATA0
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
:	lda VERA_DATA0
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
	inc VERA_ADDR_L
	bne @1
	inc VERA_ADDR_M
@1:	asl
	bcs @2
	inc VERA_ADDR_L
	bne @1
	inc VERA_ADDR_M
	bra @1
@2:	beq @3
	stx VERA_DATA0
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
	sty VERA_DATA0
@1:	asl
	bcc @3
	beq @4
	asl r0L
	bcs @2
	sty VERA_DATA0
	bra @1
@2:	stx VERA_DATA0
	bra @1
@3:	asl r0L
	inc VERA_ADDR_L
	bne @1
	inc VERA_ADDR_M
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
@3:	sta VERA_DATA0
	dey
	bne @3
@4:	rts

@5:	pla
	rts

fill_y:	sta VERA_DATA0
	sta VERA_DATA0
	sta VERA_DATA0
	sta VERA_DATA0
	sta VERA_DATA0
	sta VERA_DATA0
	sta VERA_DATA0
	sta VERA_DATA0
	dey
	bne fill_y
	rts

; XXX TODO support other step sizes
fill_pixels_with_step:
	ldx #$71    ; increment in steps of $40
	stx VERA_ADDR_H
	ldx r0L
:	sta VERA_DATA0
	inc VERA_ADDR_M ; increment hi -> add $140 = 320
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

	lda VERA_ADDR_L
	ldx VERA_ADDR_M
	inc VERA_CTRL ; 1
	sta VERA_ADDR_L
	stx VERA_ADDR_M
	lda #$11
	sta VERA_ADDR_H
	stz VERA_CTRL ; 0
	sta VERA_ADDR_H

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
@3:	lda VERA_DATA0
	jsr r14H
	sta VERA_DATA1
	dey
	bne @3
@4:	rts

filter_y:
	lda VERA_DATA0
	jsr r14H
	sta VERA_DATA1
	lda VERA_DATA0
	jsr r14H
	sta VERA_DATA1
	lda VERA_DATA0
	jsr r14H
	sta VERA_DATA1
	lda VERA_DATA0
	jsr r14H
	sta VERA_DATA1
	lda VERA_DATA0
	jsr r14H
	sta VERA_DATA1
	lda VERA_DATA0
	jsr r14H
	sta VERA_DATA1
	lda VERA_DATA0
	jsr r14H
	sta VERA_DATA1
	lda VERA_DATA0
	jsr r14H
	sta VERA_DATA1
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
	sta VERA_CTRL
	jsr FB_cursor_position
	stz VERA_CTRL
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
@3:	lda VERA_DATA1
	sta VERA_DATA0
	dey
	bne @3
@4:	rts

copy_y:	lda VERA_DATA1
	sta VERA_DATA0
	lda VERA_DATA1
	sta VERA_DATA0
	lda VERA_DATA1
	sta VERA_DATA0
	lda VERA_DATA1
	sta VERA_DATA0
	lda VERA_DATA1
	sta VERA_DATA0
	lda VERA_DATA1
	sta VERA_DATA0
	lda VERA_DATA1
	sta VERA_DATA0
	lda VERA_DATA1
	sta VERA_DATA0
	dey
	bne copy_y
	rts
