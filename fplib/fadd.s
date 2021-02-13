;----------------------------------------------------------------------
; Floating Point Library for 6502: Addition
;----------------------------------------------------------------------
; (C)2020 Michael Jørgensen, License: 2-clause BSD

; This file contains the assembly routines for
; floating point addition.
; The algorithm uses the following steps:
; 1. If either operand is zero, then finish immediately.
; 2. If one operand has a larger exponent than the other,
;    then shift the mantissa of the lesser value right.
; 3. Add or subtract the mantissas, depending on the signs.
; 4. In case of add, optionally increment exponent if overflow.
; 5. In case of subtract, Shift mantissa left until normalized.

; Rounding.
;
; The FAC has a 5-byte mantissa, where the 5th byte (stored in facov)
; contains rounding bits that are removed after the final calculation.
; In this routine, the rounding byte for the largest operand is stored
; in oldov, while the rounding byte for the smallest operand is stored
; in the A-regiser.

; Example floating point numbers:
; 10  :  84, 20, 00, 00, 00
;  1  :  81, 00, 00, 00, 00
;  0.5:  80, 00, 00, 00, 00
; -1  :  81, 80, 00, 00, 00


faddret1 rts

faddret2 jmp movfa      ; Copy from ARG to FAC.


;--------------------------------------------------------------
; Entry point for fadd
; On entry one value is stored in FAC and the other in memory pointed
; to by (A,Y).
; On exit the sum is stored in FAC.

fadd     jsr conupk

;--------------------------------------------------------------
; Entry point for faddt
; On entry the two values are stored in FAC and ARG.
; The variable arisgn contains the XOR of the two sign bits.
; Additionally, the Z-flag is the value of the FAC exponent.
; On exit the sum is stored in FAC.

faddt

; 1. If either operand is zero, then finish immediately.

         beq faddret2   ; Jump if FAC is zero.
         lda argexp
         beq faddret1   ; Jump if ARG is zero.


; 2. If one operand has a larger exponent than the other,
;    then shift the mantissa of the lesser value right.

         sec
         sbc facexp
         beq @expeq     ; Jump if no shifting needed. The A register is already zero.
         bcc @shfarg1   ; Jump if ARG needs shifting (has smaller exponent).

                        ; Here, FAC is the smallest operand, and ARG is the largest.
                        ; FAC will need to be shifted right,

                        ; Copy exponent and sign from ARG.
         ldy argexp
         sty facexp
         ldy argsgn
         sty facsgn

         stz oldov      ; ARG has no rounding bits.

         ldx #fac       ; Indicate FAC is the smallest operand.

; 2a. Shift FAC

                        ; A contains number of bits to rotate right.
         sec
         sbc #$08
         bmi @shffac2

                        ; A >= 8, therefore shift right one byte.
@shffac1 ldy faclo      ; lo -> ov
         sty facov
         ldy facmo      ; mo -> lo
         sty facmo+1
         ldy facmoh     ; moh -> mo
         sty facmoh+1
         ldy facho      ; ho -> moh
         sty facho+1
         stz facho      ; 0 -> ho
         sbc #$08       ; Carry is always set here.
         bpl @shffac1   ; Jump if more bytes to shift.

@shffac2 adc #$08       ; Carry is always clear here.
         beq @shffac4   ; Jump if no more shifting.

         tay
         lda facov
@shffac3 lsr facho      ; ho
         ror facmoh     ; moh
         ror facmo      ; mo
         ror faclo      ; lo
         ror a          ; ov
         dey
         bne @shffac3
         bra @manadd2   ; No more shifting.

@shffac4 lda facov      ; The A-register contains the shifted rounding bits of FAC.
         bra @manadd2


; 2c. No shifting needed.

                        ; When both operands have the same exponent,
                        ; work like ARG is the smallest operand.
@expeq   ldx facov
         stx oldov
                        ; oldov now contains rounding bits of FAC.
                        ; The A-register contains the rounding bits of ARG (i.e. zero).
         bra @manadd1


; 2b. Shift ARG

@shfarg2 lda facov      ; The A-register contains the shifted rounding bits of ARG.
         bra @manadd1

@shfarg1 ldx facov
         stx oldov      ; oldov now contains rounding bits of FAC.

         ldx #$00       ; Use X-register for rounding bits of ARG.

                        ; -A contains number of bits to rotate right.
                        ; Carry is always clear here.
         adc #$08
         bpl @shfarg6   ; Jump if less than 8 shifts.

@shfarg3 ldx arglo      ; Shift right one byte
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

@shfarg6 sbc #$08
         beq @shfarg2   ; Jump if no more shifting.

         tay
         txa            ; Rounding bits.
@shfarg5 lsr argho
         ror argmoh
         ror argmo
         ror arglo
         ror a          ; ov
         iny
         bne @shfarg5

@manadd1 ldx #argexp    ; Indicate ARG is the smallest operand.


; 3. Add or subtract the mantissas, depending on the signs.

@manadd2 bit arisgn
         bmi @mansub1   ; Jump if operands have different sign.

; 3a. Add the mantissas.
                        ; A contains rounding bits of smallest operand.
                        ; oldov contains rounding bits of largest operand.
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

         bcc @rndrts
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


; 3b. Subtract the mantissas.
@mansub1
                        ; X contains address of smallest operand.
                        ; A contains rounding bits of smallest operand.
                        ; oldov contains rounding bits of largest operand.
         ldy #facexp
         cpx #argexp
         beq @mansub2
         ldy #argexp

@mansub2 sec            ; Negate the rounding bits before adding.
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
         bcs fnormal

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
         bne fnormal
         inc faclo
         bne fnormal
         inc facmo
         bne fnormal
         inc facmoh
         bne fnormal
         inc facho

; 5. Shift mantissa left until normalized.

fnormal  bit facho
         bmi @ret       ; Jump if number is already normalized.

         lda #0         ; Number of bits rotated.
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
         jmp @zerofac

@norm2   ina
         asl facov
         rol faclo
         rol facmo
         rol facmoh
         rol facho
@norm1   bpl @norm2     ; We must shift left one bit

; Adjust exponent by amount of shifting.
         sec
         sbc facexp
         bcs @zerofac

         eor #$ff
         ina
         sta facexp
@ret     rts

; Underflow. Result becomes zero.
@zerofac stz facexp
         stz facsgn
         rts

