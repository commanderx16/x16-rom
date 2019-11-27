.feature labels_without_colons

.include "../io.inc"

.importzp tmp2; [declare]
.import data; [declare]

.export banked_cpychr

.segment "CPYCHR"

banked_cpychr:
	jsr inicpy
; 1: PET1
	cmp #1
	beq cpypet1
; 2: PET2
@1:	cmp #2
	beq cpypet2
; 0 and default: ISO
@2:
; ISO character set
cpyiso	lda #$c8
	sta tmp2+1       ;character data at ROM 0800
	ldx #8
;
copyv	ldy #0
px3	lda (tmp2),y
	eor data
	sta veradat
	iny
	bne px3
	inc tmp2+1
	dex
	bne px3
	rts

; PETSCII character set
cpypet1	lda #$c0
	sta tmp2+1       ;character data at ROM 0000
	ldx #4
	jsr copyv
	dec data
	lda #$c0
	sta tmp2+1       ;character data at ROM 0000
	ldx #4
	jmp copyv

cpypet2	lda #$c4
	sta tmp2+1       ;character data at ROM 0400
	ldx #4
	jsr copyv
	dec data
	lda #$c4
	sta tmp2+1       ;character data at ROM 0400
	ldx #4
	jmp copyv

inicpy	ldx #<tilbas
	stx veralo
	ldx #>tilbas
	stx veramid
	ldx #$10 | (tilbas >> 16)
	stx verahi
	stz data
	stz tmp2
	rts
