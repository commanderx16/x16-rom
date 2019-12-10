.include "../../mac.inc"
.include "../../regs.inc"
.include "../../io.inc"

.importzp ptr_fg

.export GRAPH_LL_VERA

.segment "VERA_DRV"

GRAPH_LL_VERA:
	.word GRAPH_LL_init
	.word GRAPH_LL_get_info
	.word GRAPH_LL_set_ptr
	.word GRAPH_LL_add_ptr
	.word GRAPH_LL_get_pixel
	.word GRAPH_LL_get_pixels
	.word GRAPH_LL_set_pixel
	.word GRAPH_LL_set_pixels
	.word GRAPH_LL_set_8_pixels
	.word GRAPH_LL_set_8_pixels_opaque
	.word GRAPH_LL_fill_pixels
	.word GRAPH_LL_filter_pixels
	.word GRAPH_LL_move_pixels

;---------------------------------------------------------------
; GRAPH_LL_init
;
; Pass:      -
;---------------------------------------------------------------
GRAPH_LL_init:
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
; GRAPH_LL_get_info
;
; Return:    r0       width
;            r1       height
;            a        color depth
;---------------------------------------------------------------
GRAPH_LL_get_info:
	LoadW r0, 320
	LoadW r1, 200
	lda #8
	rts
	
;---------------------------------------------------------------
; GRAPH_LL_set_ptr
;
; Function:  Sets up the VRAM address of a pixel
; Pass:      r0     x pos
;            r1     y pos
;---------------------------------------------------------------
GRAPH_LL_set_ptr:
; ptr_fg = x * 320
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
; fallthrough

;---------------------------------------------------------------
; GRAPH_LL_add_ptr
;
; Function:  Sets up the VRAM address of a pixel (relative)
; Pass:      r0     additional x pos
;---------------------------------------------------------------
GRAPH_LL_add_ptr:
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
; GRAPH_LL_set_pixel
;
; Function:  Stores a color in VRAM/BG and advances the pointer
; Pass:      a   color
;---------------------------------------------------------------
GRAPH_LL_set_pixel:
	sta veradat
	rts

;---------------------------------------------------------------
; GRAPH_LL_get_pixel
;
; Pass:      r0   x pos
;            r1   y pos
; Return:    a    color of pixel
;---------------------------------------------------------------
GRAPH_LL_get_pixel:
	lda veradat
	rts

;---------------------------------------------------------------
; GRAPH_LL_set_pixels
;
; Function:  Stores an array of color values in VRAM/BG and
;            advances the pointer
; Pass:      r0  pointer
;            r1  count
;---------------------------------------------------------------
GRAPH_LL_set_pixels:
	PushB r0H
	PushB r1H
	jsr set_pixels_FG
	PopB r1H
	PopB r0H
	rts
	
set_pixels_FG:
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
	rts

;---------------------------------------------------------------
; GRAPH_LL_get_pixels
;
; Function:  Fetches an array of color values from VRAM/BG and
;            advances the pointer
; Pass:      r0  pointer
;            r1  count
;---------------------------------------------------------------
GRAPH_LL_get_pixels:
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
; GRAPH_LL_set_8_pixels
;
; Note: Always advances the pointer by 8 pixels.
;
; Pass:      a        pattern
;            y        color
;---------------------------------------------------------------
GRAPH_LL_set_8_pixels:
	sec
	rol
	bcs @1
	inc veralo
	bne @4
	inc veramid
	bra @4
@4:	asl
@x:	bcs @1
	inc veralo
	bne @4
	inc veramid
	bra @4
@1:	beq @5
	sty veradat
	bra @4
@5:	rts

;---------------------------------------------------------------
; GRAPH_LL_set_8_pixels_opaque
;
; Pass:      a        mask
;            r4L      pattern
;            y        color
;---------------------------------------------------------------
GRAPH_LL_set_8_pixels_opaque:
; opaque drawing with fg color .x and bg color .y
@4:	asl
	bcc @1
	asl r4L
	bcc @5
	stx veradat
	bra @3
@5:	sty veradat
@3:	cmp #0
	bne @4
	rts
@1:	asl r4L
	inc veralo
	bne @3
	inc veramid
@2:	bra @3

;---------------------------------------------------------------
; GRAPH_LL_fill_pixels
;
; Pass:      r0   number of pixels
;            r1   step size
;            a    color
;---------------------------------------------------------------
GRAPH_LL_fill_pixels:
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
; GRAPH_LL_filter_pixels
;
; Pass:      r0   number of pixels
;            r1   pointer to filter routine:
;                 Pass:    a  color
;                 Return:  a  color
;---------------------------------------------------------------
GRAPH_LL_filter_pixels:
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
; GRAPH_LL_move_pixels
;
; Pass:      r0   sx
;            r1   sy
;            r2   tx
;            r3   ty
;            r4   number of pixels
;---------------------------------------------------------------
GRAPH_LL_move_pixels:
	brk
