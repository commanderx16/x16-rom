;----------------------------------------------------------------------
; CBDOS Main
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.import sdcard_init

.import fat32_init
.import fat32_dirent
.import sync_sector_buffer
.importzp krn_ptr1, read_blkptr, bank_save

.export convert_errno_status, set_errno_status

; cmdch.s
.import execute_command, set_status, acptr_status

; dir.s
.import open_dir, acptr_dir

; geos.s
.import cbmdos_GetNxtDirEntry, cbmdos_Get1stDirEntry, cbmdos_CalcBlksFree, cbmdos_GetDirHead, cbmdos_ReadBlock, cbmdos_ReadBuff, cbmdos_OpenDisk

; functions.s
.export cbdos_init

; parser.s
.import parse_cbmdos_filename, create_unix_path, unix_path, buffer, overwrite_flag
.import find_wildcards
.import file_mode, buffer_len, buffer_overflow
.import r1s, r1e

; functions.s
.import medium, soft_check_medium_a

.include "banks.inc"

;.include "common.inc"
IMPORTED_FROM_MAIN=1

.feature labels_without_colons

.include "fat32/fat32.inc"
.include "fcntl.inc"
;.include "65c02.inc"

.include "fat32/regs.inc"


ieee_status = status

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

; Commodore DOS variables
initialized:
	.byte 0
MAGIC_INITIALIZED  = $7A
listen_cmd:
	.byte 0
channel:
	.byte 0
is_receiving_filename:
	.byte 0

next_byte_for_channel:
	.res 16, 0
context_for_channel:
	.res 16, 0
CONTEXT_NONE = $ff
CONTEXT_DIR  = $fd
mode_for_channel:
	.res 16, 0
; $80 write
; $40 read

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
	phx
	phy

	ldx #14
	lda #CONTEXT_NONE
:	sta context_for_channel,x
	dex
	bpl :-

	lda #$73
	jsr set_status

	; TODO error handling
	jsr fat32_init

	ply
	plx
	rts

;---------------------------------------------------------------
; Detect SD card
;
; Returns Z=1 if SD card is present
;---------------------------------------------------------------
cbdos_sdcard_detect:
	BANKING_START
	jsr cbdos_init

	; re-init the SD card
	; * first write back any dirty sectors
	jsr sync_sector_buffer
	; * then init it
	jsr sdcard_init

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
	phx
	phy

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

; special-case command channel:
; ignore OPEN/CLOSE
	cmp #15
	beq @secnd_rts

	stz is_receiving_filename

	lda listen_cmd
	cmp #$f0
	beq @secnd_open
	cmp #$e0
	bne @secnd_rts

;---------------------------------------------------------------
; CLOSE
	ldx channel
	lda context_for_channel,x
	bmi @secnd_rts

@close_file:
	pha
	jsr fat32_close
	bcs :+
	jsr set_errno_status
:	pla
	jsr fat32_free_context
	ldx channel
	lda #CONTEXT_NONE
	sta context_for_channel,x
	stz mode_for_channel,x
	bra @secnd_rts

;---------------------------------------------------------------
; Initiate OPEN
@secnd_open:
	inc is_receiving_filename
	stz buffer_len

@secnd_rts:
	ply
	plx
	BANKING_END
	rts

;---------------------------------------------------------------
; CIOUT (send)
;---------------------------------------------------------------
cbdos_ciout:
	BANKING_START
	phx
	phy

	stz ieee_status

	ldx channel
	cpx #15
	beq @ciout_buffer

	ldx is_receiving_filename
	bne @ciout_buffer

	; ignore if channel is not for writing
	ldx channel
	bit mode_for_channel,x
	bpl @ciout_end

; write to file
	pha
	jsr fat32_write_byte
	bcs :+
	jsr set_errno_status
:	pla
	bcs @ciout_end

; write error
	lda #1
	sta ieee_status
	bra @ciout_end

@ciout_buffer:
	ldx buffer_len
	sta buffer,x
	inc buffer_len
	bne :+
	inc buffer_overflow
:

@ciout_end:
	clc
	ply
	plx
	BANKING_END
	rts

;---------------------------------------------------------------
; UNLISTEN
;---------------------------------------------------------------
cbdos_unlsn:
	BANKING_START
	phx
	phy

	lda buffer_overflow
	beq :+
	lda #$32
	jsr set_status
	bra @unlsn_end
:

; special-case command channel
	lda channel
	cmp #$0f
	beq @unlisten_cmdch

	lda listen_cmd
	cmp #$f0
	bne @unlsn_end; != OPEN? -> UNLISTEN does nothing

;---------------------------------------------------------------
; Execute OPEN with filename
	; XXX '$' only on channel 0!
	lda buffer
	cmp #'$'
	bne @unlsn_open_file

;---------------------------------------------------------------
; OPEN directory
	lda buffer_len ; filename length
	jsr open_dir
	bcc @open_ok

@open_err:
	lda #$02 ; timeout/file not found
	sta ieee_status
	bra @unlsn_end

@open_ok:
	lda #CONTEXT_DIR
	ldx channel
	sta context_for_channel,x
	bra @unlsn_end

;---------------------------------------------------------------
; OPEN file
@unlsn_open_file:
	jsr open_file
	bcs @open_err
	bra @unlsn_end

;---------------------------------------------------------------
; Execute Command
;
; UNLISTEN on command channel will ignore whether it was
; and OPEN command; it will always trigger command execution
@unlisten_cmdch:
	jsr execute_command

@unlsn_end:
	stz buffer_len
	stz buffer_overflow

	ply
	plx
	BANKING_END
	rts


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
	phx
	phy

	and #$0f
	sta channel

	tax
	lda context_for_channel,x
	; XXX test
	jsr fat32_set_context

	ply
	plx
	BANKING_END
	rts


