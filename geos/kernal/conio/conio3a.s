; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Console I/O: PutString syscall

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "c64.inc"
.include "banks.inc"
.include "kernal.inc"

.import _PutChar
.global _PutString

.setcpu "65c02"

.segment "conio3a"

_PutString:
	ldy #0
	lda (r0),y
	beq @2
	jsr _PutChar
	inc r0L
	bne @1
	inc r0H
@1:	bra _PutString
@2:	rts

;-------

.include "../../../graphics/fonts/font_internal.inc"

.macro get_font_parameters
	pha
	MoveW k_curIndexTable, g_curIndexTable
	MoveB k_baselineOffset, g_baselineOffset
	MoveW k_curSetWidth, g_curSetWidth
	MoveB k_curHeight, g_curHeight
	MoveW k_cardDataPntr, g_cardDataPntr
	pla
.endmacro

.macro set_mode
	php
	pha
	MoveB g_currentMode, k_currentMode
	pla
	plp
.endmacro

.macro get_mode
	pha
	MoveB k_currentMode, g_currentMode
	pla
.endmacro

.macro set_mode_and_colors
	lda g_currentMode
	ora #1
	sta k_currentMode
	lda #0  ; fg: black
	ldx #15
	ldy #1  ; bg: white
	jsrfar GRAPH_set_colors
.endmacro

.macro set_drawing_parameters
	php
	pha
	set_mode_and_colors
	MoveB g_windowTop, k_windowTop
	MoveB g_windowBottom, k_windowBottom
	MoveW g_leftMargin, k_leftMargin
	MoveW g_rightMargin, k_rightMargin
	pla
	plp
.endmacro

.macro jsrfar addr
	jsr gjsrfar
	.word addr
	.byte BANK_KERNAL
.endmacro

.import gjsrfar

.export _GetCharWidth, _GetRealSize, _LoadCharSet, _SmallPutChar, _UseSystemFont, _PutCharK

;---------------------------------------------------------------
; GetCharWidth
;
; Function:  Calculate the pixel width of a characteras it
;            exists in the font (in its plaintext form). Ignores
;            any style attributes.
;
; Pass:      a   ASCII character
; Return:    a   character width
; Destroyed: nothing
;---------------------------------------------------------------
_GetCharWidth:
	phx
	phy
	ldx #0; mode
	jsr _GetRealSize
	tya
	ply
	plx
	rts

;---------------------------------------------------------------
; GetRealSize                                             $C1B1
;
; Function:  Returns the size of a character in the current
;            mode (bold, italic...) and current Font.
;
; Pass:      a   ASCII character
;            x   currentMode
; Return:    y   character width
;            x   character height
;            a   baseline offset
; Destroyed: nothing
;---------------------------------------------------------------
_GetRealSize:
	php
	sei
	set_mode
	jsrfar GRAPH_get_char_size
	plp
	phx
	phy
	plx
	ply
	rts

_UseSystemFont:
	LoadW r0, 0
	php
	sei
	jsrfar GRAPH_set_font
	get_font_parameters
	plp
	rts

_LoadCharSet:
	php
	sei
	jsrfar GRAPH_set_font
	get_font_parameters
	plp
	rts

;---------------------------------------------------------------
; SmallPutChar
;
; Function:  Print a single character without the PutChar
;            overhead.
;
; Pass:      a   character code (byte)
;            r11 x-coordinate of left of character
;            r1H y-coordinate of character baseline
; Return:    r11 x-position for next character
;            r1H unchanged
; Destroyed: a, x, y, r1L, r2-r10, r12, r13
;---------------------------------------------------------------
; This is no longer significantly faster than PutChar
_SmallPutChar:
	cmp #$20
	bcs @1
@0:	rts
@1:	cmp #$80
	bne @3
	lda #$ff ; convert code $80 to $FF (GEOS compat. "logo" char)
@3:	pha
	set_mode_and_colors
	LoadW k_leftMargin, 0
	LoadW k_rightMargin, SC_PIX_WIDTH-1
	pla
; fallthrough

_PutCharK:
	php
	sei
	set_drawing_parameters
	jsrfar GRAPH_put_char
	rol tmp1
	get_mode
	plp
	lsr tmp1
	rts
