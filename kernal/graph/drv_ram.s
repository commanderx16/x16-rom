;----------------------------------------------------------------------
; Offscreen 320x200@256c Graphics Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

; XXX This code is incomplete and not currently included in the build.

.export FB_get_info
.export FB_set_ptr
.export FB_set_pixel
.export FB_get_pixel
.export FB_set_pixels
.export FB_get_pixels
.export FB_filter_pixels

.segment "RAM_DRV"

;---------------------------------------------------------------
; FB_init
;
; Pass:      -
;---------------------------------------------------------------
FB_init:
	rts
	

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
; FB_set_ptr
;
; Function:  Sets up the VRAM address of a pixel
; Pass:      r0     x pos
;            r1     y pos
;---------------------------------------------------------------
FB_set_ptr:
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
	sta ram_bank

	; add X
	AddW r0, ptr_bg
	rts

;---------------------------------------------------------------
; FB_set_pixel
;
; Function:  Stores a color in VRAM/BG and advances the pointer
; Pass:      a   color
;---------------------------------------------------------------
FB_set_pixel:
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
@1:	inc ram_bank
	lda #$a0
	sta ptr_bg+1
	pla
	rts

;---------------------------------------------------------------
; FB_get_pixel
;
; Pass:      r0   x pos
;            r1   y pos
; Return:    a    color of pixel
;---------------------------------------------------------------
FB_get_pixel:
	lda (ptr_bg)
	inc ptr_bg
	beq inc_bgpage
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
	jsr set_pixels_BG
	PopB r1H
	PopB r0H
	rts

set_pixels_BG:
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
	sta (ptr_bg)
	inc ptr_bg
	bne @d
	jsr inc_bgpage
@d:	iny
	dex
	bne :-
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
	jsr get_pixels_BG
	PopB r1H
	PopB r0H
	rts

get_pixels_BG:
	lda r1H
	beq @a

	ldx #0
@c:	jsr @b
	inc r0H
	dec r1H
	bne @c

@a:	ldx r1L
@b:	ldy #0
:	lda (ptr_bg)
	sta (r0),y
	inc ptr_bg
	bne @d
	jsr inc_bgpage
@d:	iny
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

	ldx r0H
	beq @2

	ldy #0
@1:	lda (ptr_bg),y
	jsr r14H
	sta (ptr_bg),y
	iny
	bne @1
	jsr inc_bgpage
	dex
	bne @1

; partial block
@2:	ldy r0L
	beq @4
	dey
@3:	lda (ptr_bg),y
	jsr r14H
	sta (ptr_bg),y
	dey
	cpy #$ff
	bne @3
@4:	rts