.include "../../mac.inc"
.include "../../regs.inc"
.include "../../io.inc"

.export k_GetScanLine
.export k_StoreVRAM
.export k_SetVRAMPtrFG, k_SetVRAMPtrBG
.global inc_bgpage

.segment "GRAPH"

;---------------------------------------------------------------
; GetScanLine                                             $C13C
;
; Function:  Returns the address of the beginning of a scanline
; Pass:      x   scanline nbr
; Return:    r5  add of 1st byte of foreground scr
;            r6  add of 1st byte of background scr
; Destroyed: a
;---------------------------------------------------------------
; XXX This is deprecated
k_GetScanLine:
	PushW r3
	LoadW r3, 0
	jsr k_SetVRAMPtrFG
	jsr k_SetVRAMPtrBG
	PopW r3
	rts

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
; StoreVRAM
;
; Function:  Stores a color in VRAM and advances the VRAM pointer
; Pass:      a   color
;            x   y pos
; Destroyed: preserves all registers
;---------------------------------------------------------------
k_StoreVRAM:
	sta veradat
	rts

