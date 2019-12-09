.export GRAPH_LL_get_info
.export GRAPH_LL_start_direct
.export GRAPH_LL_set_pixel
.export GRAPH_LL_get_pixel
.export GRAPH_LL_set_pixels
.export GRAPH_LL_get_pixels
.export GRAPH_LL_filter_pixels
.export GRAPH_LL_set_8_pixels
.export GRAPH_LL_set_8_pixels_opaque

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
; GRAPH_LL_start_direct
;
; Function:  Sets up the VRAM address of a pixel
; Pass:      r0     x pos
;            r1     y pos
;---------------------------------------------------------------
GRAPH_LL_start_direct:
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
	sta veralo
	lda r1L
	clc
	adc ptr_fg+1
	sta ptr_fg+1
	sta veramid
	lda #$11
	sta verahi

	; add X
	; XXX not also to r0??
	AddW r0, veralo
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
; Pass:      a        pattern
;            r4L      mask
;            y        color
;---------------------------------------------------------------
GRAPH_LL_set_8_pixels:
@4:	asl
	bcc @1
	asl r4L
	bcc @0
	sty veradat
@3:	cmp #0
	bne @4
	rts
@1:	asl r4L
@0:	inc veralo
	bne @3
	inc veramid
@2:	bra @3

;---------------------------------------------------------------
; GRAPH_LL_set_8_pixels_opaque
;
; Pass:      a        pattern
;            r4L      mask
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
;            r1   step size [NYI]
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

fill_pixels_with_step:
	ldy #$71    ; increment in steps of $40
	sty verahi
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
