;-----------------------------------------------------------------------------
; lib.inc
; Copyright (C) 2020 Frank van den Hoef
;-----------------------------------------------------------------------------

	.include "regs.inc"

	.global irq_done
	.global flash_load

;-----------------------------------------------------------------------------
; Set 16-bit variable
;-----------------------------------------------------------------------------
.macro set16 dst, src
	lda src + 0
	sta dst + 0
	lda src + 1
	sta dst + 1
.endmacro

;-----------------------------------------------------------------------------
; Set 16-bit variable
;-----------------------------------------------------------------------------
.macro set16_val dst, val
	lda #<val
	sta dst + 0
	lda #>val
	sta dst + 1
.endmacro

;-----------------------------------------------------------------------------
; Add two 16-bit variables
;-----------------------------------------------------------------------------
.macro add16 dst, src_a, src_b
	clc
	lda src_a + 0
	adc src_b + 0
	sta dst + 0
	lda src_a + 1
	adc src_b + 1
	sta dst + 1
.endmacro

;-----------------------------------------------------------------------------
; Add value to 16-bit variables
;-----------------------------------------------------------------------------
.macro add16_val dst, src, val
	clc
	lda src + 0
	adc #<val
	sta dst + 0
	lda src + 1
	adc #>val
	sta dst + 1
.endmacro

;-----------------------------------------------------------------------------
; Subtract two 16-bit variables
;-----------------------------------------------------------------------------
.macro sub16 dst, src_a, src_b
	sec
	lda src_a + 0
	sbc src_b + 0
	sta dst + 0

	lda src_a + 1
	sbc src_b + 1
	sta dst + 1
.endmacro

;-----------------------------------------------------------------------------
; Increment 16-bit variable
;-----------------------------------------------------------------------------
.macro inc16 dst
	.local l1
	inc dst
	bne l1
	inc dst + 1
l1:
.endmacro

;-----------------------------------------------------------------------------
; Decrement 16-bit variable
;-----------------------------------------------------------------------------
.macro dec16 dst
	.local l1
	lda dst
	bne l1
	dec dst + 1
l1:	dec dst
.endmacro

;-----------------------------------------------------------------------------
; Compare two 16-bit variables
;-----------------------------------------------------------------------------
.macro cmp16 src_a, src_b, lbl_not_equal
	lda src_a + 0
	cmp src_b + 0
	bne lbl_not_equal
	lda src_a + 1
	cmp src_b + 1
	bne lbl_not_equal
.endmacro

;-----------------------------------------------------------------------------
; Compare 16-bit variable with value
;-----------------------------------------------------------------------------
.macro cmp16_val src, val, lbl_not_equal
	lda src + 0
.if !(.const(val) && <val = 0)
	cmp #<val
.endif
	bne lbl_not_equal
	lda src + 1
.if !(.const(val) && <val = 0)
	cmp #>val
.endif
	bne lbl_not_equal
.endmacro

;-----------------------------------------------------------------------------
; Set 32-bit variable
;-----------------------------------------------------------------------------
.macro set32 dst, src
	lda src + 0
	sta dst + 0
	lda src + 1
	sta dst + 1
	lda src + 2
	sta dst + 2
	lda src + 3
	sta dst + 3
.endmacro

;-----------------------------------------------------------------------------
; Set 32-bit variable
;-----------------------------------------------------------------------------
.macro set32_val dst, val
.if .const(val) && <val = 0
	stz dst + 0
.else
	lda #<val
	sta dst + 0
.endif
.if .const(val) && >val = 0
	stz dst + 1
.else
	lda #>val
	sta dst + 1
.endif
.if .const(val) && ^val = 0
	stz dst + 2
.else
	lda #^val
	sta dst + 2
.endif
.if .const(val) && (.hibyte(.hiword(val))) = 0
	stz dst + 3
.else
	lda #(.hibyte(.hiword(val)))
	sta dst + 3
.endif
.endmacro

