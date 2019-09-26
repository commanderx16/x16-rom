	.feature labels_without_colons
	;use cpu 65C02
	.pc02

	.import __BANK0_LOAD__
	.import __BANK1_LOAD__
	.import __BANK2_LOAD__

	.code
	.org $800-1
	.word $801
basic_stub
	.word @1
	.word 0
	.byte $9E	; SYS
	.byte <(((start / 1000) .mod 10) + $30)  ; SYS address
	.byte <(((start / 100 ) .mod 10) + $30)
	.byte <(((start / 10  ) .mod 10) + $30)
	.byte <(((start       ) .mod 10) + $30)
	.byte 0
@1	.word 0

DFLTO   = $9A
CHROUT  = $FFD2
PTR	= $FB
BANKSEL	= $9F61
JSRFAR	= $03D1

.macro print addr
	ldx #<addr
	ldy #>addr
	jsr strout
.endmacro

.macro jsrfar addr, bank
	jsr JSRFAR
	.word addr
	.byte bank
.endmacro

.macro savestack
	tsx
	phx
.endmacro

.macro checkstack
	plx
	stx $00
	tsx
	cpx $00
	beq @end
	print aErrSP
@end:
.endmacro

.macro setregs aa, xx, yy
	lda #aa
	ldx #xx
	ldy #yy
	.byte $ff
.endmacro

.macro checkregs aa, xx, yy
	.byte $ff
	.scope
	cmp #aa
	beq @cx
	lda #1
	.byte $2c
@cx	lda #0
	cpx #xx
	beq @cy
	ora #2
@cy	cpy #yy
	beq @px
	pha
	print aErrY
	pla
@px	cmp #2
	bcc @pa
	pha
	print aErrX
	pla
@pa	ora #0
	beq @end
	print aErrA
@end:
	.endscope
.endmacro

aErrA	.byte $81,"register a mismatch!",5,0
aErrX	.byte $81,"register x mismatch!",5,0
aErrY	.byte $81,"register y mismatch!",5,0
aErrSP	.byte $81,"stack pointer mismatch!",5,0

	;.data
aCopy	.byte "copying code to bank "
cCpBank	.byte "0...",0
aMain0	.byte "main program calling bank 0...",0
aMainRt	.byte "we returned to main program.",0

	.code
	.proc start

	lda #3
	sta DFLTO   ; Set output to screen
	lda #'0'
	sta cCpBank
	print aCopy
	ldx #<__BANK0_LOAD__
	ldy #>__BANK0_LOAD__
	lda #0
	jsr copy2bank
	lda #'1'
	sta cCpBank
	print aCopy
	ldx #<__BANK1_LOAD__
	ldy #>__BANK1_LOAD__
	lda #1
	jsr copy2bank
	lda #'2'
	sta cCpBank
	print aCopy
	ldx #<__BANK2_LOAD__
	ldy #>__BANK2_LOAD__
	lda #2
	jsr copy2bank

	print aMain0
	savestack
	setregs $1A, $2B, $3C
	jsrfar $A000, 0
	checkregs $1A, $2B, $3C
	checkstack
	print aMainRt

	rts

	.endproc

	.proc strout
	stx PTR
	sty PTR+1
	ldy #0
@loop	lda (PTR),y
	beq @fin	
	jsr CHROUT
	iny
	bne @loop
@fin	lda #$0D
	jsr CHROUT
	lda #$0A
	jmp CHROUT
	.endproc

	; Copies a 256-byte block to $A000
	.proc copy2bank
	stx PTR
	sty PTR+1
	sta BANKSEL
	ldy #0
@loop	lda (PTR),y
	sta $A000,y
	iny
	bne @loop
	rts
	.endproc

	.segment "BANK0"
	.proc hello0
	print aMsg
	print aCall
	savestack
	setregs $4D, $5E, $6F
	jsrfar $A000,2
	checkregs $4D, $5E, $6F
	checkstack
	print aRet
	rts
aMsg	.byte "hello from bank zero",0
aCall	.byte "bank zero calling bank two...",0
aRet	.byte "we returned to bank zero.",0
	.endproc

	.segment "BANK1"
	.proc hello1
	print aMsg
	rts
aMsg	.byte "hello from bank one",0
	.endproc

	.segment "BANK2"
	.proc hello2
	print aMsg
	print aCall
	savestack
	setregs $9A, $8B, $7C
	jsrfar $A000,1
	checkregs $9A, $8B, $7C
	checkstack
	print aRet
	rts
aMsg	.byte "hello from bank two",0
aCall	.byte "bank two calling bank one...",0
aRet	.byte "we returned to bank two.",0
	.endproc
