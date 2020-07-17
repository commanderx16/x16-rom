.export open_dir, acptr_dir, read_dir

.import channel, fd_for_channel, ieee_status
.importzp MAGIC_FD_EOF

.import set_status
.import fat32_dirent

.include "fat32.inc"
.include "regs.inc"

DIRSTART = $0801 ; load address of directory

.segment "cbdos_data"

dirbuffer:
	.res 256, 0

dirbuffer_w:
	.byte 0
dirbuffer_r:
	.byte 0
end_reached:
	.byte 0

num_blocks:
	.word 0

.segment "cbdos"
open_dir:
	jsr fat32_init
	bcs :+

	sec
	rts

	ldy #0
	lda #<DIRSTART
	jsr storedir
	lda #>DIRSTART
	jsr storedir
	lda #1
	jsr storedir ; link
	jsr storedir
	lda #0
	jsr storedir ; line 0
	jsr storedir
	lda #$12 ; reverse
	jsr storedir
	lda #$22 ; quote
	jsr storedir
	ldx #16
	lda #' '
:	jsr storedir
	dex
	bne :-
	lda #$22 ; quote
	jsr storedir
	lda #' '
	jsr storedir
	lda #'F'
	jsr storedir
	lda #'A'
	jsr storedir
	lda #'T'
	jsr storedir
	lda #'3'
	jsr storedir
	lda #'2'
	jsr storedir
	lda #0 ; end of line
	jsr storedir

	phy
	jsr fat32_open_cwd
	ply
	bcc end_of_dir ; end of dir

not_end_of_dir:
	sty dirbuffer_r
	stz end_reached

	clc ; ok
	rts

end_of_dir:
	lda #1
	jsr storedir ; link
	jsr storedir
	lda #$ff
	jsr storedir ; XXX TODO real blocks free
	jsr storedir
	ldx #0
:	lda txt_blocksfree,x
	jsr storedir
	inx
	cpx #txt_blocksfree_end - txt_blocksfree
	bne :-

	lda #0
	jsr storedir
	jsr storedir

	sty dirbuffer_r
	lda #1
	sta end_reached

	clc ; ok
	rts

acptr_dir:
	lda dirbuffer_r
	bne @acptr7

; read next directory line
	jsr read_dir
@acptr7:
	ldy dirbuffer_w
	lda dirbuffer,y
	inc dirbuffer_w
	bne :+
	brk
:	pha
	lda dirbuffer_w
	cmp dirbuffer_r
	bne @acptr3
; buffer exhausted
	lda end_reached
	bne @acptr4

; read another block next time
	lda #0
	sta dirbuffer_r
	sta dirbuffer_w
	bra @acptr3

@acptr4:
	pla
	sec
	rts

@acptr3:
	pla
	clc
	rts


read_dir:
	lda fat32_dirent + dirent::attributes
	bit #$10 ; = directory
	beq :+
	jmp next
:
	ldy #0
	lda #1
	jsr storedir ; link
	jsr storedir

	tya
	tax
	lda fat32_dirent + dirent::size + 0
	clc
	adc #255
	lda #0
	adc fat32_dirent + dirent::size + 1
	sta num_blocks
	lda #0
	adc fat32_dirent + dirent::size + 2
	sta num_blocks + 1
	lda #0
	adc fat32_dirent + dirent::size + 3
	beq :+
	lda #$ff ; overflows 65535 blocks, so show 65535
	sta num_blocks
	sta num_blocks + 1
:	txa
	tay

	lda num_blocks
	jsr storedir
	lda num_blocks + 1
	jsr storedir

	; find out how many spaces to print
	lda num_blocks
	sec
	sbc #<1000
	lda num_blocks + 1
	sbc #>1000
	bcs gt_1000
	lda num_blocks
	sec
	sbc #<100
	lda num_blocks + 1
	sbc #>100
	bcs gt_100
	lda num_blocks
	sec
	sbc #<10
	lda num_blocks + 1
	sbc #>10
	bcs gt_10
	ldx #3
	bra :+
gt_10:
	ldx #2
	bra :+
gt_100:
	ldx #1
	bra :+
gt_1000:
	ldx #0
:	lda #' '
:	jsr storedir
	dex
	bpl :-

	lda #$22
	jsr storedir

	ldx #0
:	lda fat32_dirent + dirent::name, x
	beq :+
	jsr storedir
	inx
	bne :-
:

	lda #$22 ; quote
	jsr storedir

	lda #' '
:	jsr storedir
	inx
	cpx #16
	bne :-

	lda #'P'
	jsr storedir
	lda #'R'
	jsr storedir
	lda #'G'
	jsr storedir
	lda #0 ; end of line
	jsr storedir

next:
	phy
	jsr fat32_read_dirent
	ply
	bcs :+
	jmp end_of_dir ; end of dir
	cmp #0
	beq :+
	jmp end_of_dir ; error
:	jmp not_end_of_dir


txt_blocksfree:
	.byte "BLOCKS FREE."
txt_blocksfree_end:

storedir:
	sta dirbuffer,y
	iny
	rts
