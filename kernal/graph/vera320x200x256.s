.export GRAPH_LL_get_info
.export GRAPH_LL_start_direct
.export GRAPH_LL_set_pixel
.export GRAPH_LL_get_pixel
.export GRAPH_LL_set_pixels
.export GRAPH_LL_get_pixels
.export GRAPH_filter_pixels

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
; GRAPH_filter_pixels
;
; Pass:      r0   number of points
;            r1   pointer to filter routine:
;                 Pass:    a  color
;                 Return:  a  color
;---------------------------------------------------------------
GRAPH_filter_pixels:
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

