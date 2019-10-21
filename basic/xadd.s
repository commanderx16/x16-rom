.PC02                   ; Enable the 65C02 instruction set.

; This file contains the assembly routines for
; floating point addition.
; The algorithm uses the following steps:
; 1. If either operand is zero, then finish immediately.
; 2. If one operand has a larger exponent than the other,
;    then shift the mantissa of the lesser value right.
; 3. Add or subtract the mantissas, depending on the signs.
; 4. In case of add, optionally increment exponent if overflow.
; 5. In case of subtract, Shift mantissa left until normalized.

xerrts   rts
xfc      jmp movfa      ; Copy from ARG to FAC.

;--------------------------------------------------------------
; Entry point for xfaddt
; On entry the two values are stored in FAC and ARG.
; The variable arisgn contains the XOR of the two sign bits.
; Additionally, the Z-flag is the value of the FAC exponent.
; On exit the sum is stored in FAC.

xfaddt   

; 1. If either operand is zero, then finish immediately.

         beq xfc        ; Jump if FAC is zero.

         lda argexp
         beq xerrts     ; Jump if ARG is zero.

; 2. If one operand has a larger exponent than the other,
;    then shift the mantissa of the lesser value right.

         ldx facov
         stx oldov      ; Rounding bits of largest operand.

         ldx #argexp    ; Assume ARG is the largest operand.

         sec
         sbc facexp
         beq @fadd4     ; Jump if no shifting needed.
         bcc @fadda     ; Jump if ARG needs shifting (has smaller exponent).

         ldy argexp
         sty facexp
         ldy argsgn
         sty facsgn

         eor #$ff
         ina

         stz oldov      ; ARG has no rounding bits.

         ldx #fac       ; Indicate FAC needs shifting.

; 2a. Shift FAC

@shffac1 clc
         bra @shffac4

@shffac3 ldy faclo      ; Shift right one byte.
         sty facov
         ldy facmo      ; mo -> lo
         sty facmo+1
         ldy facmoh     ; moh -> mo
         sty facmoh+1
         ldy facho      ; ho -> moh
         sty facho+1
         stz facho      ; 0 -> ho

@shffac4 adc #$08
         bmi @shffac3
         beq @shffac3
         sbc #$08
         tay
         beq @shffac2   ; Jump if no more shifting.

                        ; Carry is always clear here.
         lda facov
@shffac5 lsr facho      ; ho
         ror facmoh     ; moh
         ror facmo      ; mo
         ror faclo      ; lo
         ror a          ; ov
         iny
         bne @shffac5
         bra @fadd4     ; No more shifting.

@shffac2 lda facov
         bra @fadd4

; 2b. Shift ARG

@fadda   stz facov
                        ; Carry is always clear here.
         bra @shfarg4

@shfarg2 lda facov
         bra @fadd4

@shfarg3 ldy arglo      ; Shift right one byte
         sty facov
         ldy argmo      ; mo -> lo
         sty argmo+1
         ldy argmoh     ; moh -> mo
         sty argmoh+1
         ldy argho      ; ho -> moh
         sty argho+1
         stz argho      ; 0 -> ho

@shfarg4 adc #$08
         bmi @shfarg3
         beq @shfarg3
         sbc #$08
         tay
         beq @shfarg2   ; Jump if no more shifting.

                        ; Carry is always clear here.
         lda facov
@shfarg5 lsr argho
         ror argmoh
         ror argmo
         ror arglo
         ror a          ; ov
         iny
         bne @shfarg5

; 3. Add or subtract the mantissas, depending on the signs.

@fadd4   bit arisgn
         bmi @fadd5     ; Jump if operands have different sign.

; 3a. Add the mantissas.
                        ; X contains address of smallest operand.
                        ; A contains rounding bits of smallest operand.
         clc
         adc oldov
         sta facov
         lda faclo
         adc arglo
         sta faclo
         lda facmo
         adc argmo
         sta facmo
         lda facmoh
         adc argmoh
         sta facmoh
         lda facho
         adc argho
         sta facho

; 4. Optionally increment exponent if overflow in mantissa

@squeez  bcc @rndrts
         inc facexp
         beq @overr
                        ; Carry bit is set here.
         ror facho
         ror facmoh
         ror facmo
         ror faclo
         ror facov
@rndrts  rts


; Overflow. Indicate error.
@overr   ldx #errov
         jmp error


; Underflow. Result becomes zero.
@zerofc  stz facexp
         stz facsgn
         rts

@norm2   adc #1
         asl facov
         rol faclo
         rol facmo
         rol facmoh
         rol facho
@norm1   bpl @norm2     ; We must shift left one bit

; Adjust exponent by amount of shifting.
         sec
         sbc facexp
         bcs @zerofc
         eor #$ff
         adc #1
         sta facexp
         rts

@fadd5

; 3b. Subtract the mantissas.
                        ; X contains address of smallest operand.
                        ; A contains rounding bits of smallest operand.
         ldy #facexp
         cpx #argexp
         beq @subit
         ldy #argexp

@subit   sec            ; Negate the rounding bits before adding.
         eor #$ff
         adc oldov
         sta facov
         lda 4,y
         sbc 4,x
         sta faclo
         lda 3,y
         sbc 3,x
         sta facmo
         lda 2,y
         sbc 2,x
         sta facmoh
         lda 1,y
         sbc 1,x
         sta facho
         bcs @normal

                        ; Negate FAC
         lda facsgn
         eor #$ff
         sta facsgn
         lda facho
         eor #$ff
         sta facho
         lda facmoh
         eor #$ff
         sta facmoh
         lda facmo
         eor #$ff
         sta facmo
         lda faclo
         eor #$ff
         sta faclo
         lda facov
         eor #$ff
         ina
         sta facov
         bne @normal
         inc faclo
         bne @normal
         inc facmo
         bne @normal
         inc facmoh
         bne @normal
         inc facho

; 5. Shift mantissa left until normalized.

@normal  lda #0
         clc
@norm3   ldx facho
         bne @norm1
                        ; We must shift left a whole byte
         ldx facho+1
         stx facho
         ldx facmoh+1
         stx facmoh
         ldx facmo+1
         stx facmo
         ldx facov
         stx faclo
         stz facov
         adc #$08
         cmp #$20
         bne @norm3
         jmp @zerofc    ; Underflow

