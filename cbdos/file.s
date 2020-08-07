;----------------------------------------------------------------------
; CBDOS File Handling
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
.import parse_cbmdos_filename
.import buffer_len
.import is_filename_empty
.import overwrite_flag

; main.s
.import context_for_channel
.import channel
.import ieee_status

; functions.s
.import alloc_context

.bss

next_byte_for_channel:
	.res 16, 0
mode_for_channel:
	.res 16, 0
; $80 write
; $40 read

.code

;---------------------------------------------------------------
file_second:
	ldx channel
	lda context_for_channel,x
	bmi @1 ; not a file context
	jmp fat32_set_context
@1:	rts

;---------------------------------------------------------------
file_open:
	ldx #0
	ldy buffer_len
	jsr parse_cbmdos_filename
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

	jmp convert_errno_status

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
	lsr
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
	lda #0 ; if EOF then make the only byte a 0

:	ldx channel
	sta next_byte_for_channel,x

@open_file_ok:
	pla ; context number
	sta context_for_channel,x
	lda #0
	jsr set_status
	rts

@open_file_err:
	jsr set_status
@open_file_err2:
	pla ; context number
	jmp fat32_free_context

@open_file_err3:
	jsr set_status
	jmp fat32_free_context

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
	jsr fat32_free_context
	ldx channel
	stz mode_for_channel,x
	rts


;---------------------------------------------------------------
file_read:
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
file_write:
	; ignore if channel is not for writing
	ldx channel
	bit mode_for_channel,x
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


