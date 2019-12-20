
.include "../../io.inc"

.export ioinit
.export iokeys

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

;---------------------------------------------------------------
; Set up VBLANK IRQ
;
; Function:  (This is KERNAL API.)
;---------------------------------------------------------------
iokeys:
	lda #1
	sta veraien     ;VERA VBLANK IRQ for 60 Hz
	jmp clklo       ;release the clock line***901227-03***


