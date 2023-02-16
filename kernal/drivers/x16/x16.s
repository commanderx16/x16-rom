;----------------------------------------------------------------------
; Commander X16 Machine Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "io.inc"

; for initializing the audio subsystems
.include "banks.inc"
.include "audio.inc"

.export ioinit
.export iokeys
.export irq_ack
.export emulator_get_data
.export vera_wait_ready
.export call_audio_init
.export boot_cartridge

.import ps2_init
.import serial_init
.import entropy_init
.import clklo
.import jsrfar
.import fetvec
.import fetch
.importzp tmp2

.segment "MACHINE"

;---------------------------------------------------------------
; IOINIT - Initialize I/O Devices
;
; Function:  Init all devices.
;            -- This is KERNAL API --
;---------------------------------------------------------------
ioinit:
	jsr vera_wait_ready
	jsr serial_init
	jsr entropy_init
	jsr clklo       ;release the clock line
	; fallthrough

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


;---------------------------------------------------------------
; Call the Audio API's init routine
;
; This sets the state of the YM2151 and the API's shadow of
; it to known values, effectively stopping any note playback,
; then loads default instrument presets into all 8 YM2151 channels.
; It also turns off any notes that are currently playing on the 
; VERA PSG by writing default values to all 64 PSG registers.
;---------------------------------------------------------------
call_audio_init:
	jsr jsrfar
	.word audio_init
	.byte BANK_AUDIO

	rts

;---------------------------------------------------------------
; Check for cartridge in ROM bank 32
;
; This routine checks bank 32 for the PETSCII sequence
; 'C', 'X', '1', '6' at address $C000
; if it exists, it jumps to the cartridge entry point at $C004.
;---------------------------------------------------------------
boot_cartridge:
	lda #tmp2
	sta fetvec
	stz tmp2
	lda #$C0
	sta tmp2+1

	ldy #3
@chkloop:
	ldx #32
	jsr fetch
	cmp @signature,y
	bne @no
	dey
	bpl @chkloop
	
	jsr jsrfar
	.word $C004
	.byte 32 ; cartridge ROM
@no:
	; If cart does not exist, we continue to BASIC.
	; The cartridge can also return to BASIC if it chooses to do so.
	rts
@signature:
	.byte "CX16"
