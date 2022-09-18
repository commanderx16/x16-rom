; Commander X16 KERNAL
; based on GEOS by Berkeley Softworks; reversed by Maciej Witkowiak, Michael Steil
;
; Font library: drawing

FntShJump:
	sta fontTemp1
.ifdef bsw128
	bbsf BOLD_BIT, currentMode, @X
	rts
@X:
.else
	bbrf BOLD_BIT, currentMode, noop
.endif
	clc
	php
	ldy #$ff
@5:
	iny
	lda fontTemp1,y
	plp
	ror
	ora fontTemp1,y
	sta fontTemp1,y
	php
	cpy r8L
	bne @5
	pla
noop:	rts
