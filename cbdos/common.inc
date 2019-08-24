; MIT License
;
; Copyright (c) 2018 Thomas Woinke, Marko Lauke, www.steckschein.de
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
.ifndef _COMMON_INC_
  _COMMON_INC_ = 1
  
.macro SetVector word, addr
			lda #<word
			sta addr
			lda #>word
			sta addr+1
.endmacro

.macro _add32 a32, a16
		clc
		lda a32+0
		adc a16+0
		sta a32+0
		lda a32+1
		adc a16+1
		sta a32+1
		lda a32+2
		adc #0
		sta a32+2
		lda a32+3
		adc #0
		sta a32+3
.endmacro

.macro _inc32 val
		.local @l1
		inc val + 0
		bne @l1
		inc val + 1
		bne @l1
		inc val + 2
		bne @l1
		inc val + 3
@l1:
.endmacro

; Decrement the 32 bit value at memory location val by one.
; 	A = ??, X & Y are unchanged.
.macro _dec32 val
		.local @l2,@l1,@l0
		lda val+0
		bne @l0
		lda val+1
		bne @l1
		lda val+2
		bne @l2
		dec val+3
@l2:	dec val+2
@l1:	dec val+1
@l0:	dec val+0
.endmacro


.macro m_memcpy src, dest, n
		.local @l
		.assert n<$80, error, "n must not >=$80"
		ldy #n-1
@l:
		lda src,y
		sta dest,y
		dey
		bpl @l
.endmacro

.macro m_memcpy2ptr src, ptr, n
		.local @l
		.assert n<$80, error, "n must not >=$80"
		ldy #n-1
@l:		lda src,y
		sta (ptr),y
		dey
		bpl @l
.endmacro

.macro m_memset dest, value, n
		.local @l
		.assert n<$80, error, "n must not >=$80"
		ldy #n-1
		lda #value
@l:		sta dest,y
		dey
		bpl @l
.endmacro

.macro m_memclr dest, n
		.assert n<$80, error, "n must not >=$80"
		.local @l
		ldx #n-1
@l:		stz dest,x
		dex
		bpl @l

.endmacro

.macro pushn addr, n
	.repeat n, i
		lda addr+i
		pha
	.endrepeat
.endmacro

.macro popn addr, n
	.repeat n, i
		pla
		lda addr+(n-i)
	.endrepeat
.endmacro

.macro saveptr ptr
	lda ptr
	pha
	lda ptr+1
	pha
.endmacro

.macro restoreptr ptr
	pla
	sta ptr+1
	pla
	sta ptr
.endmacro

.macro set_irq irq, irq_save
      copypointer $fffe, irq_save
      SetVector irq, $fffe
.endmacro

.macro restore_irq irq_save
      copypointer irq_save, $fffe
.endmacro

.macro copypointer fromptr, toptr
	.repeat 2, i
		lda fromptr+i
		sta toptr	+i
	.endrepeat
.endmacro

.macro save
	pha
	phy
	phx
.endmacro

.macro restore
	plx
	ply
	pla
.endmacro

.macro keyin
	.local @l
@l:     jsr krn_getkey
        bcc @l
.endmacro

; swap nibbles of byte in A
;http://6502.org/source/general/SWN.html
.macro swap
	ASL  A
	ADC  #$80
	ROL  A
	ASL  A
	ADC  #$80
	ROL  A
.endmacro

.macro set_bit bit, location
	lda #bit
	ora location
	sta location
.endmacro

.macro clear_bit bit, location
	lda #bit
	eor #$ff
	and location
	sta location
.endmacro

.macro dec16 word
        lda word   ; 2cl
        bne :+	   ;2/3cl
        dec word+1 ; 3cl
:       dec word   ; 3cl
.endmacro

.endif  ; _COMMON_INC_