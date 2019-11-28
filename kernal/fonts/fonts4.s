; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Font drawing

.segment "fonts4"

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
