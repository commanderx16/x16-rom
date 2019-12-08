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

.global _GetScanLine

.segment "graph2n"

.import _DMult
.import g_col1

.setcpu "65c02"

; The GetScanLine API is no longer supported. On C64
; GEOS, callers of this function could safely assume the
; VIC-II bitmap layout and that the bitmap is actually
; stored in CPU memory on the current bank. Neither of
; this is the case on a system with a VERA. deskTop 2.0
; for example would trash CPU memory if this returned
; real offsets into video RAM. Therefore, to all existing
; GEOS apps, we return a fake address that cannot cause
; any harm.
_GetScanLine:
	LoadW r5, $ff00
	LoadW r6, $ff00
	rts

.include "../../banks.inc"
.import gjsrfar
.import GRAPH_draw_line
.import GRAPH_draw_frame
.import GRAPH_draw_rect
.import GRAPH_LL_get_pixel
.import GRAPH_LL_cursor_position
.import GRAPH_LL_set_pixel
.import GRAPH_LL_filter_pixels
.import GRAPH_set_colors

.export _DrawLine, _DrawPoint, _FrameRectangle, _ImprintRectangle, _InvertRectangle, _RecoverRectangle, _Rectangle, _TestPoint, _HorizontalLine, _InvertLine, _RecoverLine, _VerticalLine, _GRAPH_start_direct, _GRAPH_set_pixel

.macro jsrfar addr
	jsr gjsrfar
	.word addr
	.byte BANK_KERNAL
.endmacro

;---------------------------------------------------------------
; DrawLine                                                $C130
;
; Pass:      signFlg  set to recover from back screen
;                     reset for drawing
;            carryFlg set for drawing in forground color
;                     reset for background color
;            r3       x pos of 1st point (0-319)
;            r11L     y pos of 1st point (0-199)
;            r4       x pos of 2nd point (0-319)
;            r11H     y pos of 2nd point (0-199)
; Return:    -
; Destroyed: a, x, y, r4 - r8, r11
;---------------------------------------------------------------
_DrawLine:
	php
	plx

	PushW r0
	PushW r1
	PushW r2
	PushW r3
	MoveW r3, r0
	MoveB r11L, r1L
	stz r1H
	MoveB r11H, r3L
	stz r3H
	MoveW r4, r2

	phx
	plp
	bmi @3 ; recover
; draw
	lda #0
	rol
	eor #1
	php
	sei
	jsrfar GRAPH_set_colors
	plp
	
	lda #0
	bra @2 ; N=0 -> draw
@3:	sec ; N=1, C=1 -> recover
@2:
	php
	sei
	jsrfar GRAPH_draw_line
	plp

	PopW r3
	PopW r2
	PopW r1
	PopW r0
	rts


;---------------------------------------------------------------
; DrawPoint                                               $C133
;
; Pass:      r3       x pos of point (0-319)
;            r11L     y pos of point (0-199)
;            carryFlg color: 1: black; 0: white
;            signFlg  0: draw color; 1: recover
; Return:    -
; Destroyed: a, x, y, r5 - r6
;---------------------------------------------------------------
_DrawPoint:
	bmi @3 ; recover
; draw
	lda #0
	rol
	eor #1

	pha
	PushW r0
	PushW r1
	MoveW r3, r0
	MoveB r11L, r1L
	jsr _GRAPH_start_direct
	PopW r1
	PopW r0
	pla

	jmp _GRAPH_set_pixel

; recover a point: use DrawLine
@3:	PushW r4
	PushB r11H
	MoveW r3, r4
	MoveB r11L, r11H
	jsr _DrawLine
	PopB r11H
	PopW r4
	rts

;---------------------------------------------------------------
; FrameRectangle                                          $C127
;
; Pass:      a   pattern byte
;            r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    r2L, r3H unchanged
; Destroyed: a, x, y, r5 - r9, r11
;---------------------------------------------------------------
_FrameRectangle:
	jsr Convert8BitPattern
	PushW r0
	PushW r1
	PushW r2
	PushW r3
	MoveW r3, r0
	MoveB r2L, r1L
	stz r1H
	MoveB r2H, r3L
	stz r3H
	MoveW r4, r2
	php
	sei
	jsrfar GRAPH_draw_frame
	plp
	PopW r3
	PopW r2
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; ImprintRectangle                                        $C250
;
; Pass:      r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    r2L, r3H unchanged
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_ImprintRectangle:
	PushW r0
	PushW r1
	PushW r2
	PushW r3
	MoveW r3, r0
	MoveB r2L, r1L
	stz r1H
	MoveB r2H, r3L
	stz r3H
	MoveW r4, r2
	php
	sei
	lda #$ff
	clc
	jsrfar GRAPH_draw_rect
	plp
	PopW r3
	PopW r2
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; InvertRectangle                                         $C12A
;
; Pass:      r2L top in scanlines (0-199)
;            r2H bottom in scanlines (0-199)
;            r3  left in pixels (0-319)
;            r4  right in pixels (0-319)
; Return:    r2L, r3H unchanged
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
_InvertRectangle:
	MoveB r2L, r11L
@1:	jsr _InvertLine
	lda r11L
	inc r11L
	cmp r2H
	bne @1
	rts

