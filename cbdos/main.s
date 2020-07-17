
.export __rtc_systime_update

.import sdcard_init

.import fat32_init

.import fat32_dirent

.export tmp1, krn_tmp, krn_tmp2, krn_tmp3, sd_tmp, lba_addr, blocks
.export fd_area

.importzp filenameptr, krn_ptr1, krn_ptr3, dirptr, read_blkptr, buffer, bank_save

.include "banks.inc"

;.include "common.inc"
IMPORTED_FROM_MAIN=1

.feature labels_without_colons

.include "fat32.inc"
.include "fcntl.inc"
;.include "65c02.inc"

.include "regs.inc"


NUM_BUFS = 2
TOTAL_NUM_BUFS = NUM_BUFS + 3
; special purpose buffers follow general purpose buffers
BUFNO_FN     = NUM_BUFS
BUFNO_CMD    = NUM_BUFS + 1
BUFNO_STATUS = NUM_BUFS + 2
; XXX Filename cnd CMD buffers shouldn't be separate!
; XXX In both cases, the full string has to be transmissed in one go
; XXX and will be discarded afterwards.

DIRSTART = $0801 ; load address of directory

via1        = $9f60
via1porta   = via1+1 ; RAM bank

.macro BANKING_START
	pha
	lda via1porta
	sta bank_save
	stz via1porta
	pla
.endmacro

.macro BANKING_END
	pha
	lda bank_save
	sta via1porta
	pla
.endmacro

.segment "cbdos_data"

; Commodore DOS buffers
buffers:
	.res NUM_BUFS * 256, 0
fnbuffer:
	.res 256, 0
cmdbuffer:
	.res 256, 0
statusbuffer:
	.res 256, 0

; SD/FAT32 buffers/variables
fd_area: ; File descriptor area
	.res 128, 0
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
	.byte 0
cur_buffer_len:
	.byte 0
save_x:
	.byte 0
save_y:
	.byte 0
listen_cmd:
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
	.res TOTAL_NUM_BUFS, 0

; current r/w pointer within the buffer
buffer_ptr:
	.res TOTAL_NUM_BUFS, 0

is_last_block_for_channel:
	; $ff = after transmitting the contents of this buffer,
	;       there won't be more
	.res 16, 0

fd_for_channel:
	.res 16, 0
MAGIC_FD_NONE     = $ff
MAGIC_FD_STATUS   = $fe
MAGIC_FD_DIR_LOAD = $fd
MAGIC_FD_EOF      = $fc

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
; GEOS
	jmp cbmdos_OpenDisk
	jmp cbmdos_ReadBuff
	jmp cbmdos_ReadBlock
	jmp cbmdos_GetDirHead
	jmp cbmdos_CalcBlksFree
	jmp cbmdos_Get1stDirEntry
	jmp cbmdos_GetNxtDirEntry

; detection
	jmp cbdos_sdcard_detect

;---------------------------------------------------------------
; Initialize CBDOS data structures
;
; This has to be done once and is triggered by
; cbdos_sdcard_detect.
;---------------------------------------------------------------
cbdos_init:
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

	ldx #14
	lda #MAGIC_FD_NONE
:	sta fd_for_channel,x
	dex
	bpl :-

	lda #MAGIC_FD_STATUS
	sta fd_for_channel + 15
	jsr set_status_73

	ldx save_x
	rts

;---------------------------------------------------------------
; Detect SD card
;
; Returns Z=1 if SD card is present
;---------------------------------------------------------------
cbdos_sdcard_detect:
	BANKING_START
	jsr cbdos_init
	jsr sdcard_init ; C=0: error
	lda #0
	rol
	eor #1          ; Z=0: error
	BANKING_END
	rts

;---------------------------------------------------------------
; LISTEN
;
; Nothing to do.
;---------------------------------------------------------------
cbdos_listn:
	rts

;---------------------------------------------------------------
; SECOND (after LISTEN)
;
;   In:   a    secondary address
;---------------------------------------------------------------
cbdos_secnd:
	BANKING_START
	stx save_x
	sty save_y

	; The upper nybble is the command:
	; $Fx OPEN
	;     The bytes sent by the host until UNLISTEN will be
	;     a filename to be associated with the given channel.
	; $6x LISTEN
	;     The bytes sent by the host until UNLISTEN will be
	;     received into the given channel. (The channel has
	;     to be open.)
	; $Ex CLOSE
	;     Close the given channel, no more bytes will be sent
	;     to it.

; separate into cmd and channel
	tax
	and #$f0
	sta listen_cmd ; we need it for UNLISTEN
	txa
	and #$0f
	sta channel

