
.import sdcard_init

.import fat32_init
.import fat32_dirent
.import sync_sector_buffer

.importzp krn_ptr1, read_blkptr, buffer, bank_save

; cmdch.s
.import ciout_cmdch, execute_command, set_status, acptr_status

; dir.s
.import open_dir, acptr_dir

; geos.s
.import cbmdos_GetNxtDirEntry, cbmdos_Get1stDirEntry, cbmdos_CalcBlksFree, cbmdos_GetDirHead, cbmdos_ReadBlock, cbmdos_ReadBuff, cbmdos_OpenDisk

.include "banks.inc"

;.include "common.inc"
IMPORTED_FROM_MAIN=1

.feature labels_without_colons

.include "fat32/fat32.inc"
.include "fcntl.inc"
;.include "65c02.inc"

.include "fat32/regs.inc"

MAX_FILENAME_LEN = 40

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

fnbuffer:
	.res MAX_FILENAME_LEN, 0

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
fnbuffer_w:
	.byte 0

next_byte_for_channel:
	.res 16, 0
context_for_channel:
	.res 16, 0
MAGIC_FD_NONE     = $ff
MAGIC_FD_STATUS   = $fe
MAGIC_FD_DIR_LOAD = $fd


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
	lda #MAGIC_FD_NONE
:	sta context_for_channel,x
	dex
	bpl :-

	lda #$73
	jsr set_status

	jsr fat32_init
	; XXX error

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
	pla
	jsr fat32_free_context
	ldx channel
	lda #MAGIC_FD_NONE
	sta context_for_channel,x
	bra @secnd_rts

;---------------------------------------------------------------
; Initiate OPEN
@secnd_open:
	inc is_receiving_filename
	stz fnbuffer_w

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

	ldx #0
	stx ieee_status

	ldx channel
	cpx #15
	beq @ciout_cmdch

	ldx is_receiving_filename
	bne @ciout_filename

	; ignore writing to read channels
	ldx channel
	beq @ciout_end
	cpx #2
	bcs @ciout_end

; write to file
	pha
	jsr fat32_write_byte
	pla
	bcs @ciout_end

; write error
	ldx #$26 ; XXX different error!
	jsr set_status
	lda #1
	sta ieee_status
	bra @ciout_end

@ciout_filename:
	ldx fnbuffer_w
	cpx #MAX_FILENAME_LEN
	bcs @ciout_end ; ignore characters on overflow
	sta fnbuffer,x
	inc fnbuffer_w
	bra @ciout_end

@ciout_cmdch:
	jsr ciout_cmdch

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

; special-case command channel
	lda channel
	cmp #$0f
	beq @unlisten_cmdch

	lda listen_cmd
	cmp #$f0
	bne @unlsn_end; != OPEN? -> UNLISTEN does nothing

;---------------------------------------------------------------
; Execute OPEN with filename
; XXX only on channel 0!
	lda fnbuffer
	cmp #'$'
	bne @unlsn_open_file

;---------------------------------------------------------------
; OPEN directory
	jsr open_dir
	bcc @open_ok

@open_err:
	lda #$02 ; timeout/file not found
	sta ieee_status
	bra @unlsn_end

@open_ok:
	lda #MAGIC_FD_DIR_LOAD
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

	cmp #MAGIC_FD_DIR_LOAD
	beq @acptr_dir

	; #MAGIC_FD_NONE
	lda #$02 ; timeout/file not found

@acptr_error:
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
	stz ieee_status
	bcc @acptr_end_neoi

	ldx #$40 ; EOI
	stx ieee_status

@acptr_end_neoi:
	clc
@acptr_end:
	ply
	plx
	BANKING_END
	rts


acptr_file:
	jsr fat32_read_byte
	bcs @acptr_file_neof

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

	ldx fnbuffer_w
	stz fnbuffer,x ; zero-terminate filename
	lda #<fnbuffer
	sta fat32_ptr + 0
	lda #>fnbuffer
	sta fat32_ptr + 1

	lda channel
	beq @open_read
	cmp #2
	bcs @open_read ; XXX parse ",t,R"/",t,W"/",t,A"

; create
	; XXX file exists?
	jsr fat32_create
	bcc @open_file_err
	ldx channel
	bra @open_file_cont

@open_read:
	jsr fat32_open
	bcc @open_file_err

	jsr fat32_read_byte
	bcs :+
	lda #0 ; of EOF then make the only byte a 0

:	ldx channel
	sta next_byte_for_channel,x

@open_file_cont:
	pla ; context number
	sta context_for_channel,x
	rts

@open_file_err:
	pla ; context number
	jsr fat32_free_context
	sec
	rts

.segment "IRQB"
	.word banked_irq
