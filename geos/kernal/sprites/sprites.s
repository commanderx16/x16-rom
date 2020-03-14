; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; C64/VIC-II sprite driver

.include "config.inc"
.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "gkernal.inc"
.include "c64.inc"

.import scr_mobx

.import NormalizeX

; syscalls
.global _DisablSprite
.global _DrawSprite
.global _EnablSprite
.global _PosSprite

.segment "sprites"

;---------------------------------------------------------------
; DisablSprite                                            $C1D5
;
; Pass:      r3L sprite nbr (0-7)
; Return:    VIC register set to disable
;            sprite.
; Destroyed: a, x
;---------------------------------------------------------------
_DisablSprite:
;---------------------------------------------------------------
; DrawSprite                                              $C1C6
;
; Pass:      r3L sprite nbr (2-7)
;            r4  ptr to picture data
; Return:    graphic data transfer to VIC chip
; Destroyed: a, y, r5
;---------------------------------------------------------------
_DrawSprite:
;---------------------------------------------------------------
; EnablSprite                                             $C1D2
;
; Pass:      r3L sprite nbr (0-7)
; Return:    sprite activated
; Destroyed: a, x
;---------------------------------------------------------------
_EnablSprite:
	rts

;---------------------------------------------------------------
; PosSprite                                               $C1CF
;
; Pass:      r3L sprite nbr (0-7)
;            r4  x pos (0-319)
;            r5L y pos (0-199)
; Return:    r3L unchanged
; Destroyed: a, x, y, r6
;---------------------------------------------------------------
_PosSprite:
	lda #<(VERA_SPRITES_BASE + 2)
	sta VERA_ADDR_L
	lda #>(VERA_SPRITES_BASE + 2)
	sta VERA_ADDR_M
	lda #((^(VERA_SPRITES_BASE + 2)) | $10)
	sta VERA_ADDR_H
	lda r4L
	sta VERA_DATA0
	lda r4H
	sta VERA_DATA0
	lda r5L
	sta VERA_DATA0
	lda #0
	sta VERA_DATA0
	lda #3 << 2 ; z-depth
	sta VERA_DATA0
	rts
