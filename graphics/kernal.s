;---------------------------------------------------------------
; This file contains bridge functions for routines in the
; Kernal ROM bank used by the graphic and fonts library
;---------------------------------------------------------------

.export grjsrfar

.export FB_init
.export FB_get_info
.export FB_set_palette
.export FB_cursor_position
.export FB_cursor_next_line
.export FB_get_pixel
.export FB_get_pixels
.export FB_set_pixel
.export FB_set_pixels
.export FB_set_8_pixels
.export FB_set_8_pixels_opaque
.export FB_fill_pixels
.export FB_filter_pixels
.export FB_move_pixels

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

FB_init:
	jsr grjsrfar
    .word k_FB_init
    .byte BANK_KERNAL
    rts

FB_get_info:
	jsr grjsrfar
    .word k_FB_get_info
    .byte BANK_KERNAL
    rts

FB_set_palette:
	jsr grjsrfar
    .word k_FB_set_palette
    .byte BANK_KERNAL
    rts

FB_cursor_position:
	jsr grjsrfar
    .word k_FB_cursor_position
    .byte BANK_KERNAL
    rts

FB_cursor_next_line:
	jsr grjsrfar
    .word k_FB_cursor_next_line
    .byte BANK_KERNAL
    rts

FB_get_pixel:
	jsr grjsrfar
    .word k_FB_get_pixel
    .byte BANK_KERNAL
    rts

FB_get_pixels:
	jsr grjsrfar
    .word k_FB_get_pixels
    .byte BANK_KERNAL
    rts

FB_set_pixel:
	jsr grjsrfar
    .word k_FB_set_pixel
    .byte BANK_KERNAL
    rts

FB_set_pixels:
	jsr grjsrfar
    .word k_FB_set_pixels
    .byte BANK_KERNAL
    rts

FB_set_8_pixels:
	jsr grjsrfar
    .word k_FB_set_8_pixels
    .byte BANK_KERNAL
    rts

FB_set_8_pixels_opaque:
	jsr grjsrfar
    .word k_FB_set_8_pixels_opaque
    .byte BANK_KERNAL
    rts

FB_fill_pixels:
	jsr grjsrfar
    .word k_FB_fill_pixels
    .byte BANK_KERNAL
    rts

FB_filter_pixels:
	jsr grjsrfar
    .word k_FB_filter_pixels
    .byte BANK_KERNAL
    rts

FB_move_pixels:
	jsr grjsrfar
    .word k_FB_move_pixels
    .byte BANK_KERNAL
    rts

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