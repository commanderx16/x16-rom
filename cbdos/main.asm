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

.export tmp1, krn_tmp, krn_tmp2, krn_tmp3, sd_tmp, lba_addr, blocks
.export fd_area, sd_blktarget, block_data, block_fat

.include "zeropage.inc"
.include "common.inc"
IMPORTED_FROM_MAIN=1
.include "fat32.inc"
.include "fcntl.inc"
.include "65c02.inc"

NUM_BUFS = 4
TOTAL_NUM_BUFS = NUM_BUFS + 3
; special purpose buffers follow general purpose buffers
BUFNO_FN     = NUM_BUFS
BUFNO_CMD    = NUM_BUFS + 1
BUFNO_STATUS = NUM_BUFS + 2

DIRSTART = $0801 ; load address of directory

.segment "cbdos_data"

; Commodore DOS buffers
buffers:
	.res NUM_BUFS * 512, 0
fnbuffer:
	.res 512, 0
cmdbuffer:
	.res 512, 0
statusbuffer:
	.res 512, 0

; SD/FAT32 buffers/variables
fd_area: ; File descriptor area
	.res 128, 0
sd_blktarget:
block_data:
	.res 512, 0
block_fat:
	.res 512, 0
tmp1:
	.byte 0
krn_tmp:
	.byte 0
krn_tmp2:
	.byte 0
krn_tmp3:
	.byte 0
sd_tmp:
	.byte 0
lba_addr:
	.byte 0,0,0,0
blocks: ; 3 bytes blocks to read, 3 bytes sufficient to address 4GB -> 4294967296 >> 9 = 8388608 ($800000) max blocks/file
	.byte 0,0,0

; Commodore DOS variables
initialized:
	.byte 0
MAGIC_INITIALIZED  = $7A
fn_base:
	.byte 0
cur_buffer_ptr:
	.word 0
cur_buffer_len:
	.word 0
save_x:
	.byte 0
save_y:
	.byte 0
listen_addr:
	.byte 0
channel:
	.byte 0
num_blocks:
	.word 0
fnlen:
	.byte 0
bufferno:
	.byte 0

buffer_alloc_map:
	; $00 = free, $ff = allocated
	.res NUM_BUFS, 0

; number of valid data bytes in each buffer
buffer_len:
	.res TOTAL_NUM_BUFS * 2, 0

; current r/w pointer within the buffer
buffer_ptr:
	.res TOTAL_NUM_BUFS * 2, 0

bytes_remaining_for_channel:
	.res 16 * 4, 0

is_last_block_for_channel:
	; $ff = after transmitting the contents of this buffer,
	;       there won't be more
	.res 16, 0

fd_for_channel:
	.res 16, 0
; $ff = none
MAGIC_FD_DIR_LOAD = $fe

buffer_for_channel:
	.res 15, 0 ; just 0-14; cmd/status is special cased


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

cbdos_init:
	; XXX don't do lazy init
	lda #MAGIC_INITIALIZED
	cmp initialized
	bne :+
	rts
:	sta initialized
	stx save_x

	ldx #NUM_BUFS - 1
	lda #0
:	sta buffer_alloc_map,x
	dex
	bpl :-

	ldx #14
	lda #$ff
:	sta buffer_for_channel,x
	dex
	bpl :-

	ldx #15
:	sta fd_for_channel,x
	dex
	bpl :-

	jsr init_status

	ldx save_x
	rts

;****************************************
; LISTEN
;****************************************
cbdos_listn:
	jmp cbdos_init ; XXX

;****************************************
; SECOND (after LISTEN)
;****************************************
cbdos_secnd: ; after listen
	; If it's $Fx, the bytes sent by the host until UNLISTEN
	; will be a filename to be associated with channel x.
	; Otherwise, we need to receive into channel x.

	sta listen_addr ; we need it for UNLISTEN

; if channel 15, ignore "OPEN", just switch to it
	and #$0f
	cmp #$0f
	sta channel
	bne :+
	lda #BUFNO_CMD
	jmp switch_to_buffer

:	lda listen_addr
	and #$f0
	cmp #$f0
	beq @secnd_open

	cmp #$e0
	beq @secnd_close

; switch to channel
	lda channel
	tax
	lda buffer_for_channel,x
	jmp switch_to_buffer

@secnd_open:
	lda #0
	sta buffer_ptr + 2 * BUFNO_FN ; clear fn buffer
	sta buffer_ptr + 2 * BUFNO_FN + 1
	lda #BUFNO_FN
	jmp switch_to_buffer

@secnd_close:
	lda channel
	cmp #$0f
	beq @ignore_close_15
	jmp buf_free

@ignore_close_15:
	rts

;****************************************
; SEND
;****************************************
cbdos_ciout:
	sty save_y
	ldy cur_buffer_ptr + 1
	bne @ciout2
; halfblock 0
	ldy cur_buffer_ptr
	sta (buffer),y
	ldy save_y
	inc cur_buffer_ptr
	bne :+
	inc cur_buffer_ptr + 1
