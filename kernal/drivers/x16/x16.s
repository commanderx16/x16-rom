;----------------------------------------------------------------------
; Commander X16 Machine Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "../../io.inc"

.export ioinit
.export iokeys
.export irq_ack
.export emulator_get_data

.import mouse_init
.import ps2_init
.import clklo

.segment "MACHINE"

;---------------------------------------------------------------
; IOINIT - Initialize I/O Devices
;
; Function:  Init all devices.
;            -- This is KERNAL API --
;---------------------------------------------------------------
ioinit:
	jsr ps2_init    ;inhibit ps/2 communcation
	jsr clklo       ;release the clock line***901227-03***

;---------------------------------------------------------------
; Set up VBLANK IRQ
;
;---------------------------------------------------------------
iokeys:
	lda #1
	sta veraien     ;VERA VBLANK IRQ for 60 Hz
	rts
	
irq_ack:
	lda #1
	sta veraisr     ;ACK VERA VBLANK
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
