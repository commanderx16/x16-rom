; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Console I/O: PromptOn, PromptOff, InitTextPrompt syscalls

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"

.include "io.inc"

.import _DisablSprite
.import _EnablSprite
.import _PosSprite
.ifdef bsw128
; XXX back bank, yet var lives on front bank!
L881A = $881A
.endif

.global _PromptOn
.global _PromptOff
.global _InitTextPrompt

.segment "conio5"

.ifdef bsw128
_PromptOn:
	ldx #$80
	lda alphaFlag
	ora #%01000000
	bne PrmptOff1
_PromptOff:
	ldx #$40
	lda alphaFlag
	and #%10111111
PrmptOff1:
	stx L881A
	and #%11000000
	ora #%00111100
	sta alphaFlag
	rts
.else
_PromptOn:
	lda #%01000000
	ora alphaFlag
	sta alphaFlag
	LoadB r3L, 1
	MoveW stringX, r4
	MoveB stringY, r5L
	jsr _PosSprite
	jsr _EnablSprite
	bra PrmptOff1
_PromptOff:
	lda #%10111111
	and alphaFlag
	sta alphaFlag
	LoadB r3L, 1
	jsr _DisablSprite
PrmptOff1:
	lda alphaFlag
	and #%11000000
	ora #%00111100
	sta alphaFlag
	rts
.endif

_InitTextPrompt:
	tay ; height

	LoadB alphaFlag, %10000011

	; init sprite #1
	lda #1 * 8
	sta VERA_ADDR_L
	lda #>VERA_SPRITES_BASE
	sta VERA_ADDR_M
	lda #((^VERA_SPRITES_BASE) | $10)
	sta VERA_ADDR_H
	lda #<((sprite_addr + $1000) >> 5)
	sta VERA_DATA0
	lda #1 << 7 | >((sprite_addr + $1000) >> 5) ; 8 bpp
	sta VERA_DATA0

	; set size
	lda #1 * 8 + 7
	sta VERA_ADDR_L
	lda #3 << 6 | 0 << 4 ;  8x64 px
	sta VERA_DATA0

	; create sprite image
	lda #>(sprite_addr + $1000)
	sta VERA_ADDR_M
	lda #<(sprite_addr + $1000)
	sta VERA_ADDR_L
	lda #$10 | (sprite_addr >> 16)
	sta VERA_ADDR_H
	tya
	pha
	lda #6 ; blue
@1:	sta VERA_DATA0
	ldx #7
@2:	stz VERA_DATA0 ; translucent
	dex
	bne @2
	dey
	bne @1
	ply
@3:	ldx #8
@4:	stz VERA_DATA0 ; translucent
	dex
	bne @4
	iny
	cpy #64
	bne @3

	rts

