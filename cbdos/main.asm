.export read_block, write_block
.export sd_read_multiblock

.export __rtc_systime_update

.import fat_mount
.import fat_open, fat_chdir, fat_unlink
.import fat_mkdir, fat_rmdir
.import fat_read_block, fat_fread ; TODO FIXME update exec, use fat_fread
.import fat_read
.import fat_fseek
.import fat_find_first, fat_find_next, fat_write
.import fat_get_root_and_pwd
.import fat_close_all, fat_close, fat_getfilesize
.import inc_lba_address

.import fat_name_string

.include "zeropage.inc"
.include "common.inc"
.include "fat32.inc"
.include "65c02.inc"


dirbuffer  = $8000
dirstart   = $0801
namebuffer = $1000

zpdir         = 2 ; 2 bytes
num_blocks    = 4 ; 2 bytes
fn_base       = 6 ; 1 byte
namebufferptr = 7 ; 1 byte
bufferptr     = 8 ; 1 byte
dirbufferlen  = 9


.segment "cbdos"
; $C000

	jmp cbdos_secnd
	jmp cbdos_tksa
	jmp cbdos_acptr
	jmp cbdos_ciout
	jmp cbdos_untlk
	jmp cbdos_unlsn
	jmp cbdos_listn
	jmp cbdos_talk

cbdos_secnd: ; after talk
	lda #0
	sta namebufferptr
	rts ; do nothing
cbdos_tksa: ; after listen
	jsr read_dir
	lda #0
	sta bufferptr
	rts
cbdos_acptr:
	ldx bufferptr
	lda dirbuffer,x
	inc bufferptr
	pha
	lda bufferptr
	cmp dirbufferlen
	bne :+
	lda #$40 ; EOI
	sta $90
:	pla
	rts
cbdos_ciout:
	ldx namebufferptr
	sta namebuffer,x
	rts
cbdos_untlk:
	rts
cbdos_unlsn:
	rts
cbdos_listn:
	rts ; do nothing
cbdos_talk:
	rts




;	.word start


read_dir:
	jsr fat_mount

	nop

	lda #<dirbuffer
	sta zpdir
	lda #>dirbuffer
	sta zpdir+1
	ldy #0
	lda #<dirstart
	jsr storedir
	lda #>dirstart
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
	lda #'G'
	jsr storedir
	lda #'H'
	jsr storedir
	lda #' '
	jsr storedir
	lda #'2'
	jsr storedir
	lda #'A'
	jsr storedir
	lda #0 ; end of line
	jsr storedir

	phy

	nop

	SetVector allfiles, filenameptr
	ldx #FD_INDEX_CURRENT_DIR
	jsr fat_find_first

	ply

dir_loop:
	lda #1
	jsr storedir ; link
	jsr storedir

	tya
	tax
	ldy #F32DirEntry::FileSize
	lda (dirptr),y
	iny
	clc
	adc #255
	lda #0
	adc (dirptr),y
	sta num_blocks
	iny
	lda #0
	adc (dirptr),y
	sta num_blocks + 1
	iny
	lda #0
	adc (dirptr),y
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

Y1:

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
	.byte $2c
gt_10:
	ldx #2
	.byte $2c
gt_100:
	ldx #1
	.byte $2c
gt_1000:
	ldx #0
	lda #' '
:	jsr storedir
	dex
	bne :-

	lda #$22
	jsr storedir

	lda zpdir
	sta krn_ptr3
	lda zpdir + 1
	sta krn_ptr3 + 1
	sty krn_tmp3
	sty fn_base
	jsr fat_name_string
	ldy krn_tmp3

	lda #$22 ; quote
	jsr storedir

	lda #17
	sec
	sbc krn_tmp3
	clc
	adc fn_base
	tax

	lda #' '
:	jsr storedir
	dex
	bne :-

	lda #'P'
	jsr storedir
	lda #'R'
	jsr storedir
	lda #'G'
	jsr storedir
	lda #0 ; end of line
	jsr storedir

	phy
	ldx #FD_INDEX_CURRENT_DIR
	jsr fat_find_next
	ply
	bcc end_of_dir ; end of dir
	cmp #0
	bne end_of_dir ; error
	jmp dir_loop

end_of_dir:
	lda #0
	jsr storedir
	jsr storedir

	sty dirbufferlen

	rts



.if 0
	lda #<filename
	ldx #>filename
	ldy #1 ; O_RDONLY
	jsr fat_open

	SetVector $1000, read_blkptr

	ldy #5
	jsr fat_fread

	jmp *
.endif

storedir:
	sta (zpdir),y
	iny
	bne :+
	inc zpdir + 1
:	rts

filename:
;	.byte "HELLO.TXT", 0
	.byte "FAT32.ASM", 0
allfiles:
	.byte "*.*", 0

read_block:
	jmp 0 ; emulator takes care of this
sd_read_multiblock:
	jmp *

__rtc_systime_update:
	rts



write_block:
	rts

