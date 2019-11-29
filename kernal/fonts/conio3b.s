; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Console I/O: UseSystemFont, LoadCharSet, GetCharWidth syscalls

.global k_LoadCharSet   ; GEOS API
.global k_UseSystemFont ; GEOS API
.global k_GetCharWidth  ; GEOS API
.global k_SmallPutChar  ; GEOS API

k_UseSystemFont:
	LoadW r0, SystemFont
k_LoadCharSet:
.if 0
	ldy #0
@1:	lda (r0),y
	sta baselineOffset,y
	iny
	cpy #8
	bne @1
.else
	ldy #0
	lda (r0),y
	sta baselineOffset
	iny
	lda (r0),y
	sta curSetWidth
	iny
	lda (r0),y
	sta curSetWidth+1
	iny
	lda (r0),y
	sta curHeight
	iny
	lda (r0),y
	sta curIndexTable
	iny
	lda (r0),y
	sta curIndexTable+1
	iny
	lda (r0),y
	sta cardDataPntr
	iny
	lda (r0),y
	sta cardDataPntr+1
.endif
	AddW r0, curIndexTable
	AddW r0, cardDataPntr
	rts

k_GetCharWidth:
	subv $20
	bcs GetChWdth1
	lda #0
	rts
GetChWdth1:
	cmp #$5f
	beq @2
	asl
	tay
	iny
	iny
	lda (curIndexTable),y
	dey
	dey
	sec
	sbc (curIndexTable),y
	rts
@2:	lda PrvCharWidth
	rts

;---------------------------------------------------------------
; SmallPutChar                                            $C202
;
; Pass:      same as PutChar, but must be sure that
;            everything is OK, there is no checking
; Return:    same as PutChar
; Destroyed: same as PutChar
;---------------------------------------------------------------
k_SmallPutChar:
	subv $20
	jmp k_FontPutChar

