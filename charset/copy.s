
.include "../io.inc"

data = $aaaa; XXX
tmp2 = $aa; XXX

; this code lives on the same ROM bank as the character sets
.segment "CPYCHR"

banked_cpychr:
	jsr inicpy
	cmp #0
	beq cpycustom
	cmp #1
	beq cpyiso
	cmp #2
	beq cpypet1
	cmp #3
	beq cpypet2
	rts ; ignore unsupported values

; 0: custom character set
cpycustom:
	stx tmp2
	sty tmp2+1
	ldx #8
copyv:	ldy #0
:	lda (tmp2),y
	eor data
	sta veradat
	iny
	bne :-
	inc tmp2+1
	dex
	bne :-
	rts

; 1: ISO character set
cpyiso:	lda #$c8
	sta tmp2+1       ;character data at ROM 0800
	ldx #8
	jmp copyv

; 2: PETSCII upper/graph character set
cpypet1:
	lda #$c0
	sta tmp2+1       ;character data at ROM 0000
	ldx #4
	jsr copyv
	dec data
	lda #$c0
	sta tmp2+1       ;character data at ROM 0000
	ldx #4
	jmp copyv

; 3: PETSCII upper/lower character set
cpypet2:
	lda #$c4
	sta tmp2+1       ;character data at ROM 0400
	ldx #4
	jsr copyv
	dec data
	lda #$c4
	sta tmp2+1       ;character data at ROM 0400
	ldx #4
	jmp copyv

inicpy:
	ldx #<tilbas
	stx veralo
	ldx #>tilbas
	stx veramid
	ldx #$10 | (tilbas >> 16)
	stx verahi
	stz data
	stz tmp2
	rts
