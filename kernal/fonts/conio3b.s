; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Console I/O: UseSystemFont, LoadCharSet, GetCharWidth syscalls

.global k_LoadCharSet   ; GEOS API
.global k_UseSystemFont ; GEOS API
.global k_GetCharWidth  ; GEOS API
.global k_SmallPutChar  ; GEOS API

.segment "conio3b"

k_UseSystemFont:
.ifdef bsw128
	bbsf 7, graphMode, @X
	LoadW r0, SystemFont
	bra k_LoadCharSet
@X:	LoadW r0, BSWFont80
.else
	LoadW r0, SystemFont
.endif
k_LoadCharSet:
	ldy #0
@1:	lda (r0),y
	sta baselineOffset,y
	iny
	cpy #8
	bne @1
	AddW r0, curIndexTable
	AddW r0, cardDataPntr

.if .defined(trap2) && (!.defined(trap2_alternate_location))
	; copy high-byte of serial
	lda SerialHiCompare
	bne @2
	jsr GetSerialNumber2
	sta SerialHiCompare
@2:
.endif
	rts

k_GetCharWidth:
	subv $20
	bcs GetChWdth1
	lda #0
	rts
GetChWdth1:
	cmp #$5f
.ifdef bsw128 ; branch taken/not taken optimization
	beq @2
.else
	bne @1
	lda PrvCharWidth
	rts
@1:
.endif
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
.ifdef bsw128 ; branch taken/not taken optimization
@2:	lda PrvCharWidth
	rts
.endif

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

