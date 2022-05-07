;----------------------------------------------------------------------
; Memory
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "regs.inc"
.include "io.inc"
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
	ldx r1L
	bne @0
	ldx r1H
	beq @5
@0:	ldx r0H
	cpx #IO_PAGE    ; detect I/O area
	beq io_fill
	phx
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
@4:	plx
	stx r0H
@5:	rts

io_fill:
	ldx r1H
	beq @2
	ldy #0
@1:	sta (r0)
	iny
	bne @1
	dex
	bne @1
@2:	ldy r1L
	beq @4
@3:	dey
	sta (r0)
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

; detect I/O area
	lda r0H
	cmp #IO_PAGE
	bne @1
	lda r1H
	cmp #IO_PAGE
	beq @0
	jmp io_fetch
@0:	jmp io_copy
@1:	lda r1H
	cmp #IO_PAGE
	beq io_stash

	PushB r0H
	PushB r1H

	CmpW r0, r1
	bcc @8

; RAM forward copy
	ldy #0
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
	PopB r0H
@7:	rts

; RAM backward copy
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

; copy from RAM to I/O
io_stash:
	PushB r0H
	ldy #0
	ldx r2H
	beq @5
@4:	lda (r0),y
	sta (r1)
	iny
	bne @4
	inc r0H
	dex
	bne @4
@5:	cpy r2L
	beq @6
	lda (r0),y
	sta (r1)
	iny
	bra @5
@6:	PopB r0H
	rts

io_fetch:
	PushB r1H
	ldy #0
	ldx r2H
	beq @5
@4:	lda (r0)
	sta (r1),y
	iny
	bne @4
	inc r1H
	dex
	bne @4
@5:	cpy r2L
	beq @6
	lda (r0)
	sta (r1),y
	iny
	bra @5
@6:	PopB r1H
	rts

io_copy:
	ldy #0
	ldx r2H
	beq @5
@4:	lda (r0)
	sta (r1)
	iny
	bne @4
	dex
	bne @4
@5:	cpy r2L
	beq @6
	lda (r0)
	sta (r1)
	iny
	bra @5
@6:	rts

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

	lda r0H
	cmp #IO_PAGE
	beq io_crc
	pha
	lda r1H
	beq @2
	ldy #0
@1:	lda (r0),y
	jsr crc16_f
	iny
	bne @1
	inc r0H
	dec r1H
	bne @1
@2:	ldy r1L
	beq @4
@3:	dey
	lda (r0),y
	jsr crc16_f
	cpy #0
	bne @3
@4:	PopB r0H
	rts

io_crc:
	lda r1H
	beq @2
	ldy #0
@1:	lda (r0)
	jsr crc16_f
	iny
	bne @1
	dec r1H
	bne @1
@2:	ldy r1L
	beq @4
@3:	dey
	lda (r0)
	jsr crc16_f
	cpy #0
	bne @3
@4:	rts

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
