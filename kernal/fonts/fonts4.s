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
	lda #0
	pha
	ldy #$ff
@5:
	iny
	ldx fontTemp1,y
	pla
	ora FontTab,x
	sta fontTemp1,y
	txa
	lsr
	lda #0
	ror
	pha
	cpy r8L
	bne @5
	pla
noop:	rts
