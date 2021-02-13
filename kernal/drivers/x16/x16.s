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

.import mouse_init
.import ps2_init
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
	jsr vera_wait_ready
	jsr ps2_init    ;inhibit ps/2 communcation
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
