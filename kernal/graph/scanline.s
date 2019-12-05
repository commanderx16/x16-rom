.export graph_init
.export graph_clear

.export GRAPH_start_direct
;.export GRAPH_start_direct_OLD

.export GRAPH_set_pixel
.global GRAPH_filter_points

.export SetVRAMPtrFG, SetVRAMPtrBG
.export SetVRAMPtrFG_NEW, SetVRAMPtrBG_NEW

.segment "GRAPH"

graph_init:
	LoadW k_dispBufferOn, ST_WR_FORE
	rts

graph_clear:
	PushB col1
	MoveB col_bg, col1
	LoadW r3, 0
	LoadW r4, SC_PIX_WIDTH-1
	LoadB r2L, 0
	LoadB r2H, SC_PIX_HEIGHT-1
	lda #0
	jsr GRAPH_draw_rect
	PopB col1
	rts

;---------------------------------------------------------------
; GRAPH_start_direct_OLD
;
; Function:  Sets up the VRAM/BG address of a pixel
; Pass:      r3     x pos
;            x      y pos
; Destroyed: a
;---------------------------------------------------------------

;NEW---------------------------------------------------------------
;NEW GRAPH_start_direct
;NEW
;NEW Function:  Sets up the VRAM/BG address of a pixel
;NEW Pass:      r0     x pos
;NEW            r1     y pos
;NEW Destroyed: a
;NEW---------------------------------------------------------------
GRAPH_start_direct:
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
	PushW r0
	PushW r1
	MoveW r3, r0
	stx r1L
	jsr SetVRAMPtrFG_NEW
	PopW r1
	PopW r0
@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
	PushW r0
	PushW r1
	MoveW r3, r0
	stx r1L
	stz r1H
	jsr SetVRAMPtrBG_NEW
	PopW r1
	PopW r0
@2:	rts

SetVRAMPtrFG:
	PushW r0
	PushW r1
	MoveW r3, r0
	stx r1L
	jsr SetVRAMPtrFG_NEW
	PopW r1
	PopW r0
	rts

SetVRAMPtrFG_NEW:
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
	AddW r0, veralo
	rts

SetVRAMPtrBG:
	PushW r0
	PushW r1
	MoveW r3, r0
	stx r1L
	jsr SetVRAMPtrBG_NEW
	PopW r1
	PopW r0
	rts

SetVRAMPtrBG_NEW:
; For BG storage, we have to work with 8 KB banks.
; Lines are 320 bytes, and 8 KB is not divisible by 320,
; so the base address of certain lines would be so close
; to the top of a bank that lda (ptr_bg),y shoots over the
; end. Therefore, we need to add memory gaps at certain
; lines to jump over the bank boundaries.
	cpx #25
	bcc @1
	inx
	cpx #51
	bcc @1
	inx
	cpx #76
	bcc @1
	inx
	cpx #102
	bcc @1
	inx
	cpx #128
	bcc @1
	inx
	cpx #153
	bcc @1
	inx
	cpx #179
	bcc @1
	inx
	cpx #204
	bcc @1
	inx
@1:
	stz ptr_bg+1
	lda r0L
	asl
	rol ptr_bg+1
	asl
	rol ptr_bg+1
	asl
	rol ptr_bg+1
	asl
	rol ptr_bg+1
	asl
	rol ptr_bg+1
	asl
	rol ptr_bg+1
	sta ptr_bg
	lda r0L
	clc
	adc ptr_bg+1
	sta ptr_bg+1

	lda ptr_bg+1
	pha
	and #$1f
	ora #$a0
	sta ptr_bg+1
	pla
	ror ; insert the carry from addition above, since the BG
	    ; data exceeds 64 KB because of the added gaps
	lsr
	lsr
	lsr
	lsr
	inc       ; start at bank 1
	sta d1pra ; RAM bank

	; add X
	AddW r0, ptr_bg
	rts

;---------------------------------------------------------------
; GRAPH_set_pixel
;
; Function:  Stores a color in VRAM/BG and advances the pointer
; Pass:      a   color
; Destroyed: preserves all registers
;---------------------------------------------------------------
GRAPH_set_pixel:
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
; FG version
	sta veradat
@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
; BG version
	sta (ptr_bg)
	inc ptr_bg
	beq inc_bgpage
@2:	rts
inc_bgpage:
	pha
	inc ptr_bg+1
	lda ptr_bg+1
	cmp #$c0
	beq @1
	pla
	rts
@1:	inc d1pra ; RAM bank
	lda #$a0
	sta ptr_bg+1
	pla
	rts

;---------------------------------------------------------------
; GRAPH_get_pixel
;
; Pass:      r3   x position of pixel (0-319)
;            r11L y position of pixel (0-199)
; Return:    a    color of pixel
; Destroyed: a, x, y
;---------------------------------------------------------------
GRAPH_get_pixel:
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
	PushW r0
	PushW r1
	MoveW r3, r0
	MoveB r11L, r1L
	jsr SetVRAMPtrFG_NEW
	PopW r1
	PopW r0
	lda veradat
	rts

@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
	PushW r0
	PushW r1
	MoveW r3, r0
	MoveB r11L, r1L
	jsr SetVRAMPtrBG_NEW
	PopW r1
	PopW r0
	lda (ptr_bg)
	inc ptr_bg
	beq inc_bgpage
	rts

@2:	lda #0
	rts

;---------------------------------------------------------------
; GRAPH_filter_points
;
; Pass:      r7   number of points
;            r9   pointer to filter routine:
;                 Pass:    a  color
;                 Return:  a  color
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
GRAPH_filter_points:
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
	jsr FilterPointsFG
@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
	jmp FilterPointsBG
@2:	rts

FilterPointsFG:
	PushB r8H
	LoadB r8H, $4c
	lda veralo
	ldx veramid
	inc veractl ; 1
	sta veralo
	stx veramid
	lda #$11
	sta verahi
	stz veractl ; 0
	sta verahi

	ldx r7H
	beq @2

; full blocks, 8 bytes at a time
	ldy #$20
@1:	jsr filter_y
	dex
	bne @1

; partial block, 8 bytes at a time
@2:	lda r7L
	lsr
	lsr
	lsr
	beq @6
	tay
	jsr filter_y

; remaining 0 to 7 bytes
@6:	lda r7L
	and #7
	beq @4
	tay
@3:	lda veradat
	jsr r8H
	sta veradat2
	dey
	bne @3
@4:	PopB r8H
	rts

filter_y:
	lda veradat
	jsr r8H
	sta veradat2
	lda veradat
	jsr r8H
	sta veradat2
	lda veradat
	jsr r8H
	sta veradat2
	lda veradat
	jsr r8H
	sta veradat2
	lda veradat
	jsr r8H
	sta veradat2
	lda veradat
	jsr r8H
	sta veradat2
	lda veradat
	jsr r8H
	sta veradat2
	lda veradat
	jsr r8H
	sta veradat2
	dey
	bne filter_y
	rts

FilterPointsBG:
	PushB r8H
	LoadB r8H, $4c

; background version
ILineBG:
	ldx r7H
	beq @2

	ldy #0
@1:	lda (ptr_bg),y
	jsr r8H
	sta (ptr_bg),y
	iny
	bne @1
	jsr inc_bgpage
	dex
	bne @1

; partial block
@2:	ldy r7L
	beq @4
	dey
@3:	lda (ptr_bg),y
	jsr r8H
	sta (ptr_bg),y
	dey
	cpy #$ff
	bne @3
@4:	rts