:	rts
@ciout2:
; halfblock 1
	ldy cur_buffer_ptr
	inc buffer + 1
	sta (buffer),y
	dec buffer + 1
	ldy save_y
	inc cur_buffer_ptr
	bne :+
; XXX reached 0x200
	brk
:	rts

;****************************************
; UNLISTEN
;****************************************
cbdos_unlsn:
	; UNLISTEN of the command channel ignores whether it was OPEN
	lda channel
	cmp #$0f
	beq @unlisten_cmd

	lda listen_addr
	and #$f0
	cmp #$f0
	beq unlsn_open

	; otherwise UNLISTEN does nothing
	rts

@unlisten_cmd:
; UNLISTEN on command channel -> execute
	brk

unlsn_open:
	stx save_x
	sty save_y

	; XXX low byte only
	lda cur_buffer_ptr
	sta fnlen

	lda channel
	jsr buf_alloc
	bcs no_bufs

	jsr sdcard_init

	lda fnbuffer
	cmp #'$'
	bne @not_dir

; DIR
	jsr open_dir
	jmp @unlisten_end

; READ FILE
@not_dir:
	jsr open_file
@unlisten_end:
	jsr finished_with_buffer

	ldy save_y
	ldx save_x
	rts

; no buffers
no_bufs:
	; TODO
	brk

;****************************************
; TALK
;****************************************
cbdos_talk:
	jmp cbdos_init ; XXX

;****************************************
; SECOND (after TALK)
;****************************************
cbdos_tksa: ; after talk
	and #$0f
	cmp #$0f
	bne :+
	lda #BUFNO_STATUS
	jmp switch_to_buffer

:	tax
	lda buffer_for_channel,x
	bmi @empty_channel
	jmp switch_to_buffer

@empty_channel:
	brk; TODO

;****************************************
; RECEIVE
;****************************************
cbdos_acptr:
	stx save_x
	sty save_y
	ldx channel
	lda fd_for_channel,x
	bpl @acptr5 ; actual file
	cmp #MAGIC_FD_DIR_LOAD
	beq @acptr5
; no fd
	lda #$02 ; timeout/file not found
	sta $90
	lda #0
	ldy save_y
	ldx save_x
	sec
	rts

; no data? read more
@acptr5:
	lda cur_buffer_len
	ora cur_buffer_len + 1
	bne @acptr7

	ldx channel
	lda fd_for_channel,x
	cmp #MAGIC_FD_DIR_LOAD
	bne @acptr6 ; actual file
; read next directory line
	jsr read_dir
	jmp @acptr7
@acptr6:
; read next block
	jsr read_block
@acptr7:
	ldy cur_buffer_ptr + 1
	bne @acptr1
; halfblock 0
	ldy cur_buffer_ptr
	lda (buffer),y
	jmp @acptr2
@acptr1:
; halfblock 1
	ldy cur_buffer_ptr
	inc buffer + 1
	lda (buffer),y
	dec buffer + 1
@acptr2:
	inc cur_buffer_ptr
	bne :+
	inc cur_buffer_ptr + 1
:	pha
	lda cur_buffer_ptr + 1
	cmp cur_buffer_len + 1
	bne @acptr3
	lda cur_buffer_ptr
	cmp cur_buffer_len
	bne @acptr3
; buffer exhausted
	ldx channel
	lda is_last_block_for_channel,x
	bmi @acptr4

; read another block next time
	lda #0
	sta cur_buffer_len
	sta cur_buffer_len + 1
	sta cur_buffer_ptr
	sta cur_buffer_ptr + 1
	jmp @acptr3

@acptr4:
; EOI
	lda #$40
	sta $90
; clear fd from channel
	ldx channel
	lda #$ff
	sta fd_for_channel,x
; status
	lda channel
	cmp #$0f
	bne @acptr3
; reload OK status
	jsr init_status
	lda buffer_len + 2 * BUFNO_STATUS
	sta cur_buffer_len
	lda buffer_len + 2 * BUFNO_STATUS + 1
	sta cur_buffer_len + 1

@acptr3:
	pla
	ldy save_y
	ldx save_x
	clc
	rts

;****************************************
; UNTALK
;****************************************
cbdos_untlk:
	stx save_x
	sty save_y
	jsr finished_with_buffer
	ldy save_y
	ldx save_x
	rts

;****************************************
; allocate a buffer for channel
; * remember it as the channel's buffer
; * switch to it
;   in:  A: channel
;   out: C: 0: success; 1: error
buf_alloc:
	tay ;  save channel
; search & allocate free buffer
	ldx #0
:	lda buffer_alloc_map,x
	beq :+
	inx
	cpx #NUM_BUFS
	bne :-
	sec ; error
	rts
:	dec buffer_alloc_map,x
; associate channel with buffer
	txa
	sta buffer_for_channel,y
; set buffer pointer to 0
	asl
	tay
	lda #0
	sta buffer_ptr,y
	sta buffer_ptr + 1,y
	tya
	lsr
switch_to_buffer:
	sta bufferno
