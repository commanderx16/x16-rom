; Code by Barry Yost (a.k.a. ZeroByte) and MooingLemur
; - 2022

; This file is for code dealing with the VERA PSG

.include "io.inc" ; for VERA symbols

.importzp azp0, azp0L, azp0H

.export psg_init
.export psg_playfreq
.export psg_setvol
.export psg_set_atten

.import psgtmp1
.import psg_atten
.import psg_volshadow
.import audio_prev_bank
.import audio_bank_refcnt

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
.scope
	lda ram_bank
	stz ram_bank
	beq skip_preserve
	sta audio_prev_bank
skip_preserve:
	inc audio_bank_refcnt
.endscope
.endmacro

.macro RESTORE_BANK
.scope
	dec audio_bank_refcnt
	bne skip_restore
	lda audio_prev_bank
	stz audio_prev_bank
	sta ram_bank
skip_restore:
.endscope
.endmacro


;---------------------------------------------------------------
; Re-initialize the VERA PSG to default state (everything off).
;---------------------------------------------------------------
; inputs: none
; affects: .A .X
; returns: none
;
.proc psg_init: near
	; explicit PRESERVE_AND_SET_BANK
	lda ram_bank
	stz ram_bank
	sta audio_prev_bank
	lda #1
	sta audio_bank_refcnt

	PRESERVE_VERA

	lda #0
	SET_VERA_PSG_POINTER

	; write zeroes into all 16 PSG voices for freq and volume
	; and set waveform to pulse, 50%
	ldx #16
	lda #$3F
loop1:
	stz VERA_DATA0
	stz VERA_DATA0
	stz VERA_DATA0
	sta VERA_DATA0
	dex
	bne loop1

	; zero out the shadow and attenuation state for all 16 channels
	ldx #16
loop2:
	stz psg_atten-1,x
	stz psg_volshadow-1,x
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
	pha
	PRESERVE_AND_SET_BANK
	pla
	sta psgtmp1
	
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
	sta psg_volshadow,x
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
; inputs: .X = voice
;         .A = volume
; affects: .Y
; preserves: none
;-----------------------------------------------------------------

.proc psg_setvol: near
	tay
	PRESERVE_AND_SET_BANK
	PRESERVE_VERA

	txa
	and #$0F
	tax
	SET_VERA_PSG_POINTER 0, 2 ; 0 stride, offset 2 (volume register)

	; Retrieve L/R, set them both on if they're not set
	; otherwise keep state
	lda VERA_DATA0
	and #$C0
	bne :+
	lda #$C0
:	sta psgtmp1

	tya
	and #$3F
	sta psg_volshadow,x
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
; psg_set_atten
;-----------------------------------------------------------------
; Set PSG voice attenuation (and reapply volume)
; 
; inputs: .X = voice
;         .A = volume
; affects: .Y
; preserves: none
;-----------------------------------------------------------------

.proc psg_set_atten: near
	tay
	PRESERVE_AND_SET_BANK

	txa
	and #$0F
	tax
	tya
	and #$7F

	sta psg_atten,x
	lda psg_volshadow,x
	jsr psg_setvol

	RESTORE_BANK
	rts
.endproc