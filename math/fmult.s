;----------------------------------------------------------------------
; Floating Point Library for 6502: Multiplication
;----------------------------------------------------------------------
; (C)2020 Michael Jørgensen, License: 2-clause BSD

; This file contains the assembly routine for
; floating point multiplication.

; Rounding:
; The FAC has a 5-byte mantissa, where the 5th byte (stored in facov)
; contains rounding bits that are removed after the final calculation.

; A4 = fachop
; A3 = facho
; A2 = facmoh
; A1 = facmo
; A0 = faclo
; AV = facov

; B3 = argho
; B2 = argmoh
; B1 = argmo
; B0 = arglo

; C3 = resho
; C2 = resmoh
; C1 = resmo
; C0 = reslo
; CV = resov

; This routine calculates C3:C2:C1:C0:CV = A3:A2:A1:A0:AV * B3:B2:B1:B0:0
; C3 = A3*B3
; C2 = A2*B3 + A3*B2
; C1 = A1*B3 + A2*B2 + A3*B1
; C0 = A0*B3 + A1*B2 + A2*B1 + A3*B0
; CV = AV*B3 + A0*B2 + A1*B1 + A2*B0


;--------------------------------------------------------------
; Entry point for fmult
; On entry one value is stored in FAC and the other in memory pointed
; to by (A,Y).
; On exit the sum is stored in FAC.

fmult    jsr conupk

;--------------------------------------------------------------
; Entry point for fmultt
; On entry the two values are stored in FAC and ARG.
; The variable arisgn contains the XOR of the two sign bits.
; Additionally, the Z-flag is the value of the FAC exponent.
; On exit the sum is stored in FAC.

fmultt

; 1. If either operand is zero, then finish immediately.

         beq @multrt    ; Jump if FAC is zero.
         lda argexp
         beq @zeremv    ; Jump if ARG is zero.

; 2. Calculate new exponent and test for overflow/underflow.

         clc
         adc facexp
         bcc @tryoff
         clc
         bpl @adjust
         ldx #errov     ; Overflow
         jmp error

@zeremv  stz facexp     ; Result is zero.
         stz facsgn
@multrt  rts

@tryoff  bpl @zeremv    ; Jump if underflow.
@adjust  adc #$80       ; Carry is always clear here.
         beq @zeremv    ; Jump if underflow.
         sta facexp

                        ; Copy over sign of result.
         lda arisgn
         sta facsgn

; 3. Calculate mantissa

         stz reshop
         stz resho
         stz resmoh
         stz resmo
         stz reslo
         stz resov
         stz fachop

; We simultaneously calculate the four terms:
;    00:00:00:A3:A2 * B0
;  + 00:00:A3:A2:A1 * B1
;  + 00:A3:A2:A1:A0 * B2
;  + A3:A2:A1:A0:AV * B3

; First calculate 00:00:00:A3:A2 * B0
@b0      lsr arglo      ; B0
         bcc @b1
         lda resov
         clc
         adc facmoh     ; A2
         sta resov
         lda reslo
         adc facho      ; A3
         sta reslo
         lda resmo
         adc fachop     ; A4
         sta resmo
         bcc @b1
         inc resmoh
         bne @b1
         inc resho
         bne @b1
         inc reshop

; Next calculate 00:00:A3:A2:A1 * B1
@b1      lsr argmo      ; B1
         bcc @b2
         lda resov
         clc
         adc facmo      ; A1
         sta resov
         lda reslo
         adc facmoh     ; A2
         sta reslo
         lda resmo
         adc facho      ; A3
         sta resmo
         lda resmoh
         adc fachop     ; A4
         sta resmoh
         bcc @b2
         inc resho
         bne @b2
         inc reshop

; Then calculate 00:A3:A2:A1:A0 * B2
@b2      lsr argmoh     ; B2
         bcc @b3
         lda resov
         clc
         adc faclo      ; A0
         sta resov
         lda reslo
         adc facmo      ; A1
         sta reslo
         lda resmo
         adc facmoh     ; A2
         sta resmo
         lda resmoh
         adc facho      ; A3
         sta resmoh
         lda resho
         adc fachop     ; A4
         sta resho
         bcc @b3
         inc reshop

; Finally calculate A3:A2:A1:A0:AV * B3
@b3      lsr argho      ; B3
         bcc @rota
         lda resov
         clc
         adc facov      ; AV
         sta resov
         lda reslo
         adc faclo      ; A0
         sta reslo
         lda resmo
         adc facmo      ; A1
         sta resmo
         lda resmoh
         adc facmoh     ; A2
         sta resmoh
         lda resho
         adc facho      ; A3
         sta resho
         lda reshop
         adc fachop     ; A4
         sta reshop

; Shift left FAC
@rota    asl facov
         rol faclo
         rol facmo
         rol facmoh
         rol facho
         rol fachop
         bmi @fin
         jmp @b0

@fin     lda reshop
         sta facho
         lda resho
         sta facmoh
         lda resmoh
         sta facmo
         lda resmo
         sta faclo
         lda reslo
         sta facov

         jmp fnormal    ; In basic/xadd.s


; Multiply FAC by 10.

mul10

; 1. ARG = FAC
         jsr movaf      ; ARG = FAC; Leaves exponent in A register.

; 2. FAC *= 4
         tax            ; Exponent
         beq @mul101    ; Return if zero.
         clc
         adc #2
         bcs @mul102    ; Jump if overflow
         sta facexp     ; Store new exponent.

; 3. FAC += ARG
         stz arisgn
         jsr faddt      ; The Z flag is clear here.

; 4. FAC *= 2
         inc facexp
         beq @mul102    ; Jump if overflow
@mul101  rts

@mul102  ldx #errov     ; Overllow
         jmp error

