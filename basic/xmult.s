.PC02                   ; Enable the 65C02 instruction set.

; This file contains the assembly routine for
; floating point multiplication.

; Rounding:
; The FAC has a 5-byte mantissa, where the 5th byte (stored in facov)
; contains rounding bits that are removed after the final calculation.


;--------------------------------------------------------------
; Entry point for xfmultt
; On entry the two values are stored in FAC and ARG.
; The variable arisgn contains the XOR of the two sign bits.
; Additionally, the Z-flag is the value of the FAC exponent.
; On exit the sum is stored in FAC.

xfmultt  

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
         ldx #errov     ; Overllow
         jmp error

@tryoff  bpl @zeremv    ; Jump if underflow.
@adjust  adc #$80       ; Carry is always clear here.
         beq @zeremv    ; Jump if underflow.
         sta facexp

                        ; Copy over sign of result.
         lda arisgn
         sta facsgn

; 3. Calculate mantissa

         stz resho
         stz resmoh
         stz resmo
         stz reslo

         lda facov
         jsr @mltply
         lda faclo
         jsr @mltply
         lda facmo
         jsr @mltply
         lda facmoh
         jsr @mltply
         lda facho
         jsr @mltpl1

         lda resho
         sta facho
         lda resmoh
         sta facmoh
         lda resmo
         sta facmo
         lda reslo
         sta faclo
         jmp xnormal    ; In basic/xadd.s

@zeremv  stz facexp     ; Result is zero.
         stz facsgn
@multrt  rts


                        ; Byte is zero.
@shffac1 ldy reslo      ; lo -> ov
         sty facov
         ldy resmo      ; mo -> lo
         sty resmo+1
         ldy resmoh     ; moh -> mo
         sty resmoh+1
         ldy resho      ; ho -> moh
         sty resho+1
         stz resho      ; 0 -> ho
         rts

; 3a. Multiply a single byte

@mltply  beq @shffac1   ; If multiplying by zero, just shift result.

@mltpl1  lsr a
         ora #$80

@mltpl2  tay
         bcc @mltpl3
         clc
         lda reslo
         adc arglo
         sta reslo
         lda resmo
         adc argmo
         sta resmo
         lda resmoh
         adc argmoh
         sta resmoh
         lda resho
         adc argho
         sta resho

@mltpl3  ror resho
         ror resmoh
         ror resmo
         ror reslo
         ror facov
         tya
         lsr a
         bne @mltpl2
         rts


; Multiply Accumulator by 10.

xmul10

; 1. ARG = FAC
         jsr movaf      ; ARG = FAC; Leaves exponent in A register.

; 2. FAC *= 4
         tax            ; Exponent
         beq @xmul101   ; Return if zero.
         clc
         adc #2
         bcs @xmul102   ; Jump if overflow
         sta facexp     ; Store new exponent.

; 3. FAC += ARG
         stz arisgn
         jsr xfaddt     ; The Z flag is clear here.

; 4. FAC *= 2
         inc facexp
         beq @xmul102   ; Jump if overflow
@xmul101 rts

@xmul102 ldx #errov     ; Overllow
         jmp error


; Multiply Accumulator by 6.

xmul6

; 1. ARG = FAC
         jsr movaf      ; ARG = FAC

; 2. FAC *= 2
         tax            ; Exponent
         beq @xmul61    ; Return if zero.
         inc facexp
         beq @xmul62    ; Jump if overflow

; 3. FAC += ARG
         stz arisgn
         jsr xfaddt     ; The Z flag is clear here.

; 4. FAC *= 2
         inc facexp
         beq @xmul62    ; Overflow
@xmul61  rts

@xmul62  ldx #errov     ; Overllow
         jmp error

