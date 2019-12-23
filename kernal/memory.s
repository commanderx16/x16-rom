;----------------------------------------------------------------------
; LZSA2 Decompression
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "../regs.inc"
.include "../mac.inc"

.export memory_fill
.export memory_copy
.export memory_crc

.segment "MEMORY"

;---------------------------------------------------------------
; memory_fill
;
; Function:  Fill a memory region with a byte value.
;
; Pass:      r0   address
;            r1   number of bytes
;---------------------------------------------------------------
memory_fill:
	ldx r1H
	beq @2
	ldy #0
@1:	sta (r0),y
	iny
	bne @1
	inc r0H
	dex
	bne @1
@2:	ldy r1L
	beq @4
@3:	dey
	sta (r0),y
	cpy #0
	bne @3
@4:	rts

;---------------------------------------------------------------
; memory_copy
;
; Function:  Copy a memory region to a different region. The
;            two regions may overlap.
;
; Pass:      r0   source address
;            r1   destination address
;            r2   number of bytes
;
; Note:      This could be sped up by ~20% by special casing
;            the non-overlapping case.
;---------------------------------------------------------------
memory_copy:
	lda r2L
	ora r2H
	beq @7
	PushB r0L
	PushB r1H

	CmpW r0, r1
	bcc @8

; forward copy
@3:	ldy #0
	ldx r2H
	beq @5
@4:	lda (r0),y
	sta (r1),y
	iny
	bne @4
	inc r0H
	inc r1H
	dex
	bne @4
@5:	cpy r2L
	beq @6
	lda (r0),y
	sta (r1),y
	iny
	bra @5
@6:	PopB r1H
	PopB r0L
@7:	rts

; backward copy
@8:	AddB r2H, r0H
	AddB r2H, r1H
	ldx r2H
	ldy r2L
	beq @A
@9:	dey
	lda (r0),y
	sta (r1),y
	tya
	bne @9
@A:	dec r0H
	dec r1H
	txa
	beq @6
@B:	dey
	lda (r0),y
	sta (r1),y
	tya
	bne @B
	dex
	bra @A

memory_crc:
