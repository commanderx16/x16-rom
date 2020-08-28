; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; C64/C128 keyboard driver

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "c64.inc"
.include "banks.inc"

.global _DoKeyboardScan

.import KbdScanHelp2

.segment "keyboard1"

_DoKeyboardScan:
	.import gjsrfar
	jsr gjsrfar
	.word $FF9F ; kbd_scan
	.byte BANK_KERNAL

	jsr gjsrfar
	.word $FFE4 ; getin
	.byte BANK_KERNAL

	cmp #0
	bne :+
	rts

:	cmp #20; PETSCII delete
	bne :+
	lda #8 ; ASCII backspace

:	jmp KbdScanHelp2
