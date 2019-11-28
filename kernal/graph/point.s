; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: TestPoint, DrawPoint, DrawLine syscalls

.include "../../regs.inc"
.include "../../io.inc"
.include "../../mac.inc"

.setcpu "65c02"

.import k_BitMaskPow2Rev
.import k_Dabs

.import k_SetVRAMPtrFG, k_SetVRAMPtrBG

.import k_dispBufferOn
.import k_col1

.global k_TestPoint
.global k_DrawPoint
.global k_DrawLine

.segment "GRAPH"

;---------------------------------------------------------------
; DrawLine                                                $C130
;
; Pass:      signFlg  set to recover from back screen
;                     reset for drawing
;            a        color
;            r3       x pos of 1st point (0-319)
;            r11L     y pos of 1st point (0-199)
;            r4       x pos of 2nd point (0-319)
;            r11H     y pos of 2nd point (0-199)
; Return:    -
; Destroyed: a, x, y, r4 - r8, r11
;---------------------------------------------------------------
k_DrawLine:
	php
	LoadB r7H, 0
	lda r11H
	sub r11L
	sta r7L
	bcs @1
	lda #0
	sub r7L
	sta r7L
@1:	lda r4L
	sub r3L
	sta r12L
	lda r4H
	sbc r3H
	sta r12H
	ldx #r12
	jsr k_Dabs
	CmpW r12, r7
	bcs @2
	jmp @9
@2:
	lda r7L
	asl
	sta r9L
	lda r7H
	rol
	sta r9H
	lda r9L
	sub r12L
	sta r8L
	lda r9H
	sbc r12H
	sta r8H
	lda r7L
	sub r12L
	sta r10L
	lda r7H
	sbc r12H
	sta r10H
	asl r10L
	rol r10H
	LoadB r13L, $ff
	CmpW r3, r4
	bcc @4
	CmpB r11L, r11H
	bcc @3
	LoadB r13L, 1
@3:	ldy r3H
	ldx r3L
	MoveW r4, r3
	sty r4H
	stx r4L
	MoveB r11H, r11L
	bra @5
@4:	ldy r11H
	cpy r11L
	bcc @5
	LoadB r13L, 1
@5:	lda k_col1
	plp
	php
	jsr k_DrawPoint
	CmpW r3, r4
	bcs @8
	inc r3L
	bne @6
	inc r3H
@6:	bbrf 7, r8H, @7
	AddW r9, r8
	bra @5
@7:	AddB_ r13L, r11L
	AddW r10, r8
	bra @5
@8:	plp
	rts
@9:	lda r12L
	asl
	sta r9L
	lda r12H
	rol
	sta r9H
	lda r9L
	sub r7L
	sta r8L
	lda r9H
	sbc r7H
	sta r8H
	lda r12L
	sub r7L
	sta r10L
	lda r12H
	sbc r7H
	sta r10H
	asl r10L
	rol r10H
	LoadW r13, $ffff
	CmpB r11L, r11H
	bcc @B
	CmpW r3, r4
	bcc @A
	LoadW r13, 1
@A:	MoveW r4, r3
	ldx r11L
	lda r11H
	sta r11L
	stx r11H
	bra @C
@B:	CmpW r3, r4
	bcs @C
	LoadW r13, 1
@C:	lda k_col1
	plp
	php
	jsr k_DrawPoint
	CmpB r11L, r11H
	bcs @E
	inc r11L
	bbrf 7, r8H, @D
	AddW r9, r8
	bra @C
@D:	AddW r13, r3
	AddW r10, r8
	bra @C
@E:	plp
	rts

;---------------------------------------------------------------
; DrawPoint                                               $C133
;
; Pass:      r3       x pos of point (0-319)
;            r11L     y pos of point (0-199)
;            signFlg  0: draw col1; 1: recover
; Return:    -
; Destroyed: a, x, y, r5 - r6
;---------------------------------------------------------------
k_DrawPoint:
	bmi @3
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE

	ldx r11L
	jsr k_SetVRAMPtrFG
	lda k_col1
	sta veradat

@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
	ldx r11L
	jsr k_SetVRAMPtrBG
	lda k_col1
	sta (r6)
@2:	rts
; recover
@3:
	ldx r11L
	jsr k_SetVRAMPtrFG
	jsr k_SetVRAMPtrBG

	lda (r6)
	sta veradat
	rts

;---------------------------------------------------------------
; TestPoint                                               $C13F
;
; Pass:      r3   x position of pixel (0-319)
;            r11L y position of pixel (0-199)
; Return:    a    color of pixel
; Destroyed: a, x, y, r5, r6
;---------------------------------------------------------------
k_TestPoint:
	bbrf 7, k_dispBufferOn, @1 ; ST_WR_FORE
	ldx r11L
	jsr k_SetVRAMPtrFG
	lda veradat
	rts

@1:	bbrf 6, k_dispBufferOn, @2 ; ST_WR_BACK
	ldx r11L
	jsr k_SetVRAMPtrBG
	lda (r6)
	rts

@2:	lda #0
	rts
