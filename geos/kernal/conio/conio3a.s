; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Console I/O: PutString syscall

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"
.include "../../banks.inc"

.import _PutChar
.global _PutString

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

.import col1, col2, col_bg

.macro get_font_parameters
	pha
	MoveW curIndexTable, g_curIndexTable
	MoveB baselineOffset, g_baselineOffset
	MoveW curSetWidth, g_curSetWidth
	MoveB curHeight, g_curHeight
	MoveW cardDataPntr, g_cardDataPntr
	pla
.endmacro

.macro set_mode
	php
	pha
	MoveB g_currentMode, currentMode
	pla
	plp
.endmacro

.macro get_mode
	pha
	MoveB currentMode, g_currentMode
	pla
.endmacro

.macro set_drawing_parameters
	php
	pha
	lda g_currentMode
	ora #1
	sta currentMode
	lda #0  ; fg: black
	sta col1
	lda #15
	sta col2
	lda #1  ; bg: white
	sta col_bg
	MoveB g_windowTop, windowTop
	MoveB g_windowBottom, windowBottom
	MoveW g_leftMargin, leftMargin
	MoveW g_rightMargin, rightMargin
	pla
	plp
.endmacro

.macro jsrfar addr
	jsr gjsrfar
	.word addr
	.byte BANK_KERNAL
.endmacro


; FONT VARS
.importzp curIndexTable
.import baselineOffset, curSetWidth, curHeight, cardDataPntr, currentMode, windowTop, windowBottom, leftMargin, rightMargin

.import gjsrfar

.import k_GetCharWidth, k_GetRealSize, k_LoadCharSet, k_SmallPutChar, k_UseSystemFont, k_PutChar

.export _GetCharWidth, _GetRealSize, _LoadCharSet, _SmallPutChar, _UseSystemFont, _PutCharK

_GetCharWidth:
	php
	sei
	jsrfar k_GetCharWidth
	plp
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
	jsrfar k_GetRealSize
	plp
	rts

_UseSystemFont:
	php
	sei
	jsrfar k_UseSystemFont
	get_font_parameters
	plp
	rts

_LoadCharSet:
	php
	sei
	jsrfar k_LoadCharSet
	get_font_parameters
	plp
	rts

;---------------------------------------------------------------
; SmallPutChar                                            $C202
;
; Pass:      Print a single character; does not support control
;            codes, ignores faults
; Return:    same as PutChar
; Destroyed: same as PutChar
;---------------------------------------------------------------
_SmallPutChar:
	php
	sei
	set_drawing_parameters
	jsrfar k_SmallPutChar
	plp
	rts

_PutCharK:
	php
	sei
	set_drawing_parameters
	jsrfar k_PutChar
	rol tmp1
	get_mode
	plp
	lsr tmp1
	rts
