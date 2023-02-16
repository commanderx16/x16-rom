; Code by Barry Yost (a.k.a. ZeroByte) and MooingLemur
; - 2022

; This file is for code dealing with the VERA PSG

.include "io.inc" ; for VERA symbols

.importzp azp0, azp0L, azp0H

.export psg_init
.export psg_playfreq
.export psg_setvol
.export psg_setatten
.export psg_getatten
.export psg_setfreq
.export psg_write
.export psg_setpan
.export psg_getpan
.export psg_read
.export psg_write_fast

.import psgtmp1
.import psg_atten
.import psg_volshadow
.import audio_prev_bank
.import audio_bank_refcnt

.import playstring_len
.import playstring_defnotelen
.import playstring_octave
.import playstring_pos
.import playstring_tempo
.import playstring_voice
.import playstring_art
.import playstring_delayrem

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

.macro SET_VERA_PSG_POINTER_REG stride, offset
	stz VERA_CTRL
.ifnblank offset
	clc
	adc #<(VERA_PSG_BASE + offset)
.else
	ora #<(VERA_PSG_BASE)
.endif
	sta VERA_ADDR_L
	lda #>VERA_PSG_BASE
	sta VERA_ADDR_M
	SET_VERA_STRIDE stride
.endmacro

.macro SET_VERA_PSG_POINTER_VOICE stride, offset
	; "input": voice number is in .A

	; point data0 at PSG registers
	and #$0F
	asl
	asl
	SET_VERA_PSG_POINTER_REG stride, offset
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
; affects: .A .X .Y
; returns: none
;
.proc psg_init: near
	; Make re-entrant safe by protecting bank variables from interrupt
	php
	sei

	; explicit PRESERVE_AND_SET_BANK
	lda ram_bank
	stz ram_bank
	sta audio_prev_bank
	lda #1
	sta audio_bank_refcnt

	stz playstring_len
	stz playstring_pos
	stz playstring_voice
	stz playstring_delayrem
	lda #120
	sta playstring_tempo
	lda #60
	sta playstring_defnotelen
	lda #4
	sta playstring_octave
	lda #1
	sta playstring_art

	plp ; restore interrupt flag

	PRESERVE_VERA

	lda #0
	SET_VERA_PSG_POINTER_VOICE

	; write zeroes into all 16 PSG voices for freq and volume
	; and set waveform to pulse, 50%
	ldx #16
	ldy #$C0
	lda #$3F
loop1:
	stz VERA_DATA0
	stz VERA_DATA0
	sty VERA_DATA0
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
	; Make re-entrant safe by protecting tmp variables from interrupt
	php
	sei

	and #$0F
	pha
	PRESERVE_AND_SET_BANK
	pla

	sta psgtmp1

	PRESERVE_VERA

	lda psgtmp1
	SET_VERA_PSG_POINTER_VOICE

	; Set frequency
	stx VERA_DATA0
	sty VERA_DATA0

	; Retrieve the voice
	ldx psgtmp1

	; Retrieve L/R, keep state
	SET_VERA_STRIDE 0

	lda VERA_DATA0
	and #$C0
	sta psgtmp1

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

	plp ; restore interrupt flag
	rts
.endproc

;-----------------------------------------------------------------
; psg_setfreq
;-----------------------------------------------------------------
; Set the PSG frequency
; inputs: .A    = voice
;         .X .Y = 16-bit PSG frequency
;-----------------------------------------------------------------

.proc psg_setfreq: near
	and #$0F
	pha
	PRESERVE_AND_SET_BANK
	pla

	; Make re-entrant safe by protecting tmp variables from interrupt
	php
	sei

	sta psgtmp1

	PRESERVE_VERA

	lda psgtmp1

	plp ; restore interrupt flag

	SET_VERA_PSG_POINTER_VOICE

	; Set frequency
	stx VERA_DATA0
	sty VERA_DATA0

	RESTORE_VERA
	RESTORE_BANK
	rts
.endproc


.macro PSG_WRITE_BODY
.scope
	; Writing something besides volume?
	; skip to the write
	txa
	and #$03
	cmp #$02
	bne write

	PRESERVE_AND_SET_BANK

	; We are writing volume
	; Preserve the L+R bits from the incoming write
	tya
	and #$C0

	; Make re-entrant safe by protecting tmp variables from interrupt
	php
	sei

	sta psgtmp1

	; Shadow the raw value
	tya
	and #$3F
	sta psg_volshadow,y

	; Apply attenuation
	sec
	sbc psg_atten,y
	bpl :+
	lda #$00
:	ora psgtmp1

	plp ; restore interrupt flag

	tay

	RESTORE_BANK
write:
	sty VERA_DATA0
.endscope
.endmacro

;-----------------------------------------------------------------
; psg_write
;-----------------------------------------------------------------
; Do a PSG register write, while cooking volume
; inputs: .A = value, .X = PSG register ($00-$3F)
; affects: .Y
; preserves: .A .X
;-----------------------------------------------------------------

.proc psg_write: near
	pha
	phx

	tay
	PRESERVE_VERA

	txa
	SET_VERA_PSG_POINTER_REG

	PSG_WRITE_BODY

	RESTORE_VERA
	plx
	pla
	rts
.endproc

;-----------------------------------------------------------------
; psg_write_fast
;-----------------------------------------------------------------
; Do a PSG register write, while cooking volume
; Skips preservation of VERA registers, and only repoints
; VERA_ADDR_L.
;
; This routine is 70 clock cycles faster per invocation
; but requires the caller to set up VERA_ADDR_M and VERA_ADDR_H
; to point to $1F9xx.  It is highly recommended to set an
; auto-increment of 0, so that writing to register $3F
; (VERA_ADDR_L = $FF) does not increment VERA_ADDR_M
;
; e.g.
;     stz VERA_CTRL
;     lda #$01
;     sta VERA_ADDR_H
;     lda #$F9
;     sta VERA_ADDR_M
;
; inputs: .A = value, .X = PSG register ($00-$3F)
; affects: .Y
; preserves: .A .X
;-----------------------------------------------------------------

