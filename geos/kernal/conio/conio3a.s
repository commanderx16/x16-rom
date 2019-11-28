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

.macro jsrfar addr
	jsr gjsrfar
	.word addr
	.byte BANK_KERNAL
.endmacro

.import gjsrfar

.import k_FontPutChar, k_GetCharWidth, k_GetRealSize, k_LoadCharSet, k_SmallPutChar, k_UseSystemFont

.export FontPutChar, _GetCharWidth, _GetRealSize, _LoadCharSet, _SmallPutChar, _UseSystemFont

FontPutChar:
	php
	sei
	jsrfar k_FontPutChar
	plp
	rts

_GetCharWidth:
	php
	sei
	jsrfar k_GetCharWidth
	plp
	rts

_GetRealSize:
	php
	sei
	jsrfar k_GetRealSize
	plp
	rts

_LoadCharSet:
	php
	sei
	jsrfar k_LoadCharSet
	plp
	rts

_SmallPutChar:
	php
	sei
	jsrfar k_SmallPutChar
	plp
	rts

_UseSystemFont:
	php
	sei
	jsrfar k_UseSystemFont
	plp
	rts