;---------------------------------------------------------------
; RecoverRectangle                                        $C12D
;
; Pass:      r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    rectangle recovered from backscreen
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_RecoverRectangle:
	PushW r0
	PushW r1
	PushW r2
	PushW r3
	MoveW r3, r0
	MoveB r2L, r1L
	stz r1H
	MoveB r2H, r3L
	stz r3H
	MoveW r4, r2
	php
	sei
	lda #$ff
	sec
	jsrfar GRAPH_draw_rect
	plp
	PopW r3
	PopW r2
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; Rectangle                                               $C124
;
; Pass:      r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    draws the rectangle
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_Rectangle:
	lda g_col1
	php
	sei
	jsrfar GRAPH_set_colors
	plp

	PushW r0
	PushW r1
	PushW r2
	PushW r3
	MoveW r3, r0
	MoveB r2L, r1L
	stz r1H
	MoveB r2H, r3L
	stz r3H
	MoveW r4, r2
	php
	sei
	lda #0 ; N=0 -> draw
	jsrfar GRAPH_draw_rect
	plp
	PopW r3
	PopW r2
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; TestPoint                                               $C13F
;
; Pass:      r3   x position of pixel (0-319)
;            r11L y position of pixel (0-199)
; Return:    carry set if bit is set
; Destroyed: a, x, y, r5, r6
;---------------------------------------------------------------
_TestPoint:
	PushW r0
	PushW r1
	MoveW r3, r0
	MoveB r11L, r1L
	stz r1H
	php
	sei
	jsr gjsrfar
	.word GRAPH_LL_get_pixel
	.byte BANK_KERNAL
	plp
	tax
	PopW r1
	PopW r0
	cpx #0  ; black
	beq @1
	cpx #16 ; also black
	beq @1
	clc
	rts
@1:	sec
	rts

;---------------------------------------------------------------
; HorizontalLine                                          $C118
;
; Pass:      a    pattern byte
;            r3   x in pixel of left end (0-319)
;            r4   x in pixel of right end (0-319)
;            r11L y position in scanlines (0-199)
; Return:    r11L unchanged
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_HorizontalLine:
	jsr Convert8BitPattern
	PushW r0
	PushW r1
	PushW r2
	PushW r3
	MoveW r3, r0
	MoveB r11L, r1L
	stz r1H
	MoveW r4, r2
	MoveB r11L, r3L
	stz r3H

	php
	sei
	lda #0 ; N=0 -> draw
	jsrfar GRAPH_draw_line
	plp

	PopW r3
	PopW r2
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; InvertLine                                              $C11B
;
; Pass:      r3   x pos of left endpoint (0-319)
;            r4   x pos of right endpoint (0-319)
;            r11L y pos (0-199)
; Return:    r3-r4 unchanged
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
_InvertLine:
	PushW r0
	PushW r1
	MoveW r3, r0
	MoveB r11L, r1L
	stz r1H
	jsr _GRAPH_start_direct
	MoveW r4, r0
	SubW r3, r0
	IncW r0

	PushW r12
	PushB r13L
	LoadW r1, r12L  ; pointer to code
	LoadB r12L, $49 ; EOR #
	LoadB r12H, $01 ;      1
	LoadB r13L, $60 ; RTS

	php
	sei
	jsrfar GRAPH_LL_filter_pixels
	plp
		
	PopB r12L
	PopW r13
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; RecoverLine                                             $C11E
;
; Pass:      r3   x pos of left endpoint (0-319)
;            r4   x pos of right endpoint (0-319)
;            r11L y pos of line (0-199)
; Return:    copies bits of line from background to
;            foreground sceen
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
_RecoverLine:
	PushW r0
	PushW r1
	PushW r2
	PushW r3
	MoveW r3, r0
	MoveB r11L, r1L
	stz r1H
	MoveW r4, r2
	MoveB r11L, r3L
	stz r3H

	php
	sei
	lda #$ff
	sec      ; N=1, C=1 -> recover
	jsrfar GRAPH_draw_line
	plp

	PopW r3
	PopW r2
	PopW r1
	PopW r0
	rts

;---------------------------------------------------------------
; VerticalLine                                            $C121
;
; Pass:      a pattern byte
;            r3L top of line (0-199)
;            r3H bottom of line (0-199)
;            r4  x position of line (0-319)
; Return:    draw the line
; Destroyed: a, x, y, r4 - r8, r11
;---------------------------------------------------------------
_VerticalLine:
	jsr Convert8BitPattern
	PushW r0
	PushW r1
	PushW r2
	PushW r3
	MoveW r4, r0
	MoveB r3L, r1L
	stz r1H
	MoveW r4, r2
	MoveB r3H, r3L
	stz r3H

	php
	sei
	lda #0 ; N=0 -> draw
	jsrfar GRAPH_draw_line
	plp

	PopW r3
	PopW r2
	PopW r1
	PopW r0
	rts

_GRAPH_start_direct:
	php
	sei
	jsrfar GRAPH_LL_cursor_position
	plp
	rts

_GRAPH_set_pixel:
	php
	sei
	jsrfar GRAPH_LL_set_pixel
	plp
	rts

;---------------------------------------------------------------
; Color compatibility logic
;---------------------------------------------------------------

; in compat mode, this converts 8 bit patterns into shades of gray
Convert8BitPattern:
	ldx #8
	ldy #8
@1:	lsr
	bcc @2
	dey
@2:	dex
	bne @1
	cpy #8
	beq @3
	tya
	asl
	ora #16
	bra @4
@3:	lda #16+15
@4:	php
	sei
	jsrfar GRAPH_set_colors
	plp
	rts
