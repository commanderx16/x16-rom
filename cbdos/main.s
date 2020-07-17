
.import sdcard_init

.import fat32_init

.import fat32_dirent

.export tmp1, krn_tmp, krn_tmp2, krn_tmp3, sd_tmp, lba_addr, blocks
.export fd_area

.importzp filenameptr, krn_ptr1, krn_ptr3, dirptr, read_blkptr, buffer, bank_save

; cmdch.s
.import execute_command, set_status
.export buffer_len
.export BUFNO_STATUS
.export buffer_ptr
.export statusbuffer
.export cmdbuffer

; dir.s
.import open_dir, read_dir
.export fn_base, num_blocks, cur_buffer_len, is_last_block_for_channel
.export channel, fd_for_channel, status
.export MAGIC_FD_DIR_LOAD

; geos.s
.import cbmdos_GetNxtDirEntry, cbmdos_Get1stDirEntry, cbmdos_CalcBlksFree, cbmdos_GetDirHead, cbmdos_ReadBlock, cbmdos_ReadBuff, cbmdos_OpenDisk

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
	lda #$73
	jsr set_status

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
	lda #0
	jsr set_status
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

.segment "IRQB"
	.word banked_irq
