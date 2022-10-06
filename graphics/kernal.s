;---------------------------------------------------------------
; This file contains bridge functions for routines in the
; Kernal ROM bank used by the graphic and fonts library
;---------------------------------------------------------------

.export grjsrfar

.import k_kbdbuf_get                ;Set during link stage from Kernal.sym
.import k_sprite_set_position       ;Set during link stage from Kernal.sym
.import k_sprite_set_image          ;Set during link stage from Kernal.sym

.export kbdbuf_get
.export sprite_set_position
.export sprite_set_image
.export bsout

.include "banks.inc"
.include "kernal_vectors.inc"

.segment "GRAPH"

kbdbuf_get:
	jsr grjsrfar	
	.word k_kbdbuf_get
	.byte BANK_KERNAL
	rts

sprite_set_image:
	jsr grjsrfar	
	.word k_sprite_set_image
	.byte BANK_KERNAL
	rts

sprite_set_position:
 	jsr grjsrfar	
	.word k_sprite_set_position
	.byte BANK_KERNAL
	rts

bsout:
 	jsr grjsrfar	
	.word k_bsout
	.byte BANK_KERNAL
	rts

ram_bank = $00
rom_bank = $01

grjsrfar: .include "jsrfar.inc"