; fetch buffer pointer & len
	asl
	tay
	lda buffer_ptr,y
	sta cur_buffer_ptr
	lda buffer_ptr + 1,y
	sta cur_buffer_ptr + 1
	lda buffer_len,y
	sta cur_buffer_len
	lda buffer_len + 1,y
	sta cur_buffer_len + 1
; set zp word
	tya ; buffer# * 2
	clc
	adc #>buffers
	sta buffer + 1
	lda #0
	sta buffer
	clc ; success
	rts

;****************************************
; free a channel's buffer
;   in: A: channel
buf_free:
	tax
	lda buffer_for_channel,x
	tay
	lda #$ff
	sta buffer_for_channel,x
	lda #0
	sta buffer_alloc_map,y
	rts

;****************************************
; write back buffer ptr
finished_with_buffer:
	lda bufferno
	asl
	tax
	lda cur_buffer_ptr
	sta buffer_ptr,x
	lda cur_buffer_ptr + 1
	sta buffer_ptr + 1,x
	lda cur_buffer_len
	sta buffer_len,x
	lda cur_buffer_len + 1
	sta buffer_len + 1,x
	rts

;****************************************
init_status:
	lda #0
	sta buffer_len + 2 * BUFNO_STATUS + 1
	ldx #stat_end - stat
	stx buffer_len + 2 * BUFNO_STATUS
	dex
:	lda stat,x
	sta statusbuffer,x
	dex
	bpl :-
	rts

stat:
	.byte "00,OK,00,00", 13
stat_end:

;****************************************
open_file:
	jsr fat_mount

	lda #0 ; zero-terminate filename
	ldy fnlen
	sta fnbuffer,y
	lda #<fnbuffer
	ldx #>fnbuffer
	ldy #O_RDONLY
	jsr fat_open
	beq :+
	lda #$ff
	.byte $24 ; no fd
:	txa
	ldx channel
	sta fd_for_channel,x ; remember fd

; start counting remaining bytes
	tax
	ldy channel
	lda fd_area + F32_fd::FileSize + 0, x
	sta bytes_remaining_for_channel + 0,y
	lda fd_area + F32_fd::FileSize + 1, x
	sta bytes_remaining_for_channel + 1,y
	lda fd_area + F32_fd::FileSize + 2, x
	sta bytes_remaining_for_channel + 2,y
	lda fd_area + F32_fd::FileSize + 3, x
	sta bytes_remaining_for_channel + 3,y

; indicate there's nothing currently read
	lda #0
	sta cur_buffer_len
	sta cur_buffer_len + 1
	rts


read_block:
	ldx channel
	lda fd_for_channel,x
	bpl :+
	sec
	rts ; no fd, return
:	tax
	lda buffer
	sta read_blkptr
	lda buffer + 1
	sta read_blkptr + 1
	ldy #1 ; one block
	jsr fat_fread

X1:

; are there more than $0200 bytes remaining?
	ldx channel
	lda bytes_remaining_for_channel + 0,x
	sec
	sbc #<$0200
	pha
	lda bytes_remaining_for_channel + 1,x
	sbc #>$0200
	pha
	lda bytes_remaining_for_channel + 2,x
	sbc #0
	pha
	lda bytes_remaining_for_channel + 3,x
	sbc #0
	bcc @read_block1
; yes, subtract $0200, say there's $0200 in the buffer
	sta bytes_remaining_for_channel + 3,x
	pla
	sta bytes_remaining_for_channel + 2,x
	pla
	sta bytes_remaining_for_channel + 1,x
	pla
	sta bytes_remaining_for_channel + 0,x
	lda #<$0200
	sta cur_buffer_len
	lda #>$0200
	sta cur_buffer_len + 1
	lda #0
	sta is_last_block_for_channel,x
	clc
	rts
; no, say there's this many bytes in the buffer
@read_block1:
	pla
	pla
	pla
	lda bytes_remaining_for_channel + 0,x
	sta cur_buffer_len
	lda bytes_remaining_for_channel + 1,x
	sta cur_buffer_len + 1
	lda #$ff
	sta is_last_block_for_channel,x
	clc
	rts



open_dir:
	lda #MAGIC_FD_DIR_LOAD
	ldx channel
	sta fd_for_channel,x ; remember fd

	jsr fat_mount

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
	SetVector allfiles, filenameptr
	ldx #FD_INDEX_CURRENT_DIR
	jsr fat_find_first
	ply
	bcc end_of_dir ; end of dir

not_end_of_dir:
	sty cur_buffer_len
	lda #0
	sta cur_buffer_len + 1
	lda #0
	ldx channel
	sta is_last_block_for_channel,x

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

	sty cur_buffer_len
	lda #0
	sta cur_buffer_len + 1
	lda #$ff
	ldx channel
	sta is_last_block_for_channel,x

	rts

read_dir:
	ldy #0
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

	lda buffer
	sta krn_ptr3
	lda buffer + 1
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
	sta (buffer),y
	iny
	bne :+
	inc buffer + 1
:	rts

allfiles:
	.byte "*.*", 0

__rtc_systime_update:
	rts



write_block:
	rts

