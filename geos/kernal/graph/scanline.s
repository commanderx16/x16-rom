; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: GetScanLine syscall

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.global _GetScanLine, _GetScanLineCompat

.segment "graph2n"

.import _DMult

.setcpu "65c02"

; This is a fake version of the KERNAL call GetScanLine
; referenced by the jump table. On C64 GEOS, callers of
; the function could safely assume the VIC-II bitmap
; layout and that the bitmap is actually stored in CPU
; memory on the current bank. Neither of this is the
; case on a system with a VERA. deskTop 2.0 for example
; would trash CPU memory if this returned real offsets
; into video RAM. Therefore, to all users in compatMode,
; we return a fake address that cannot cause any harm.
_GetScanLineCompat:
	bit compatMode
	bpl _GetScanLine
	LoadW r5, $ff00
	LoadW r6, $ff00
	rts

;---------------------------------------------------------------
; GetScanLine                                             $C13C
;
; Function:  Returns the address of the beginning of a scanline

; Pass:      x   scanline nbr
; Return:    r5  add of 1st byte of foreground scr
;            r6  add of 1st byte of background scr
; Destroyed: a
;---------------------------------------------------------------
_GetScanLine:
	; r5 = x * 320
	stz r5H
	txa
	asl
	rol r5H
	asl
	rol r5H
	asl
	rol r5H
	asl
	rol r5H
	asl
	rol r5H
	asl
	rol r5H
	sta r5L
	txa
	clc
	adc r5H
	sta r5H

; For BG storage, we have to work with 8 KB banks.
; Lines are 320 bytes, and 8 KB is not divisible by 320,
; so the base address of certain lines would be so close
; to the top of a bank that lda (r6),y shoots over the
; end. Therefore, we need to add memory gaps at certain
; lines to jump over the bank boundaries.
	cpx #25
	bcc @1
	inx
	cpx #51
	bcc @1
	inx
	cpx #76
	bcc @1
	inx
	cpx #102
	bcc @1
	inx
	cpx #128
	bcc @1
	inx
	cpx #153
	bcc @1
	inx
	cpx #179
	bcc @1
	inx
	cpx #204
	bcc @1
	inx
@1:
	stz r6H
	txa
	asl
	rol r6H
	asl
	rol r6H
	asl
	rol r6H
	asl
	rol r6H
	asl
	rol r6H
	asl
	rol r6H
	sta r6L
	txa
	clc
	adc r6H
	sta r6H

	lda r6H
	pha
	and #$1f
	ora #$a0
	sta r6H
	pla
	ror ; insert the carry from addition above, since the BG
	    ; data exceeds 64 KB because of the added gaps
	lsr
	lsr
	lsr
	lsr
	sta d1pra ; RAM bank
	rts

.global inc_bgpage

inc_bgpage:
	pha
	inc r6H
	lda r6H
	cmp #$c0
	beq @1
	pla
	rts
@1:	inc d1pra ; RAM bank
	lda #$a0
	sta r6H
	pla
	rts

.segment "graph2o"
