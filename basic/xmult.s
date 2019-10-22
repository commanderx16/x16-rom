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

xfmultt  beq @multrt    ; Jump if FAC is zero.
         jsr @muldiv

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
         jmp xnormal

@muldiv  lda argexp
         beq @zeremv    ; Jump if ARG is zero.
         clc
         adc facexp
         bcc @tryoff
         bmi @goover    ; Jump if overflow.
         clc
         .byt $2c
@tryoff  bpl @zeremv    ; Jump if underflow.
         adc #$80       ; Carry is always clear here.
         beq @zeremv    ; Jump if underflow.
         sta facexp
         lda arisgn
         sta facsgn
@multrt  rts

@zeremv  pla            ; Pop of return address.
         pla
         stz facexp     ; Result is zero.
         stz facsgn
         rts

@goover  ldx #errov
         jmp error


@mltply  bne @mltpl1

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

