;----------------------------------------------------------------------
; Commander X16 Machine Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "io.inc"

.export ioinit
.export iokeys
.export irq_ack
.export emulator_get_data
.export vera_wait_ready

.import ps2_init
.import serial_init
.import entropy_init
.import clklo

.segment "MACHINE"

;---------------------------------------------------------------
; IOINIT - Initialize I/O Devices
;
; Function:  Init all devices.
;            -- This is KERNAL API --
;---------------------------------------------------------------
ioinit:
	lda #%10000000
	sta VERA_CTRL        	; reset VERA
	jsr ym_init		; reset YM
	jsr vera_wait_ready
	jsr serial_init
	jsr entropy_init
	jsr clklo       ;release the clock line
	; fallthrough

;---------------------------------------------------------------
; Re-initialize the YM-2151 to default state (everything off).
;
;---------------------------------------------------------------
YM_ADDRESS = $9f40
YM_DATA = $9f41

ym_init:
	ldx #$e0
	ldy #$0f
@1:	jsr @ym_write	; disable all lfos $e0..$ff
	inx
	bne @1
	ldx #$08
	ldy #7
@2:	jsr @ym_write	; set key off for all voices
	dey
	bpl @2
	ldx #$01
	ldy #$02
	jsr @ym_write	; reset lfo
	ldx #$19
	ldy #$80
	jsr @ym_write	; clear pmd
	ldx #$0f
	ldy #0
@3:	jsr @ym_write	; clear everything else $0f..$ff
	inx
	bne @3
	ldx #$01
	ldy #$00
	jsr @ym_write	; re-enable lfo
	rts

@ym_write:  ; .X=reg, .Y=value
	bit YM_DATA	; ready for write?
	bmi @ym_write
	stx YM_ADDRESS
	nop
	nop
	nop
	nop
	nop
	sty YM_DATA
	rts
  
;---------------------------------------------------------------
; Set up VBLANK IRQ
;
;---------------------------------------------------------------
iokeys:
	lda #1
	sta VERA_IEN    ;VERA VBLANK IRQ for 60 Hz
	rts

;---------------------------------------------------------------
; ACK VBLANK IRQ
;
;---------------------------------------------------------------
irq_ack:
	lda #1
	sta VERA_ISR    ;ACK VERA VBLANK
	rts

;---------------------------------------------------------------
; Get some data from the emulator
;
; Function:  Detect an emulator and get config information.
;            For now, this is the keyboard layout.
;---------------------------------------------------------------
emulator_get_data:
	lda $9fbe       ;emulator detection
	cmp #'1'
	bne @1
	lda $9fbf
	cmp #'6'
	bne @1
	lda $9fbd       ;emulator keyboard layout
	bra @2
@1:	lda #0          ;fall back to US layout
@2:	rts


;---------------------------------------------------------------
; Wait for VERA to be ready
;
; VERA's FPGA needs some time to configure itself. This function
; will see if the configuration is done by writing a VERA
; register and checking if the value is correctly written.
;---------------------------------------------------------------
vera_wait_ready:
	lda #42
	sta VERA_ADDR_L
	lda VERA_ADDR_L
	cmp #42
	bne vera_wait_ready
	rts
