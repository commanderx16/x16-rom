; This header allows building the FAT32 code for a non-C 6502 CPU.
; Just flip the ".if" to enable emulation of the new instructions.
; Note that it will require two zeropage locations.

.if 1
.setcpu "65c02"

.macro bitimm arg1
	bit #arg1
.endmacro

.macro ldaind arg1
	lda (arg1)
.endmacro

.macro staind arg1
	sta (arg1)
.endmacro

.macro cmpind arg1
	cmp (arg1)
.endmacro

.macro inca
	inc
.endmacro

.else
zptmp65c02_0 = $00
zptmp65c02_1 = $01

.macro stz arg1, arg2
	php
	pha
	lda #0
.ifblank arg2
	sta arg1
.else
	sta arg1,arg2
.endif
	pla
	plp
.endmacro

.macro bra arg1
	jmp arg1
.endmacro

.macro phx
	sta zptmp65c02_0
	php
	pla
	sta zptmp65c02_1
	txa
	pha
	lda zptmp65c02_1
	pha
	lda zptmp65c02_0
	plp
.endmacro

.macro plx
	sta zptmp65c02_0
	pla
	tax
	php
	lda zptmp65c02_0
	plp
.endmacro

.macro phy
	sta zptmp65c02_0
	php
	pla
	sta zptmp65c02_1
	tya
	pha
	lda zptmp65c02_1
	pha
	lda zptmp65c02_0
	plp
.endmacro

.macro ply
	sta zptmp65c02_0
	pla
	tay
	php
	lda zptmp65c02_0
	plp
.endmacro

.macro bitimm arg1
	pha
	lda #arg1
	sta zptmp65c02_0
	pla
	bit zptmp65c02_0
.endmacro

.macro inca
	php
	clc
	adc #1
	plp
	and #zptmp65c02_0
.endmacro

.macro ldaind arg1
	sty zptmp65c02_0
	ldy #0
	lda (arg1),y
	php
	ldy zptmp65c02_0
	plp
.endmacro

.macro staind arg1
	sty zptmp65c02_0
	ldy #0
	sta (arg1),y
	php
	ldy zptmp65c02_0
	plp
.endmacro

.macro cmpind arg1
	sty zptmp65c02_0
	ldy #0
	cmp (arg1),y
	php
	ldy zptmp65c02_0
	plp
.endmacro

.endif