;---------------------------------------------------------------
; RECEIVE
;---------------------------------------------------------------
cbdos_acptr:
	BANKING_START
	phx
	phy

	ldx channel
	cpx #15
	beq @acptr_status

	lda context_for_channel,x
	bpl @acptr_file ; actual file

	cmp #CONTEXT_DIR
	beq @acptr_dir

	; #CONTEXT_NONE
	lda #$02 ; timeout/file not found
	ora ieee_status
	sta ieee_status
	lda #0
	sec
	bra @acptr_end

@acptr_dir:
	jsr acptr_dir
	bra @acptr_eval

@acptr_status:
	jsr acptr_status
	bra @acptr_eval

@acptr_file:
	jsr acptr_file

@acptr_eval:
	bcc @acptr_end_neoi

	pha
	lda #$40 ; EOI
	ora ieee_status
	sta ieee_status
	pla
	bra @acptr_end2

@acptr_end_neoi:
	stz ieee_status
@acptr_end2:
	clc
@acptr_end:
	ply
	plx
	BANKING_END
	rts


acptr_file:
	; ignore if not open for writing
	bit mode_for_channel,x
	bvc @acptr_file_not_open

	jsr fat32_read_byte
	bcs @acptr_file_neof

	jsr set_errno_status

@acptr_file_not_open:
	; EOF
	ldx channel
	lda next_byte_for_channel,x
	sec
	rts

@acptr_file_neof:
	tay
	ldx channel
	lda next_byte_for_channel,x
	pha
	tya
	sta next_byte_for_channel,x
	pla
	clc
	rts



;---------------------------------------------------------------
; UNTALK
;---------------------------------------------------------------
cbdos_untlk:
	rts

;---------------------------------------------------------------
open_file:
	; XXX check if channel already open

	jsr fat32_alloc_context
	pha
	jsr fat32_set_context

	ldx #0
	ldy buffer_len
	jsr parse_cbmdos_filename
	bcc :+
	lda #$30 ; syntax error
	jmp @open_file_err
:	lda medium
	jsr soft_check_medium_a
	bcc :+
	lda #$74 ; drive not ready
	jmp @open_file_err
:
	lda r1s
	cmp r1e
	bne :+
	lda #$34 ; syntax error (empty filename)
	jmp @open_file_err
:
	ldy #0
	jsr create_unix_path
	lda #<unix_path
	sta fat32_ptr + 0
	lda #>unix_path
	sta fat32_ptr + 1

	; channels 0 and 1 are read and write
	lda channel
	beq @open_read
	cmp #1
	beq @open_write

	; otherwise check the mode
	lda file_mode
	cmp #'W'
	beq @open_write
	cmp #'A'
	beq @open_append
	; 'R', nonexistant and illegal modes -> read
	bra @open_read

@open_append:
	; TODO: This is blocked on the implementation of fat32_seek
	;       or fat32_open with an "append" option.
	lda #$31
	bra @open_file_err

	; open for writing
@open_write:
	jsr find_wildcards
	bcc :+
	lda #$33; syntax error (wildcards)
	bra @open_file_err
:	lda overwrite_flag
	bne @open_create
	jsr fat32_find_dirent
	bcc @1
	; exists, but don't overwrite
	lda #$63
	bra @open_file_err

@1:	lda fat32_errno
	beq @open_create
	jsr set_errno_status
	bra @open_file_err2

@open_create:
	jsr fat32_create
	bcs :+
	jsr set_errno_status
	bra @open_file_err2

:	ldx channel
	lda #$80 ; write
	sta mode_for_channel,x
	bra @open_file_ok

@open_read:
	jsr fat32_open
	bcs :+
	jsr set_errno_status
	bra @open_file_err2

:	ldx channel
	lda #$40 ; read
	sta mode_for_channel,x

	jsr fat32_read_byte
	bcs :+
	jsr set_errno_status
	lda #0 ; of EOF then make the only byte a 0

:	ldx channel
	sta next_byte_for_channel,x

@open_file_ok:
	pla ; context number
	sta context_for_channel,x
	lda #0
	jsr set_status
	clc
	rts

@open_file_err:
	jsr set_status
@open_file_err2:
	pla ; context number
	jsr fat32_free_context
	sec
	rts

;---------------------------------------------------------------
convert_errno_status:
	ldx fat32_errno
	lda status_from_errno,x
	rts

set_errno_status:
	jsr convert_errno_status
	jmp set_status

status_from_errno:
	.byte $00 ; ERRNO_OK               = 0  -> OK
	.byte $20 ; ERRNO_READ             = 1  -> READ ERROR
	.byte $25 ; ERRNO_WRITE            = 2  -> WRITE ERROR
	.byte $33 ; ERRNO_ILLEGAL_FILENAME = 3  -> SYNTAX ERROR
	.byte $63 ; ERRNO_FILE_EXISTS      = 4  -> FILE EXISTS
	.byte $62 ; ERRNO_FILE_NOT_FOUND   = 5  -> FILE NOT FOUND
	.byte $26 ; ERRNO_FILE_READ_ONLY   = 6  -> WRITE PROTECT ON
	.byte $63 ; ERRNO_DIR_NOT_EMPTY    = 7  -> FILE EXISTS (XXX)
	.byte $74 ; ERRNO_NO_MEDIA         = 8  -> DRIVE NOT READY
	.byte $74 ; ERRNO_NO_FS            = 9  -> DRIVE NOT READY
	.byte $71 ; ERRNO_FS_INCONSISTENT  = 10 -> DIRECTORY ERROR
	.byte $26 ; ERRNO_WRITE_PROTECT_ON = 11 -> WRITE PROTECT ON

.segment "IRQB"
	.word banked_irq
