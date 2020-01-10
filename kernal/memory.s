;----------------------------------------------------------------------
; LZSA2 Decompression
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "regs.inc"
.include "mac.inc"

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
;            a    byte value
;---------------------------------------------------------------
memory_fill:
.ifp02
	tax
	lda r0H
	pha
	txa
.else
	ldx r0H
	phx
.endif
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
@4:
.ifp02
	tax
	pla
	sta r0H
	txa
.else
	plx
	stx r0H
.endif
	rts

;---------------------------------------------------------------
; memory_copy
;
; Function:  Copy a memory region to a different region. The
;            two regions may overlap.
;
; Pass:      r0   source address
;            r1   target address
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

;---------------------------------------------------------------
; memory_crc
;
; Function:  Calculate the CRC16 of a memory region.
;
; Pass:      r0   address
;            r1   number of bytes
;
; Return:    r2   CRC16 result
;---------------------------------------------------------------
memory_crc:
	lda #$ff
	sta r2L
	sta r2H

	PushB r0H
	lda r1H
	beq @2
	pha
	ldy #0
@1:	lda (r0),y
	jsr crc16_f
	iny
	bne @1
	inc r0H
	dec r1H
	bne @1
	PopB r1H
@2:	ldy r1L
	beq @4
@3:	dey
	lda (r0),y
	jsr crc16_f
	cpy #0
	bne @3
@4:	PopB r0H
	rts

; This is taken from
; http://www.6502.org/source/integers/crc-more.html
; (November 23rd, 2004, "alternate ending" version, preserving .Y)
crc16_f:
	eor r2H         ; A contained the data
	sta r2H         ; XOR it into high byte
	lsr             ; right shift A 4 bits
	lsr             ; to make top of x^12 term
	lsr             ; ($1...)
	lsr
	tax             ; save it
	asl             ; then make top of x^5 term
	eor r2L         ; and XOR that with low byte
	sta r2L         ; and save
	txa             ; restore partial term
	eor r2H         ; and update high byte
	sta r2H         ; and save
	asl             ; left shift three
	asl             ; the rest of the terms
	asl             ; have feedback from x^12
	tax             ; save bottom of x^12
	asl             ; left shift two more
	asl             ; watch the carry flag
	eor r2H         ; bottom of x^5 ($..2.)
	sta r2H         ; save high byte
	txa             ; fetch temp value
	rol             ; bottom of x^12, middle of x^5!
	eor r2L         ; finally update low byte
	ldx r2H         ; then swap high and low bytes
	sta r2H
	stx r2L
	rts
