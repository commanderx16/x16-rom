; Code by Barry Yost (a.k.a. ZeroByte) and MooingLemur
; - 2022

; This file is for code dealing with the VERA PSG

.include "io.inc" ; for VERA symbols

.importzp azp0, azp0L, azp0H

.export psg_init
.export psg_playfreq
.export psg_setvol

.import psgtmp1
.import psg_atten

.macro PRESERVE_VERA
	; save the state of VERA data0 / CTRL registers
	lda VERA_CTRL
	pha
	lda VERA_ADDR_L
	pha
	lda VERA_ADDR_M
	pha
	lda VERA_ADDR_H
	pha
.endmacro

.macro RESTORE_VERA
	; restore VERA data0 / CTRL
	pla
	sta VERA_ADDR_H
	pla
	sta VERA_ADDR_M
	pla
	sta VERA_ADDR_L
	pla
	and #$7F ; clear the VERA reset bit (just in case)
	sta VERA_CTRL
.endmacro

.macro SET_VERA_STRIDE stride
   .ifnblank stride
      .if stride < 0
         lda #((^VERA_PSG_BASE) | $08 | ((0-stride) << 4)))
      .else
         lda #(^VERA_PSG_BASE | (stride << 4))
      .endif
   .else
      lda #(^VERA_PSG_BASE) | $10
   .endif
	sta VERA_ADDR_H
.endmacro

.macro SET_VERA_PSG_POINTER stride, offset
	; "input": voice number is in .A

	; point data0 at PSG registers
	stz VERA_CTRL
	and #$0F
	asl
	asl
	clc
	.ifnblank offset
	adc #<(VERA_PSG_BASE + offset)
	.else
	adc #<(VERA_PSG_BASE)
	.endif
	sta VERA_ADDR_L
	lda #>VERA_PSG_BASE
	sta VERA_ADDR_M
	SET_VERA_STRIDE stride
.endmacro

.macro PRESERVE_AND_SET_BANK
	lda ram_bank
	pha
	stz ram_bank
.endmacro

.macro RESTORE_BANK
	pla
	sta ram_bank
.endmacro


;---------------------------------------------------------------
; Re-initialize the VERA PSG to default state (everything off).
;---------------------------------------------------------------
; inputs: none
; affects: .A .X
; returns: none
;
.proc psg_init: near
	PRESERVE_AND_SET_BANK
	PRESERVE_VERA

	lda #0
	SET_VERA_PSG_POINTER

	; write zero into all 64 PSG registers.
	lda #64
loop:
	stz VERA_DATA0
	dec
	bne loop

	ldx #16
loop2:
	stz psg_atten-1,x
	dex
	bne loop2

	RESTORE_VERA
	RESTORE_BANK
	rts
.endproc

;-----------------------------------------------------------------
; psg_playfreq
;-----------------------------------------------------------------
; Convenience routine to set PSG voice to freq at max vol
; inputs: .A    = voice
;         .X .Y = 16-bit PSG frequency
;-----------------------------------------------------------------

.proc psg_playfreq: near
	and #$0F
	sta psgtmp1

	PRESERVE_AND_SET_BANK
	PRESERVE_VERA

	lda psgtmp1
	SET_VERA_PSG_POINTER

	; Set frequency
	stx VERA_DATA0
	sty VERA_DATA0

	; Retrieve the voice
	ldx psgtmp1
	
	; Retrieve L/R, set them both on if they're not set
	; otherwise keep state
	SET_VERA_STRIDE 0

	lda VERA_DATA0
	and #$C0
	bne :+
	lda #$C0
:	sta psgtmp1

	lda #$3F          ; max volume
	sec
	sbc psg_atten,x   ; apply attenuation
	bpl :+
	lda #$00          ; clamp at 0
:	ora psgtmp1       ; apply L+R channels
	sta VERA_DATA0    ; set VERA volume
	
	RESTORE_VERA
	RESTORE_BANK
	rts
.endproc

;-----------------------------------------------------------------
; psg_setvol
;-----------------------------------------------------------------
; Set PSG voice volume w/ attenuation
; 
; inputs: .A = voice
;         .X = volume
; clobbers: .Y
;-----------------------------------------------------------------

.proc psg_setvol: near
	and #$0F
	tay

	PRESERVE_AND_SET_BANK
	PRESERVE_VERA

	tya
	SET_VERA_PSG_POINTER 0, 2 ; 0 stride, offset 2 (volume register)

	; Retrieve L/R, set them both on if they're not set
	; otherwise keep state
	lda VERA_DATA0
	and #$C0
	bne :+
	lda #$C0
:	sta psgtmp1

	txa
	and #$3F
	sec
	sbc psg_atten,y   ; apply attenuation

	bpl :+
	lda #$00          ; clamp at 0
:	ora psgtmp1       ; apply L+R channels
	sta VERA_DATA0    ; set VERA volume
	
	RESTORE_VERA
	RESTORE_BANK
	rts
.endproc


