;----------------------------------------------------------------------
; Commander X16 Machine Driver
;----------------------------------------------------------------------

.include "../../io.inc"

.export ioinit
.export iokeys
.export irq_ack

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
; Function:  (This is KERNAL API.)
;---------------------------------------------------------------
iokeys:
	lda #1
	sta veraien     ;VERA VBLANK IRQ for 60 Hz
	rts
	
irq_ack:
	lda #1
	sta veraisr     ;ACK VERA VBLANK
	rts
