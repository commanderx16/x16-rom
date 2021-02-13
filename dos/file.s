;----------------------------------------------------------------------
; CMDR-DOS File Handling
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "fat32/fat32.inc"
.include "fat32/regs.inc"
.include "file.inc"

; cmdch.s
.import set_status

; parser.s
.import find_wildcards
.import file_type, file_mode
.import unix_path
.import create_unix_path
.import medium
.import parse_dos_filename
.import buffer_len
.import is_filename_empty
.import overwrite_flag

; main.s
.import channel
.import ieee_status

; functions.s
.import alloc_context, free_context
.export file_set_position

.bss

cur_mode:           ; for current channel
	.byte 0

mode_for_channel:   ; =$80: write
	.res 16, 0  ; =$40: read

.code

;---------------------------------------------------------------
; In:  a  context
;---------------------------------------------------------------
file_second:
	stz ieee_status
	jsr fat32_set_context
	ldx channel
	lda mode_for_channel,x
	sta cur_mode
	rts

;---------------------------------------------------------------
; In:  channel       channel
;      0->buffer_len filename
;---------------------------------------------------------------
file_open:
	ldx #0
	ldy buffer_len
	jsr parse_dos_filename
	bcc :+
	lda #$30 ; syntax error
	jmp @open_file_err3
:	jsr is_filename_empty
	bne :+
	lda #$34 ; syntax error (empty filename)
	jmp @open_file_err3
:
	; type and mode defaults
	lda file_type
	bne :+
	lda #'S'
	sta file_type
:	lda file_mode
	bne :+
	lda #'R'
	sta file_mode
:
	jsr alloc_context
	bcs @alloc_ok

	jsr convert_errno_status
	sec
	rts

@alloc_ok:
	pha
	jsr fat32_set_context

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
	cmp #'M'
	; 'R', nonexistant and illegal modes -> read
	bne @open_read

; *** M - open for modify (read/write)
	; try opening existing file
	jsr fat32_open
	bcs :+
	lda fat32_errno
	cmp #ERRNO_FILE_NOT_FOUND
	bne @open_file_err2
	; otherwise create file - wildcards are not ok
	jsr find_wildcards
	bcs @open_file_err_wilcards
	jsr fat32_create
	bcc @open_file_err2

:	lda #$c0 ; read & write
	bra @open_set_mode

; *** A - open for appending
@open_append:
	; wildcards are ok
	jsr fat32_open
	bcc @open_file_err2

:	lda #$ff ; seek to end of file
	sta fat32_size + 0
	sta fat32_size + 1
	sta fat32_size + 2
	sta fat32_size + 3
	jsr fat32_seek
	bcc @open_file_err2
	bra @open_set_mode_write

; *** W - open for writing
@open_write:
	jsr find_wildcards
	bcs @open_file_err_wilcards
	lda overwrite_flag
	lsr
	jsr fat32_create
	bcc @open_file_err2

@open_set_mode_write:
	lda #$80 ; write
	bra @open_set_mode

; *** R - open for reading
@open_read:
	jsr fat32_open
	bcc @open_file_err2

:	lda #$40 ; read
@open_set_mode:
	ldx channel
	sta mode_for_channel,x

@open_file_ok:
	lda #0
	jsr set_status
	pla ; context number
	clc
	rts

@open_file_err2:
	jsr set_errno_status
	bra :+
@open_file_err_wilcards:
	lda #$33; syntax error (wildcards)
@open_file_err:
	jsr set_status
:	pla ; context number
	jsr free_context
	sec
	rts

@open_file_err3:
	jsr set_status
	jsr free_context
	sec
	rts

;---------------------------------------------------------------
; file_close
;
; In:   a   context
;---------------------------------------------------------------
file_close:
	pha
	jsr fat32_set_context

	jsr fat32_close
	bcs :+
	jsr set_errno_status
:	pla
	jsr free_context
	ldx channel
	stz mode_for_channel,x
	stz cur_mode
	rts

;---------------------------------------------------------------
; file_read
;
; Read one byte from the current context.
;
; Out:  a  byte
;       c  =1: EOI
;---------------------------------------------------------------
file_read:
	bit cur_mode
	bvc @acptr_file_not_open

	jsr fat32_read_byte
	bcc @acptr_file_error

	tay
	txa ; x==$ff is EOF after this byte, which is the
	lsr ; same as EOI *now*, so move LSB into C
	tya
	rts

@acptr_file_error:
	jsr set_errno_status

@acptr_file_not_open:
	sec
	rts

;---------------------------------------------------------------
; file_read_block
;
; Read up to 256 bytes from the current context. The
; implementation is free to return any number of bytes,
; optimizing for speed and simplicity.
; We always read to the end of the next 256 byte page in the
; file to reduce the amount of work in fat32_read a bit.
;
; In:   y:x  pointer to data
;       a    number of bytes to read
;            =0: implementation decides; up to 512
; Out:  y:x  number of bytes read
;       c    =1: error or EOF (no bytes received)
;---------------------------------------------------------------
file_read_block:
	stx fat32_ptr
	sty fat32_ptr + 1
	tax
	bne @1

	; A=0: read to end of 512-byte sector
	jsr fat32_get_offset
	lda #0
	sec
	sbc fat32_size + 0
	sta fat32_size + 0

	lda fat32_size + 1
	and #1
	sta fat32_size + 1

	lda #2
	sbc fat32_size + 1
	sta fat32_size + 1
	bra @2

	; A!=0: read A bytes
@1:	sta fat32_size + 0
	stz fat32_size + 1

	; Read
@2:	jsr fat32_read
	bcc @eoi_or_error

	clc
@end:	ldx fat32_size + 0
	ldy fat32_size + 1
	rts

@eoi_or_error:
	lda fat32_errno
	beq @eoi

; EOF or error, no data received
	jsr set_errno_status
	ldx #0
	ldy #0
	sec
	rts

@eoi:	sec
	bra @end

;---------------------------------------------------------------
file_write:
	bit cur_mode
	bpl @ciout_not_present

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

@ciout_not_present:
	lda #128 ; device not present
	sta ieee_status
@ciout_end:
	rts

;---------------------------------------------------------------
; file_set_position
;
; In:   a    context
;       x/y  structure that contains
;              offset 0  offset[0:7]
;              offset 1  offset[8:15]
;              offset 2  offset[16:23]
;              offset 3  offset[24:31]
;---------------------------------------------------------------
file_set_position:
	stx fat32_ptr
	sty fat32_ptr + 1
	tax
	bmi @error ; not a file context
	jsr fat32_set_context

	lda (fat32_ptr)
	sta fat32_size + 0
	ldy #1
	lda (fat32_ptr),y
	sta fat32_size + 1
	iny
	lda (fat32_ptr),y
	sta fat32_size + 2
	iny
	lda (fat32_ptr),y
	sta fat32_size + 3
	jsr fat32_seek
	bcc @error
	clc
	rts

@error:	sec
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
	.byte $ff ; ERRNO_DIR_NOT_EMPTY    = 7  -> (not used)
	.byte $74 ; ERRNO_NO_MEDIA         = 8  -> DRIVE NOT READY
	.byte $74 ; ERRNO_NO_FS            = 9  -> DRIVE NOT READY
	.byte $71 ; ERRNO_FS_INCONSISTENT  = 10 -> DIRECTORY ERROR
	.byte $26 ; ERRNO_WRITE_PROTECT_ON = 11 -> WRITE PROTECT ON
	.byte $70 ; ERRNO_OUT_OF_RESOURCES = 12 -> NO CHANNEL