;-----------------------------------------------------------------------------
; Add two 32-bit variables
;-----------------------------------------------------------------------------
.macro add32 dst, src_a, src_b
	clc
	lda src_a + 0
	adc src_b + 0
	sta dst + 0
	lda src_a + 1
	adc src_b + 1
	sta dst + 1
	lda src_a + 2
	adc src_b + 2
	sta dst + 2
	lda src_a + 3
	adc src_b + 3
	sta dst + 3
.endmacro

;-----------------------------------------------------------------------------
; Compare two 32-bit variables
;-----------------------------------------------------------------------------
.macro cmp32 src_a, src_b, lbl_not_equal
	lda src_a + 0
	cmp src_b + 0
	bne lbl_not_equal
	lda src_a + 1
	cmp src_b + 1
	bne lbl_not_equal
	lda src_a + 2
	cmp src_b + 2
	bne lbl_not_equal
	lda src_a + 3
	cmp src_b + 3
	bne lbl_not_equal
.endmacro

;-----------------------------------------------------------------------------
; Add 32-bit and 16-bit variable
;-----------------------------------------------------------------------------
.macro add32_16 dst, src_a, src_b
	clc

	lda src_a + 0
	adc src_b + 0
	sta dst + 0

	lda src_a + 1
	adc src_b + 1
	sta dst + 1

	lda src_a + 2
	adc #0
	sta dst + 2

	lda src_a + 3
	adc #0
	sta dst + 3
.endmacro

;-----------------------------------------------------------------------------
; Increment 32-bit variable
;-----------------------------------------------------------------------------
.macro inc32 dst
	.local l1
	inc dst + 0
	bne l1
	inc dst + 1
	bne l1
	inc dst + 2
	bne l1
	inc dst + 3
l1:
.endmacro

;-----------------------------------------------------------------------------
; Decrement 32-bit variable
;-----------------------------------------------------------------------------
.macro dec32 dst
	.local l1, l2, l3
	lda dst + 0
	bne l3
	lda dst + 1
	bne l2
	lda dst + 2
	bne l1
	dec dst + 3
l1:	dec dst + 2
l2:	dec dst + 1
l3:	dec dst + 0
.endmacro

;-----------------------------------------------------------------------------
; Subtract immediate value from 32-bit variable
;-----------------------------------------------------------------------------
.macro sub32_val dst, src, val
	sec
	lda src + 0
	sbc #<val
	sta dst + 0

	lda src + 1
	sbc #>val
	sta dst + 1

	lda src + 2
	sbc #^val
	sta dst + 2

	lda src + 3
	sbc #(.hibyte(.hiword(val)))
	sta dst + 3
.endmacro

;-----------------------------------------------------------------------------
; Subtract two 32-bit variables
;-----------------------------------------------------------------------------
.macro sub32 dst, src_a, src_b
	sec
	lda src_a + 0
	sbc src_b + 0
	sta dst + 0

	lda src_a + 1
	sbc src_b + 1
	sta dst + 1

	lda src_a + 2
	sbc src_b + 2
	sta dst + 2

	lda src_a + 3
	sbc src_b + 3
	sta dst + 3
.endmacro

;-----------------------------------------------------------------------------
; Perform 32-bit shift-right on variable
;-----------------------------------------------------------------------------
.macro shr32 dst
	lsr dst + 3
	ror dst + 2
	ror dst + 1
	ror dst + 0
.endmacro

;-----------------------------------------------------------------------------
; Perform 32-bit shift-left on variable
;-----------------------------------------------------------------------------
.macro shl32 dst
	asl dst + 0
	rol dst + 1
	rol dst + 2
	rol dst + 3
.endmacro

;-----------------------------------------------------------------------------
; Copy bytes
;-----------------------------------------------------------------------------
.macro copy_bytes dst, src, count
	.local l1
	ldy #0
l1:	lda src, y
	sta dst, y
	iny
	cpy #count
	bne l1
.endmacro

;-----------------------------------------------------------------------------
; Clear bytes
;-----------------------------------------------------------------------------
.macro clear_bytes dst, count
	.local l1
	ldx #0
l1:	stz dst, x
	inx
	cpx #count
	bne l1
.endmacro

.macro set24_val dst, val
	lda #<val
	sta dst + 0
	lda #>val
	sta dst + 1
	lda #^val
	sta dst + 2
.endmacro
