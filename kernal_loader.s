; C64 RAM KERNAL Loader
; by David Murray, Michael Steil, 2019

!to "kernal_loader.prg",cbm

*=$0801               ;start address is $0801

basic:	!byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00
	;adds basic line:  1 sys 2061

	;copy BASIC to RAM
	lda #00
	sta $fb
	lda #$a0
	sta $fc
	ldy #00
copy1:
	lda ($fb),y             ;reads from ROM
	sta ($fb),y             ;writes to RAM
	iny
	cpy #00
	bne copy1
	inc $fc
	lda $fc
	cmp #$c0
	bne copy1

	;copy new KERNAL to RAM
	lda #<kernal_rom
	sta $fb
	lda #>kernal_rom
	sta $fc

	;lda #$00
	;sta $fb
	;lda #$e0
	;sta $fc


	lda #$00
	sta $fd
	lda #$e0
	sta $fe
	ldy #$00
copy2:
	lda ($fb),y             ;reads from new KERNAL
	sta ($fd),y             ;writes to KERNAL RAM space
	iny
	cpy #$00
	bne copy2
	inc $fc
	inc $fe
	lda $fe
	cmp #00
	bne copy2

	sei

	lda #$7f
	sta $dc0d
	bit $dc0d

	lda #53
	sta 1
	jmp ($fffc) ; RESET

kernal_rom !binary "kernal-c64.bin"

