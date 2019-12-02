; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Console I/O: UseSystemFont, LoadCharSet, GetCharWidth syscalls

.export k_LoadCharSet   ; GEOS API
.export k_UseSystemFont ; GEOS API
.export k_GetCharWidth  ; GEOS API
.export k_SmallPutChar  ; GEOS API

.export font_init

font_init:
	LoadB windowTop, 0
	LoadB windowBottom, SC_PIX_HEIGHT-1
	LoadW leftMargin, 0
	LoadW rightMargin, SC_PIX_WIDTH-1
; fallthrough
k_UseSystemFont:
	LoadW r0, SystemFont
k_LoadCharSet:
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
; SmallPutChar
;
; Pass:      same as PutChar, but must be sure that
;            everything is OK, there is no checking
; Return:    same as PutChar
; Destroyed: same as PutChar
;---------------------------------------------------------------
k_SmallPutChar:
	subv $20
	jmp k_FontPutChar

