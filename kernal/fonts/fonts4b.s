; Commander X16 KERNAL
; based on GEOS by Berkeley Softworks; reversed by Maciej Witkowiak, Michael Steil
;
; Font library: drawing

FontGt1:
	sty fontTemp1+1
	sty fontTemp1+2
	lda (r2),y
	and FontTVar3
	and r7H
	jmp (r12)

FontGt2:
	sty fontTemp1+2
	sty fontTemp1+3
	lda (r2),y
	and FontTVar3
	sta fontTemp1
	iny
	lda (r2),y
	and r7H
	sta fontTemp1+1
FontGt2_1:
	lda fontTemp1
	jmp (r12)

FontGt3:
	sty fontTemp1+3
	sty fontTemp1+4
	lda (r2),y
	and FontTVar3
	sta fontTemp1
	iny
	lda (r2),y
	sta fontTemp1+1
	iny
	lda (r2),y
	and r7H
	sta fontTemp1+2
.ifdef bsw128 ; dup for speed?
	lda fontTemp1
	jmp (r12)
.else
	bra FontGt2_1
.endif

FontGt4:
	lda (r2),y
	and FontTVar3
	sta fontTemp1
FontGt4_1:
	iny
	cpy r3H
	beq FontGt4_2
	lda (r2),y
	sta fontTemp1,y
	bra FontGt4_1
FontGt4_2:
	lda (r2),y
	and r7H
	sta fontTemp1,y
	lda #0
	sta fontTemp1+1,y
	sta fontTemp1+2,y
.ifdef bsw128 ; dup for speed?
	lda fontTemp1
	jmp (r12)
.else
	beq FontGt2_1
.endif
