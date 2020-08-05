;----------------------------------------------------------------------
; CBDOS Directory Listing
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.export dir_open, dir_read

; cmdch.s
.import set_status

; file.s
.import set_errno_status

; functions.s
.import create_fat32_path_only_dir, create_fat32_path_only_name

.import soft_check_medium_a
.import medium
.import parse_cbmdos_filename
.import buffer

.include "fat32/fat32.inc"
.include "fat32/regs.inc"

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
context:
	.byte 0
dir_eof:
	.byte 0
is_part_dir:
	.byte 0

.segment "cbdos"

;---------------------------------------------------------------
;---------------------------------------------------------------
dir_open:
	pha ; filename length

	jsr fat32_alloc_context
	bcs @alloc_ok

	pla
	lda #$70
	jsr set_status
	sec
	rts

@alloc_ok:
	sta context
	jsr fat32_set_context

	lda #0
	jsr set_status

	stz is_part_dir

	lda buffer+1
	cmp #'='
	bne @not_part_dir
	lda buffer+2
	cmp #'P'
	bne @not_part_dir

	lda #$80
	sta is_part_dir

	; partition directory
	lda buffer+3
	cmp #':'
	bne @no_filter

	ldx #4
	ply ; filename length
	bra @cont1

@no_filter:
	ply ; filename length
	ldx #1
	ldy #1
	bra @cont1

@not_part_dir:

	ldx #1
	ply ; filename length
@cont1:
	jsr parse_cbmdos_filename
	bcc @1
	lda #$30 ; syntax error
	jmp @dir_open_err
@1:	lda medium
	jsr soft_check_medium_a
	bcc @2
	lda #$74 ; drive not ready
	jmp @dir_open_err
@2:

	ldy #0
	lda #<DIRSTART
	jsr storedir
	lda #>DIRSTART
	jsr storedir
	lda #1
	jsr storedir ; link
	jsr storedir

	lda #0
	bit is_part_dir
	bpl @not_part1
	lda #255
@not_part1:
	jsr storedir ; header line number
	lda #0
	jsr storedir
	lda #$12 ; reverse
	jsr storedir
	lda #$22 ; quote
	jsr storedir

	bit is_part_dir
	bpl @not_part2

	ldx #0
@3b:	lda part_dir_header,x
	beq @4
	jsr storedir
	inx
	bne @3b
	bra @4

@not_part2:
	phy
	jsr fat32_get_vollabel
	ply
	bcc @dir_open_err3

	ldx #0
@3:	lda fat32_dirent + dirent::name,x
	beq @4
	jsr storedir
	inx
	bne @3

@4:	cpx #16
	bcs @5
	lda #$20
	jsr storedir
	inx
	bra @4
@5:

	lda #$22 ; quote
	jsr storedir
	lda #' '
	jsr storedir

	bit is_part_dir
	bpl @not_part4
	lda #' '
	jsr storedir
	lda #'M'
	jsr storedir
	lda #'B'
	jsr storedir
	lda #'R'
	jsr storedir
	lda #' '
	bra @cont4

@not_part4:
	lda #'F'
	jsr storedir
	lda #'A'
	jsr storedir
	lda #'T'
	jsr storedir
	lda #'3'
	jsr storedir
	lda #'2'
@cont4:
	jsr storedir
	lda #0 ; end of line
	jsr storedir
	phy

	jsr create_fat32_path_only_dir

	bit is_part_dir
	bpl @not_part3
	jsr fat32_open_ptable
	bra @cont3

@not_part3:
	jsr fat32_open_dir
@cont3:
	ply
	bcc @dir_open_err3

	sty dirbuffer_w
	stz dirbuffer_r

	stz dir_eof
	clc ; ok
	rts

@dir_open_err3:
	jsr set_errno_status
	bra @dir_open_err2
@dir_open_err:
	jsr set_status
@dir_open_err2:
	lda context
	jsr fat32_free_context
	lda #1
	sta dir_eof
	clc ; ok
	rts

;---------------------------------------------------------------
;---------------------------------------------------------------
dir_read:
	ldx dirbuffer_r
	cpx dirbuffer_w
	beq @acptr_empty

	lda dirbuffer,x
	inc dirbuffer_r
	clc
	rts

@acptr_empty:
	jsr read_dir_entry
	bcc dir_read
	lda #0
	rts ; C = 1


;---------------------------------------------------------------
read_dir_entry:
	lda dir_eof
	beq @read_entry
	sec
	rts

@read_entry:

	jsr create_fat32_path_only_name

	bit is_part_dir
	bpl @not_part1
	jsr fat32_ptable_entry
	bra @cont1

@not_part1:
	jsr fat32_read_dirent_filtered
@cont1:
	bcs @found
	lda fat32_errno
	beq :+
	jsr set_errno_status
:	bit is_part_dir
	bmi :+
	jmp @read_dir_entry_end
:	jmp @dir_end

@found:	;lda fat32_dirent + dirent::name
	;cmp #'.' ; hide "." and ".."
	;beq @read_entry

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
	sbc #<10000
	lda num_blocks + 1
	sbc #>10000
	bcc @ngt_10000
	lda #'T' - $40
	jsr storedir
	bra @gt_1000

@ngt_10000:
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

	ldx #2
	bra :+
@gt_10:
	ldx #1
	bra :+
@gt_100:
	ldx #0
:	lda #' '
:	jsr storedir
	dex
	bpl :-
@gt_1000:

;@gt_10000:
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
	cpx #17
	bcc :-

	lda fat32_dirent + dirent::attributes
	bit #$10 ; = directory
	bne @read_dir_entry_dir

	lda #'P'
	jsr storedir
	lda #'R'
	jsr storedir
	lda #'G'
	jsr storedir
	bra @read_dir_cont

@read_dir_entry_dir:
	lda #'D'
	jsr storedir
	lda #'I'
	jsr storedir
	lda #'R'
	jsr storedir

@read_dir_cont:
	lda fat32_dirent + dirent::attributes
	lsr
	bcc :+
	lda #'<' ; write protect indicator
	jsr storedir
:

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
	beq @dir_end
	jsr storedir
	inx
	bne :-

@dir_end:
	lda #0
	jsr storedir
	jsr storedir
	; the final 0 is missing, because the character transmission
	; function will send one extra 0 with EOI

	jsr fat32_close ; can't fail
	lda context
	jsr fat32_free_context

	inc dir_eof ; = 1

	sty dirbuffer_w
	stz dirbuffer_r
	clc ; ok
	rts


txt_free:
	.byte "B FREE.", 0

part_dir_header:
	.byte "CBDOS SDCARD", 0

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