.proc psg_write_fast: near
	pha
	phx

	tay
	txa
	ora #<(VERA_PSG_BASE)
	sta VERA_ADDR_L

	PSG_WRITE_BODY

	plx
	pla
	rts
.endproc


;-----------------------------------------------------------------
; psg_setvol
;-----------------------------------------------------------------
; Set PSG voice volume w/ attenuation
;
; inputs: .A = voice
;         .X = volume
; affects: .Y
; preserves: none
;-----------------------------------------------------------------

.proc psg_setvol: near
	and #$0F
	tay
	PRESERVE_AND_SET_BANK
	PRESERVE_VERA

	tya
	SET_VERA_PSG_POINTER_VOICE 0, 2 ; 0 stride, offset 2 (volume register)

	; Retrieve L/R, keep state
	lda VERA_DATA0
	and #$C0

	; Make re-entrant safe by protecting tmp variables from interrupt
	php
	sei

	sta psgtmp1

	txa
	and #$3F
	sta psg_volshadow,y
	sec
	sbc psg_atten,y   ; apply attenuation

	bpl :+
	lda #$00          ; clamp at 0
:	ora psgtmp1       ; apply L+R channels

	plp ; restore interrupt flag

	sta VERA_DATA0    ; set VERA volume

	RESTORE_VERA
	RESTORE_BANK
	rts
.endproc


;-----------------------------------------------------------------
; psg_setatten
;-----------------------------------------------------------------
; Set PSG voice attenuation (and reapply volume)
;
; inputs: .A = voice
;         .X = attenuation
; affects: .Y
; preserves: none
;-----------------------------------------------------------------

.proc psg_setatten: near
	and #$0F
	tay
	PRESERVE_AND_SET_BANK

	txa
	and #$7F
	tax

	sta psg_atten,y
	lda psg_volshadow,y
	tax
	tya
	jsr psg_setvol

	RESTORE_BANK
	rts
.endproc

;-----------------------------------------------------------------
; Retreive current PSG attenuation setting
;-----------------------------------------------------------------
; inputs: .A = voice
; affects: .Y
; preserves: .A
; returns: .X = attenuation setting
;
.proc psg_getatten: near
	pha      ; preerve .A
	and #$0F ; mask to channel range 0-15
	tax

	PRESERVE_AND_SET_BANK
	lda psg_atten,x
	RESTORE_BANK

	tax
	pla
	rts
.endproc

;-----------------------------------------------------------------
; psg_setpan
;-----------------------------------------------------------------
; Set PSG voice panning
;
; inputs: .A = voice
;         .X = pan (0=off, 1=left, 2=right, 3=both)
; affects: .Y
; preserves: none
;-----------------------------------------------------------------

.proc psg_setpan: near
	and #$0F
	tay
	PRESERVE_AND_SET_BANK
	PRESERVE_VERA

	tya
	SET_VERA_PSG_POINTER_VOICE 0, 2 ; 0 stride, offset 2 (volume register)

	txa
	ror
	ror
	ror
	and #$C0

	; Make re-entrant safe by protecting tmp variables from interrupt
	php
	sei

	sta psgtmp1

	; Retrieve volume, clear L+R bits
	lda VERA_DATA0
	and #$3F
	ora psgtmp1
	sta VERA_DATA0

	plp ; restore interrupt flag

	RESTORE_VERA
	RESTORE_BANK
	clc
	rts
.endproc

;-----------------------------------------------------------------
; Retreive current PSG pan setting
;-----------------------------------------------------------------
; inputs: .A = voice
; affects: .Y
; preserves: .A
; returns: .X = pan value
;
.proc psg_getpan: near
	pha
	and #$0F ; mask to voice range 0..15
	asl
	asl
	inc
	inc
	tax
	jsr psg_read
	rol
	rol
	rol
	and #$03
	tax
	pla
	rts
.endproc

;-----------------------------------------------------------------
; psg_read
;-----------------------------------------------------------------
; Do a PSG register read
; inputs: .X = PSG register ($00-$3F)
;       : .C set   = retrieve volumes with attenuation applied (cooked)
;       :    clear = retrieve raw values (as received by psg_write, et al)
; affects: .A .Y
; preserves: .X
; returns : .A = retrieve value
;-----------------------------------------------------------------

.proc psg_read: near
	phx
	php ; preserve carry flag

	PRESERVE_AND_SET_BANK
	PRESERVE_VERA

	txa
	SET_VERA_PSG_POINTER_REG 0

	; Reading something besides volume?
	; skip to the read
	txa
	and #$03
	cmp #$02
	bne plp_read

	; cooked value comes right from the VERA
	plp
	bcs read

	; get the voice number
	txa
	lsr
	lsr
	tax

	; raw value is composed of L+R bits, plus the volume shadow
	lda psg_volshadow,x

	; make re-entrant safe by protecting tmp vars from interrupt
	php
	sei

	sta psgtmp1 ; should already be $00-$3F
	lda VERA_DATA0
	and #$C0
	ora psgtmp1

	plp ; restore interrupt flag

	tay

	bra done
plp_read:
	plp ; pushed earlier, we didn't need it
read:
	ldy VERA_DATA0
done:
	RESTORE_VERA
	RESTORE_BANK
	tya
	plx
	rts
.endproc
