.export graph_init
.export graph_clear

.export k_SetVRAMPtr
.export k_SetPoint
.global k_FilterPoints

.export k_SetVRAMPtrFG, k_SetVRAMPtrBG

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
	jsr k_Rectangle
	PopB col1
	rts

;---------------------------------------------------------------
; k_SetVRAMPtr
;
; Function:  Sets up the VRAM/BG address of a pixel
; Pass:      r3     x pos
;            x      y pos
; Return:    <VERA> VRAM address of pixel
;            r6/RAMBANK BG address of pixel
;            (depending on dispBufferOn)
; Destroyed: a
;---------------------------------------------------------------
k_SetVRAMPtr:
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
	jsr k_SetVRAMPtrFG
@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
	jmp k_SetVRAMPtrBG
@2:	rts

;---------------------------------------------------------------
; k_SetVRAMPtrFG
;
; Function:  Sets up the VRAM address of a pixel
; Pass:      r3     x pos
;            x      y pos
; Return:    <VERA> VRAM address of pixel
; Destroyed: a
;---------------------------------------------------------------
k_SetVRAMPtrFG:
	; r5 = x * 320
	stz r5H
	txa
	asl
	rol r5H
	asl
	rol r5H
	asl
	rol r5H
	asl
	rol r5H
	asl
	rol r5H
	asl
	rol r5H
	sta r5L
	sta veralo
	txa
	clc
	adc r5H
	sta r5H
	sta veramid
	lda #$11
	sta verahi

	; add X
	AddW r3, veralo
	rts

;---------------------------------------------------------------
; k_SetVRAMPtrBG
;
; Function:  Sets up the BG address of a pixel
; Pass:      r3         x pos
;            x          y pos
; Return:    r6/RAMBANK BG address of pixel
; Destroyed: a
;---------------------------------------------------------------
k_SetVRAMPtrBG:
; For BG storage, we have to work with 8 KB banks.
; Lines are 320 bytes, and 8 KB is not divisible by 320,
; so the base address of certain lines would be so close
; to the top of a bank that lda (r6),y shoots over the
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
	stz r6H
	txa
	asl
	rol r6H
	asl
	rol r6H
	asl
	rol r6H
	asl
	rol r6H
	asl
	rol r6H
	asl
	rol r6H
	sta r6L
	txa
	clc
	adc r6H
	sta r6H

	lda r6H
	pha
	and #$1f
	ora #$a0
	sta r6H
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
	AddW r3, r6
	rts

;---------------------------------------------------------------
; SetPoint
;
; Function:  Stores a color in VRAM/BG and advances the pointer
; Pass:      a   color
; Destroyed: preserves all registers
;---------------------------------------------------------------
k_SetPoint:
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
; FG version
	sta veradat
@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
; BG version
	sta (r6)
	inc r6L
	beq inc_bgpage
@2:	rts
inc_bgpage:
	pha
	inc r6H
	lda r6H
	cmp #$c0
	beq @1
	pla
	rts
@1:	inc d1pra ; RAM bank
	lda #$a0
	sta r6H
	pla
	rts

;---------------------------------------------------------------
; FilterPoints
;
; Pass:      r7   number of points
;            r9   pointer to filter routine:
;                 Pass:    a  color
;                 Return:  a  color
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
k_FilterPoints:
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
@1:	lda (r6),y
	jsr r8H
	sta (r6),y
	iny
	bne @1
	jsr inc_bgpage
	dex
	bne @1

; partial block
@2:	ldy r7L
	beq @4
	dey
@3:	lda (r6),y
	jsr r8H
	sta (r6),y
	dey
	cpy #$ff
	bne @3
@4:	rts
