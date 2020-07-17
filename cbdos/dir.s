.export open_dir, acptr_dir

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

dirbuffer_r:
	.byte 0
dirbuffer_w:
	.byte 0
num_blocks:
	.word 0
dir_eof:
	.byte 0

.segment "cbdos"

;---------------------------------------------------------------
;---------------------------------------------------------------
open_dir:
	jsr fat32_init
	bcs :+

	sec
	rts

:	lda #0
	jsr set_status

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

	sty dirbuffer_w
	stz dirbuffer_r

	jsr fat32_open_dir
	bcc @open_dir_err

	stz dir_eof
	clc ; ok
	rts

@open_dir_err:
	lda #1
	sta dir_eof
	clc ; ok
	rts

;---------------------------------------------------------------
;---------------------------------------------------------------
acptr_dir:
	ldx dirbuffer_r
	cpx dirbuffer_w
	beq @acptr_empty

	lda dirbuffer,x
	inc dirbuffer_r
	clc
	rts

@acptr_empty:
	jsr read_dir_entry
	bcc acptr_dir
	rts ; C = 1


;---------------------------------------------------------------
read_dir_entry:
	lda dir_eof
	beq :+
	sec
	rts

:	jsr fat32_read_dirent
	bcs :+
	jmp @read_dir_entry_end

:	lda fat32_dirent + dirent::attributes
	bit #$10 ; = directory
	bne read_dir_entry

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
	bcs @gt_1000
	lda num_blocks
	sec
	sbc #<100
	lda num_blocks + 1
	sbc #>100
	bcs @gt_100
	lda num_blocks
	sec
	sbc #<10
	lda num_blocks + 1
	sbc #>10
	bcs @gt_10
	ldx #3
	bra :+
@gt_10:
	ldx #2
	bra :+
@gt_100:
	ldx #1
	bra :+
@gt_1000:
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

	stz dir_eof

	sty dirbuffer_w
	stz dirbuffer_r
	clc ; ok
	rts


@read_dir_entry_end:
	ldy #0
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
	jsr storedir

	inc dir_eof ; = 1

	sty dirbuffer_w
	stz dirbuffer_r
	clc ; ok
	rts


txt_blocksfree:
	.byte "BLOCKS FREE."
txt_blocksfree_end:

storedir:
	sta dirbuffer,y
	iny
	rts
