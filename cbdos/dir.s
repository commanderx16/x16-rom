.export open_dir, acptr_dir

; cmdch.s
.import set_status

; fat32.s
.import fat32_dirent, fat32_get_free_space, fat32_size

.include "fat32/fat32.inc"
.include "fat32/regs.inc"

DIRSTART = $0801 ; load address of directory
MAX_DIRLINE_LEN = 40

.segment "cbdos_data"

dirbuffer:
	.res MAX_DIRLINE_LEN, 0

dirbuffer_r:
	.byte 0
dirbuffer_w:
	.byte 0
num_blocks:
	.word 0
context:
	.byte 0
dir_eof:
	.byte 0

.segment "cbdos"

;---------------------------------------------------------------
;---------------------------------------------------------------
open_dir:
	lda #0
	jsr set_status

	jsr fat32_alloc_context
	sta context
	jsr fat32_set_context

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

	lda #<root
	sta fat32_ptr
	lda #>root
	sta fat32_ptr + 1

	jsr fat32_open_dir
	bcc @open_dir_err

	stz dir_eof
	clc ; ok
	rts

@open_dir_err:
	lda context
	jsr fat32_free_context
	lda #1
	sta dir_eof
	clc ; ok
	rts

root:
	.byte '/', 0

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
	lda #0
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

	jsr fat32_get_free_space
	lda fat32_size + 2
	ora fat32_size + 3
	bne @not_kb

	lda #'K'
	bra @print_free

@not_kb:
	jsr shr10
	lda fat32_size + 2
	bne @not_mb

	lda #'M'
	bra @print_free

@not_mb:
	jsr shr10
	lda #'G'

@print_free:
	pha
	lda fat32_size + 0
	jsr storedir
	lda fat32_size + 1
	jsr storedir
	pla
	jsr storedir
	ldx #0
:	lda txt_free,x
	jsr storedir
	inx
	cpx #txt_free_end - txt_free
	bne :-

	lda #0
	jsr storedir
	jsr storedir
	; the final 0 is missing, because the character transmission
	; function will send one extra 0 with EOI

	jsr fat32_close
	lda context
	jsr fat32_free_context

	inc dir_eof ; = 1

	sty dirbuffer_w
	stz dirbuffer_r
	clc ; ok
	rts


txt_free:
	.byte "B FREE."
txt_free_end:

storedir:
	sta dirbuffer,y
	iny
	rts

shr10:
	; >> 8
	lda fat32_size + 1
	sta fat32_size + 0
	lda fat32_size + 2
	sta fat32_size + 1
	lda fat32_size + 3
	sta fat32_size + 2

	; >> 2
	lsr fat32_size + 2
	ror fat32_size + 1
	ror fat32_size + 0
	lsr fat32_size + 2
	ror fat32_size + 1
	ror fat32_size + 0

	lda fat32_size + 0
	lda fat32_size + 1
	lda fat32_size + 2
	lda fat32_size + 3
	rts
