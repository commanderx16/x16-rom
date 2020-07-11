;-----------------------------------------------------------------------------
; fat32_util.s
; Copyright (C) 2020 Frank van den Hoef
;-----------------------------------------------------------------------------

        .include "fat32_util.inc"
	.include "lib.inc"
	.include "fat32.inc"
	.include "text_display.inc"
	.include "text_input.inc"

;-----------------------------------------------------------------------------
; Variables
;-----------------------------------------------------------------------------
	.bss

	.code

;-----------------------------------------------------------------------------
; print_dirent
;-----------------------------------------------------------------------------
.proc print_dirent
	; Print file name
	ldx #0
:	lda fat32_dirent + dirent::name, x
	beq :+
	jsr to_lower
	jsr putchar
	inx
	bne :-
:
	; Pad spaces
:	cpx #13
	beq :+
	inx
	lda #' '
	jsr putchar
	bra :-
:
	; Print attributes
	lda fat32_dirent + dirent::attributes
	bit #$10
	bne dir

	; Print size
	set32 val32, fat32_dirent + dirent::size
	lda #' '
	sta padch
	jsr print_val32

	bra cluster

dir:	ldy #0
:	lda dirstr, y
	beq :+
	jsr putchar
	iny
	bra :-
:
cluster:
.if 0
	; Spacing
	lda #' '
	jsr putchar

	; Print cluster
	; set32 val32, fat32_dirent + dirent::cluster
	; lda #0
	; sta padch
	; jsr print_val32

	ldx #3
:	lda fat32_dirent + dirent::cluster, x
	jsr puthex
	dex
	cpx #$FF
	bne :-
.endif

	; New line
	lda #10
	jsr putchar

	rts

dirstr: .byte "<DIR>     ", 0
.endproc