; special-case command channel
	cmp #$0f
	beq @secnd_cmdch

	lda listen_cmd
	cmp #$f0
	beq @secnd_open
	cmp #$e0
	beq @secnd_close

;---------------------------------------------------------------
; switch to channel
	ldx channel
	; XXX open already?
	lda buffer_for_channel,x
	bra @secnd_switch

;---------------------------------------------------------------
; LISTEN on command channel will ignore OPEN/CLOSE
; -> always just switch to command channel
@secnd_cmdch:
	lda #BUFNO_CMD
	jmp @secnd_switch

;---------------------------------------------------------------
; Initiate OPEN
@secnd_open:
	lda #0
	sta buffer_ptr + BUFNO_FN ; clear fn buffer
	lda #BUFNO_FN
@secnd_switch:
	jsr switch_to_buffer
	bra @secnd_rts

;---------------------------------------------------------------
; CLOSE
@secnd_close:
	lda channel
	jsr buf_free

@secnd_rts:
	ldx save_x
	ldy save_y
	BANKING_END
	rts

;---------------------------------------------------------------
; SEND
;
; XXX This has to be rewritten:
;     * CMD channel and FN buffer should be special cased
;       and use buffers < 512 bytes
;     * regular channel writes will go directly to fat32 lib
;---------------------------------------------------------------
cbdos_ciout:
	BANKING_START
	sty save_y
	ldy cur_buffer_ptr
	sta (buffer),y
	inc cur_buffer_ptr
	bne :+
	brk
:	ldy save_y
	BANKING_END
	rts

;---------------------------------------------------------------
; UNLISTEN
;---------------------------------------------------------------
cbdos_unlsn:
	BANKING_START
	stx save_x
	sty save_y

; special-case command channel
	lda channel
	cmp #$0f
	beq @unlisten_cmdch

	lda listen_cmd
	cmp #$f0
	bne @unlsn_end2; otherwise UNLISTEN does nothing

;---------------------------------------------------------------
; Execute OPEN with filename
	lda cur_buffer_ptr
	sta fnlen

	lda channel
	jsr buf_alloc
	bcs @no_bufs

	; XXX necessary?
	jsr sdcard_init

	lda fnbuffer
	cmp #'$'
	bne @not_dir

;---------------------------------------------------------------
; OPEN directory
	jsr open_dir
	jmp @unlisten_end

;---------------------------------------------------------------
; OPEN file
@not_dir:
	jsr open_file

@unlisten_end:
	jsr finished_with_buffer

@unlsn_end2:
	ldy save_y
	ldx save_x
	BANKING_END
	rts

; no buffers
@no_bufs:
	; TODO
	brk

;---------------------------------------------------------------
; Execute Command
;
; UNLISTEN on command channel will ignore whether it was
; and OPEN command; it will always trigger command execution
@unlisten_cmdch:
	jsr execute_command
	jmp @unlsn_end2


;---------------------------------------------------------------
; TALK
;
; Nothing to do.
;---------------------------------------------------------------
cbdos_talk:
	rts

;---------------------------------------------------------------
; SECOND (after TALK)
;---------------------------------------------------------------
cbdos_tksa: ; after talk
	BANKING_START
	stx save_x
	sty save_y

	and #$0f
	sta channel

; special-case command channel
	cmp #$0f
	beq @tksa_cmdch

	tax
	lda buffer_for_channel,x
	bmi @empty_channel

@tksa_switch:
	jsr switch_to_buffer
	ldx save_x
	ldy save_y
	BANKING_END
	rts

@empty_channel:
	brk; TODO

@tksa_cmdch:
	lda #BUFNO_STATUS
	bra @tksa_switch

;---------------------------------------------------------------
; RECEIVE
;---------------------------------------------------------------
cbdos_acptr:
	BANKING_START
	stx save_x
	sty save_y
	ldx channel
	lda fd_for_channel,x
	bpl @acptrX ; actual file
	cmp #MAGIC_FD_DIR_LOAD
	beq @acptr5
 	cmp #MAGIC_FD_STATUS
	beq @acptr5
	cmp #MAGIC_FD_NONE
	beq @acptr_nofd
; else #MAGIC_FD_EOF


; EOF
@eof:
	lda #$40
	bra :+
@acptr_nofd
; no fd
	lda #$02 ; timeout/file not found
:	sta status
	lda #0
	ldy save_y
	ldx save_x
	BANKING_END
	sec
	rts

