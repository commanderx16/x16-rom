.export __rtc_systime_update

.import sdcard_init

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
.include "fcntl.inc"
.include "65c02.inc"


databuffer = $8000
dirstart   = $0801
fnbuffer   = $1000

; LOAD"$"
zpdir         = 2 ; 2 bytes
num_blocks    = 4 ; 2 bytes
fn_base       = 6 ; 1 byte

writebufptr   = 7 ; 1 byte
writebuf      = 8 ; 2 byte
bufferptr     = 10; 1 byte
databufferlen = 11; 1 byte
save_x        = 12; 1 byte
save_y        = 13; 1 byte


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

cbdos_listn:
	; ignore

	stx save_x
	sty save_y
	jsr sdcard_init
	ldy save_y
	ldx save_x
	rts ; do nothing

cbdos_secnd: ; after listen
	; If it's $Fx, the bytes sent by the host until UNLISTEN
	; will be a filename to be associated with channel x.
	; Otherwise, we need to receive into channel x.

	lda #0
	sta writebufptr
	lda #<fnbuffer
	sta writebuf
	lda #>fnbuffer
	sta writebuf + 1
	rts ; do nothing

cbdos_ciout:
	sty save_y
	ldy writebufptr
	sta (writebuf),y
	ldy save_y
	inc writebufptr
	rts

cbdos_unlsn:
	stx save_x
	sty save_y
	ldy #0
	lda (writebuf),y
	cmp #'$'
	bne not_dir
	jsr read_dir
	jmp cbdos_unlsn2
not_dir:
	jsr read_file
cbdos_unlsn2:
	lda #0
	sta bufferptr
	ldy save_y
	ldx save_x
	rts

cbdos_talk:
	rts

cbdos_tksa: ; after talk
	rts

cbdos_acptr:
	lda databufferlen
	bne :+
	lda #$02 ; file not found
	sta $90
	lda #0
	rts

:
	stx save_x
	ldx bufferptr
	lda databuffer,x
	ldx save_x
	inc bufferptr
	pha
	lda bufferptr
	cmp databufferlen
	bne :+
acptr_fnf:
	lda #$40 ; EOI
	sta $90
:	pla
	rts

cbdos_untlk:
	rts

read_file:
	jsr fat_mount

	lda #0 ; zero-terminate
	ldy writebufptr
	sta (writebuf),y
	lda writebuf
	ldx writebuf + 1
	ldy #O_RDONLY
	jsr fat_open
X1:
	bne read_file_error

	SetVector databuffer, read_blkptr

	ldy #5
	jsr fat_fread
	lda #$ff
	sta databufferlen ; XXX
	rts

read_file_error:
	lda #0
	sta databufferlen ; = file not found
	rts



read_dir:
	jsr fat_mount

	lda #<databuffer
	sta zpdir
	lda #>databuffer
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

	sty databufferlen

	rts

txt_blocksfree:
	.byte "BLOCKS FREE."
txt_blocksfree_end:

storedir:
	sta (zpdir),y
	iny
	bne :+
	inc zpdir + 1
:	rts

allfiles:
	.byte "*.*", 0

__rtc_systime_update:
	rts



write_block:
	rts

