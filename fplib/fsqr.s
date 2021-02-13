;----------------------------------------------------------------------
; Floating Point Library for 6502: SQR
;----------------------------------------------------------------------
; (C)2020 Michael Jørgensen, License: 2-clause BSD

; This file contains the assembly routine for the square root function.
;
; The method used is to first calculate an initial approximation to the result,
; and then to refine this approximation using Newton's method.
; 
; ** Newton's method.
; If S if the value we wish to calculate the square root of, and x is our
; initial approximation, then a new and better approximation is given by:
; x' = (x + S/x)/2.
; 
; The division by 2 is a simple decrement of the floating point exponent, and the
; addition above will be of two almost equal operands, and therefore usually won't
; require any shifting. In other words, the addition is very fast. Only the
; division will be time consuming.
; 
; Newton's method is a quadratic algorithm which means the number of accurate
; bits in the mantissa doubles on each iteration. If the initial approximation
; has eight bits of accuracy, then two iterations of Newton's method will give
; a perfectly accurate result (within the 32-bit mantissa).
; 
; ** Initial approximation.
; The exponent of the result is half that of the argument. However, we must add
; 1 before halving, to get the correct value.
; Values between 1 and 2 have an exponent of 0x81, while values between 2 and 4
; have an exponent of 0x82. In both cases, the result will be between 1 and 2
; and have an exponent of 0x81.
; So we add 1, then shift right, and finally add 0x40.

; The HO byte of the result will be found using a table lookup, based on the
; HO byte of the argument as well as the parity of the exponent.
; Since bit 7 of the HO byte is always 1, then replacing that bit with the 
; parity of the exponent gives a single 8-bit value that can be used as index
; into a table giving the HO byte of the result.

itercnt = sgnflg

; The first half of this table is 128*sqrt(i/128 + 1), where i is the index. This 
; corresponds to the square roots of the numbers from 1 to 2.
; The second half of this table is 128*sqrt(i/64). This 
; corresponds to the square roots of the numbers from 2 to 4.
sqrtab   .byt $80, $81, $81, $82, $82, $83, $83, $84, $84, $85, $85, $86, $86, $87, $87, $88
         .byt $88, $88, $89, $89, $8A, $8A, $8B, $8B, $8C, $8C, $8D, $8D, $8E, $8E, $8E, $8F
         .byt $8F, $90, $90, $91, $91, $92, $92, $92, $93, $93, $94, $94, $95, $95, $95, $96
         .byt $96, $97, $97, $98, $98, $98, $99, $99, $9A, $9A, $9B, $9B, $9B, $9C, $9C, $9D
         .byt $9D, $9D, $9E, $9E, $9F, $9F, $9F, $A0, $A0, $A1, $A1, $A1, $A2, $A2, $A3, $A3
         .byt $A3, $A4, $A4, $A5, $A5, $A5, $A6, $A6, $A6, $A7, $A7, $A8, $A8, $A8, $A9, $A9
         .byt $AA, $AA, $AA, $AB, $AB, $AB, $AC, $AC, $AD, $AD, $AD, $AE, $AE, $AE, $AF, $AF
         .byt $AF, $B0, $B0, $B1, $B1, $B1, $B2, $B2, $B2, $B3, $B3, $B3, $B4, $B4, $B4, $B5

         .byt $B5, $B6, $B7, $B7, $B8, $B9, $BA, $BA, $BB, $BC, $BC, $BD, $BE, $BE, $BF, $C0
         .byt $C0, $C1, $C2, $C2, $C3, $C4, $C4, $C5, $C6, $C6, $C7, $C8, $C8, $C9, $C9, $CA
         .byt $CB, $CB, $CC, $CD, $CD, $CE, $CE, $CF, $D0, $D0, $D1, $D2, $D2, $D3, $D3, $D4
         .byt $D5, $D5, $D6, $D6, $D7, $D8, $D8, $D9, $D9, $DA, $DB, $DB, $DC, $DC, $DD, $DD
         .byt $DE, $DF, $DF, $E0, $E0, $E1, $E1, $E2, $E3, $E3, $E4, $E4, $E5, $E5, $E6, $E6
         .byt $E7, $E8, $E8, $E9, $E9, $EA, $EA, $EB, $EB, $EC, $ED, $ED, $EE, $EE, $EF, $EF
         .byt $F0, $F0, $F1, $F1, $F2, $F2, $F3, $F3, $F4, $F4, $F5, $F6, $F6, $F7, $F7, $F8
         .byt $F8, $F9, $F9, $FA, $FA, $FB, $FB, $FC, $FC, $FD, $FD, $FE, $FE, $FF, $FF, $FF


;--------------------------------------------------------------
; Entry point for sqr
; On entry the value is stored in FAC.
; On exit the square root is stored in FAC.

sqr
         lda facexp

                        ; If the operand is zero, then finish immediately.
         bne @s0
         rts         
@s0         
                        ; If the operand is negative, the finish with error.
         bit facsgn
         bpl @s1
         jmp fcerr
@s1         
                        ; Copy original value from FAC to TEMP1
         sta tempf1
         ldx facho
         stx tempf1+1
         ldx facmoh
         stx tempf1+2
         ldx facmo
         stx tempf1+3
         ldx faclo
         stx tempf1+4

                        ; Calculate the new exponent
         ina            ; Increment before shift to get correct rounding.
         lsr
         php            ; Store carry flag
         clc
         adc #$40
         sta facexp

                        ; Calculate index into lookup table
         lda facho
         asl            ; Remove bit 7
         plp            ; Retrieve carry
         ror

                        ; Perform lookup to get initial value
         tax
         lda sqrtab,X
         sta facho

                        ; It is sufficient to perform two iterations of Newton's method.
         lda #2
         sta itercnt

; Perform single iteration x' = (x + S/x)/2.
; At this point, the original value (S) is in TEMP1, and the current result (x) is in FAC.
@s2
         ; Copy current result (x) from FAC to TEMP2
         lda facexp
         sta tempf2
         ldx facho
         stx tempf2+1
         ldx facmoh
         stx tempf2+2
         ldx facmo
         stx tempf2+3
         ldx faclo
         stx tempf2+4

         ; Copy original value (S) from TEMP1 to ARG
         lda tempf1
         sta argexp
         ldx tempf1+1
         stx argho
         ldx tempf1+2
         stx argmoh
         ldx tempf1+3
         stx argmo
         ldx tempf1+4
         stx arglo

         stz arisgn
         lda facexp
         jsr fdivt      ; Calculate S/x

         ; Copy current result (x) from TEMP2 to ARG
         lda tempf2
         sta argexp
         ldx tempf2+1
         stx argho
         ldx tempf2+2
         stx argmoh
         ldx tempf2+3
         stx argmo
         ldx tempf2+4
         stx arglo

         lda facexp
         jsr faddt      ; Calculate x + S/x
         dec facexp     ; Divide result by 2

         dec itercnt
         bne @s2

@ret     rts