@acptrX:
	jsr fat32_read_byte
	bcc @eof
	jmp @acptr_end

; no data? read more
@acptr5:
	lda cur_buffer_len
	bne @acptr7

	ldx channel
	lda fd_for_channel,x
	cmp #MAGIC_FD_DIR_LOAD
	bne @acptr6
; read next directory line
	jsr read_dir
	jmp @acptr7
@acptr6:
; MAGIC_FD_STATUS

	lda #$40 ; EOF
	sta status
	jsr set_status_ok
	lda buffer_len + BUFNO_STATUS
	sta cur_buffer_len
	lda #$0d
	bne @acptr_end

@acptr7:
	ldy cur_buffer_ptr
	lda (buffer),y
	inc cur_buffer_ptr
	bne :+
	brk
:	pha
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
	sta cur_buffer_ptr
	jmp @acptr3

@acptr4:
; clear fd from channel
	ldx channel
	lda #MAGIC_FD_EOF ; next time, send EOF
	sta fd_for_channel,x

@acptr3:
	pla
@acptr_end:
	ldy save_y
	ldx save_x
	BANKING_END
	clc
	rts

;---------------------------------------------------------------
; UNTALK
;---------------------------------------------------------------
cbdos_untlk:
	BANKING_START
	stx save_x
	sty save_y
	jsr finished_with_buffer
	ldy save_y
	ldx save_x
	BANKING_END
	rts

;---------------------------------------------------------------
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
	tya
	lsr
switch_to_buffer:
	sta bufferno
; fetch buffer pointer & len
	tay
	lda buffer_ptr,y
	sta cur_buffer_ptr
	lda buffer_len,y
	sta cur_buffer_len
; set zp word
	tya ; buffer# * 2
	clc
	adc #>buffers
	sta buffer + 1
	lda #0
	sta buffer
	clc ; success
	rts

;---------------------------------------------------------------
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

;---------------------------------------------------------------
; write back buffer ptr
finished_with_buffer:
	lda bufferno
	tax
	lda cur_buffer_ptr
	sta buffer_ptr,x
	lda cur_buffer_len
	sta buffer_len,x
	rts

;---------------------------------------------------------------
set_status_ok:
	lda #$00
	bra :+
set_status_writeprot
	lda #$26
	bra :+
set_status_synerr
	lda #$31
	bra :+
set_status_62
	lda #$62
	bra :+
set_status_73
	lda #$73
	bra :+
set_status_74
	lda #$74
:	pha
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta statusbuffer
	pla
	and #$0f
	ora #$30
	sta statusbuffer + 1
	lda #','
	sta statusbuffer + 2
	pla
	ldx #0
:	cmp stcodes,x
	beq :+
	inx
	cpx #stcodes_end - stcodes
	bne :-
:	txa
	asl
	tax
	lda ststrs,x
	sta krn_ptr1
	lda ststrs + 1,x
	sta krn_ptr1 + 1
	ldx #3
	ldy #0
:	lda (krn_ptr1),y
	beq :+
	sta statusbuffer,x
	iny
	inx
	bne :-
:	lda #','
	sta statusbuffer + 0,x
	lda #'0'
	sta statusbuffer + 1,x
	sta statusbuffer + 2,x
	lda #','
	sta statusbuffer + 3,x
	lda #'0'
	sta statusbuffer + 4,x
	sta statusbuffer + 5,x

	lda #0
	sta buffer_ptr + BUFNO_STATUS
	txa
	clc
	adc #6
	sta buffer_len + BUFNO_STATUS
	rts

stcodes:
	.byte $00, $26, $31, $62, $73, $74
stcodes_end:

ststrs:
	.word status_00
	.word status_26
	.word status_31
	.word status_62
	.word status_73
	.word status_74

status_00:
	.byte "OK", 0
status_26:
	.byte "WRITE PROTECT ON", 0
status_31:
	.byte "SYNTAX ERROR" ,0
status_62:
	.byte " FILE NOT FOUND" ,0
status_73:
	.byte "CBDOS V1.0 X16", 0
status_74:
	.byte "DRIVE NOT READY", 0

;---------------------------------------------------------------
open_file:
	jsr fat32_init

	lda #0 ; zero-terminate filename
	ldy fnlen
	sta fnbuffer,y
	lda #<fnbuffer
	sta fat32_ptr + 0
	lda #>fnbuffer
	sta fat32_ptr + 1
	jsr fat32_open
	lda #0 ; >= 0 FD
	bcs :+
	lda #MAGIC_FD_NONE
:	ldx channel
	sta fd_for_channel,x ; remember fd
	rts

open_dir:
	jsr fat32_init
	bcs :+
	lda #$02 ; timeout/file not found
	sta status
	jmp set_status_62
:
	lda #MAGIC_FD_DIR_LOAD
	ldx channel
	sta fd_for_channel,x ; remember fd

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
	nop
	ply
	bcc end_of_dir ; end of dir

not_end_of_dir:
	sty cur_buffer_len
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
	lda #$ff
	ldx channel
	sta is_last_block_for_channel,x

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
gt_10
	ldx #2
	bra :+
gt_100
	ldx #1
	bra :+
gt_1000
	ldx #0
:	lda #' '
:	jsr storedir
	dex
	bpl :-

	lda #$22
	jsr storedir

	lda buffer
	sta krn_ptr3
	lda buffer + 1
	sta krn_ptr3 + 1
;	sty krn_tmp3
	sty fn_base

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
	sta (buffer),y
	iny
	bne :+
	inc buffer + 1 ; XXX?
:	rts

__rtc_systime_update:
	rts



write_block:
	rts

execute_command:
	lda cur_buffer_ptr
	beq @rts ; empty

	lda cmdbuffer
	ldx #0
:	cmp cmds,x
	beq @found
	inx
	cpx #cmds_end - cmds
	bne :-
	jmp set_status_synerr

@found:
	txa
	asl
	tax
	lda cmdptrs + 1,x
	pha
	lda cmdptrs,x
	pha
@rts:	rts

cmds:
	.byte "IVNRSCU"
cmds_end:

cmdptrs:
	.word cmd_i - 1
	.word cmd_v - 1
	.word cmd_n - 1
	.word cmd_r - 1
	.word cmd_s - 1
	.word cmd_c - 1
	.word cmd_u - 1

cmd_i:
	jsr fat32_init
	jmp set_status_ok ; XXX error handling

cmd_v:
	jmp set_status_writeprot

cmd_n:
	jmp set_status_writeprot

cmd_r:
	jmp set_status_writeprot

cmd_s:
	jmp set_status_writeprot

cmd_c:
	jmp set_status_writeprot

cmd_u:
	jmp set_status_73


;
; GEOS
;
; TODO: The SD card driver is using zero page and other memory
;       locations that are also used by GEOS! We need too find
;       memory that is unused by KERNAL, BASIC and GEOS!

.include "../geos/inc/geossym.inc"
.include "../geos/inc/geosmac.inc"

.import sd_read_block_lower, sd_read_block_upper

cbmdos_OpenDisk:
	jsr sdcard_init

	jsr get_dir_head
	LoadB $848b, $ff ; isGEOS
	ldx #17
:	lda $8290,x
	sta $841e,x
	dex
	bpl :-
	LoadW r5, $841e
	ldx #0
	rts

cbmdos_ReadBuff:
	LoadW r4, $8000
cbmdos_ReadBlock:
GetBlock:
	ldx #1
	lda #0
	tay
@l1:	cpx r1L
	beq @l2
	clc
	adc secpertrack - 1,x
	bcc @l3
	iny
@l3:	inx
	jmp @l1
@l2:	clc
	adc r1H
	bcc @l4
	iny
@l4:	sta lba_addr+0
	sty lba_addr+1
	stz lba_addr+2
	stz lba_addr+3
	lsr lba_addr+1 ; / 2
	ror lba_addr+0
	lda r4L
	sta read_blkptr
	lda r4H
	sta read_blkptr + 1
	bcs @l5
;XXX	jsr sd_read_block_lower
	jmp @l6
@l5:
;XXX	jsr sd_read_block_upper
@l6:	ldx #0 ; no error
	rts



cbmdos_GetDirHead:
	jsr get_dir_head
	LoadW r4, $8200
	rts


cbmdos_CalcBlksFree:
	LoadW r4, 999*4
	LoadW r3, 999*4
	ldx #0
	rts


cbmdos_Get1stDirEntry:
	LoadW r4, $8000
	LoadB r1L, 18
	LoadB r1H, 1
	jsr cbmdos_ReadBlock
	lda #$02
	sta r4L
	sta r5L
	lda #$80
	sta r4H
	sta r5H
	ldx #0
	sec
	rts

cbmdos_GetNxtDirEntry:
	ldy #1
	clc
	rts

get_dir_head:
	LoadB r1L, 18
	LoadB r1H, 0
	LoadW r4, $8200
	jmp cbmdos_ReadBlock

secpertrack:
	.byte 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 19, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17

.segment "IRQB"
	.word banked_irq
