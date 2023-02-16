;----------------------------------------------------------------------
; CMDR-DOS Main
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "fat32/fat32.inc"
.include "fat32/sdcard.inc"

.import sdcard_init

.import fat32_init
.import sync_sector_buffer
.importzp bank_save

; cmdch.s
.import cmdch_exec, set_status, cmdch_read

; dir.s
.import dir_open, dir_close, dir_read

; functions.s
.export dos_init, dos_unit, disk_changed
.import cur_medium

; parser.s
.import buffer
.import buffer_len, buffer_overflow

; file.s
.export channel, context_for_channel, ieee_status

; match.s
.import skip_mask

; jumptab.s
.export dos_secnd, dos_tksa, dos_acptr, dos_ciout, dos_untlk, dos_unlsn, dos_listn, dos_talk, dos_macptr
.export dos_set_time

.include "banks.inc"

.include "file.inc"

ieee_status = status

ram_bank   = 0

.macro BANKING_START
	pha
	lda ram_bank
	sta bank_save
	stz ram_bank
	pla
.endmacro

.macro BANKING_END
	pha
	lda bank_save
	sta ram_bank
	pla
.endmacro

.bss

; Commodore DOS variables
dos_unit:
	.byte 0
no_sdcard_active: ; $00: SD card active; $80: no SD card active
	.byte 0
listen_cmd:
	.byte 0
channel:
	.byte 0
cur_context:
	.byte 0
is_receiving_filename:
	.byte 0
disk_changed:
	.byte 0

context_for_channel:
	.res 16, 0
CONTEXT_NONE = $ff
CONTEXT_DIR  = $fe
CONTEXT_CMD  = $fd

.code

;---------------------------------------------------------------
; Initialize CMDR-DOS
;
; This is called once on a system RESET.
;---------------------------------------------------------------
dos_init:
	BANKING_START
	lda #8
	sta dos_unit
	; SD card needs detection and init
	lda #$80
	sta no_sdcard_active
	; SD card detection will trigger a call to reset_dos

	lda #$73
	jsr set_status

	BANKING_END
	rts

;---------------------------------------------------------------
; sdcard_check
;
; This is called by every TALK and LISTEN:
; * If there is an active SD card, verify it is still present.
;   If no, try to detect one.
; * If there is no active SD card, try to detect one.
;
; Out:  c  =0: OK
;          =1: device not present
;---------------------------------------------------------------
sdcard_check:
	BANKING_START

	cmp dos_unit
	beq @1
	sec
	rts

@1:	bit no_sdcard_active
	bmi @not_active

	; SD card was there - make sure it is still there
	jsr sdcard_check_alive; cheap, not state destructive
	bcs @yes

@not_active:
	lda #1
	sta disk_changed
	; no SD card was there - maybe there is now, so
	; try to init it
	jsr sdcard_init ; expensive, state destructive
	bcc @no

	jsr reset_dos

@yes:	lda #0
	bra @end
@no:	lda #$80
@end:	sta no_sdcard_active
	asl
	BANKING_END
	rts

;---------------------------------------------------------------
; reset_dos
;
; Reset CMDR-DOS after a new SD card has been inserted
;
; Whenever an SD card is inserted, all state is cleared.
; The status messages is preserved.
;---------------------------------------------------------------
reset_dos:
	ldx #14
	lda #CONTEXT_NONE
:	sta context_for_channel,x
	dex
	bpl :-
	lda #CONTEXT_CMD
	sta context_for_channel + 15

	stz buffer_overflow
	stz buffer_len
	stz disk_changed
	stz skip_mask

	jsr fat32_init

	lda #1
	sta cur_medium

	rts

;---------------------------------------------------------------
; dos_set_time
;---------------------------------------------------------------
dos_set_time:
	BANKING_START
	lda 2
	sta fat32_time_year
	lda 3
	sta fat32_time_month
	lda 4
	sta fat32_time_day
	lda 5
	sta fat32_time_hours
	lda 6
	sta fat32_time_minutes
	lda 7
	sta fat32_time_seconds
	BANKING_END
	rts

;---------------------------------------------------------------
; LISTEN
;
; Nothing to do.
;---------------------------------------------------------------
dos_listn:
	jmp sdcard_check

;---------------------------------------------------------------
; SECOND (after LISTEN)
;
;   In:   a    secondary address
;---------------------------------------------------------------
dos_secnd:
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
	bne :+
	stz ieee_status
	bra @secnd_rts
:
	stz is_receiving_filename

	lda listen_cmd
	cmp #$f0
	beq @secnd_open
	cmp #$e0
	beq @second_close

; switch to context
	jsr file_second2
	bra @secnd_rts

;---------------------------------------------------------------
; CLOSE
@second_close:
	ldx channel
	lda context_for_channel,x
	cmp #CONTEXT_DIR
	bne :+
	jsr dir_close
:	jsr file_close_clr_channel
	bra @secnd_rts

;---------------------------------------------------------------
; Initiate OPEN
@secnd_open:
	inc is_receiving_filename
	stz buffer_len
	stz buffer_overflow

@secnd_rts:
	ply
	plx
	BANKING_END
	rts

;---------------------------------------------------------------
; CIOUT (send)
;---------------------------------------------------------------
dos_ciout:
	BANKING_START
	phx
	phy

	stz ieee_status

	ldx channel
	cpx #15
	beq @ciout_buffer

	ldx is_receiving_filename
	bne @ciout_buffer

	jsr file_write
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
dos_unlsn:
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
	cmp #15
	beq @unlisten_cmdch

	lda listen_cmd
	cmp #$f0
	bne @unlsn_end; != OPEN? -> UNLISTEN does nothing

	jsr file_close_clr_channel

;---------------------------------------------------------------
; Execute OPEN with filename
	lda buffer
	cmp #'$'
	bne @unlsn_open_file
	lda channel
	bne @unlsn_open_file ; only on channel 0

;---------------------------------------------------------------
; OPEN directory
	lda buffer_len ; filename length
	jsr dir_open
	bcs @unlsn_end

	lda #CONTEXT_DIR
	ldx channel
	sta context_for_channel,x
	bra @unlsn_end

;---------------------------------------------------------------
; OPEN file
@unlsn_open_file:
	jsr file_open
	bcs @unlsn_end
	ldx channel
	sta context_for_channel,x
	bra @unlsn_end

;---------------------------------------------------------------
; Execute Command
;
; UNLISTEN on command channel will ignore whether it was
; and OPEN command; it will always trigger command execution
@unlisten_cmdch:
	jsr cmdch_exec

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
dos_talk:
	jmp sdcard_check


;---------------------------------------------------------------
; SECOND (after TALK)
;---------------------------------------------------------------
dos_tksa: ; after talk
	BANKING_START
	phx
	phy

	and #$0f
	sta channel

	jsr file_second2


	ply
	plx
	BANKING_END
	rts

;---------------------------------------------------------------
file_second2:
	ldx channel
	lda context_for_channel,x
	sta cur_context
	bmi @2 ; not a file context
	jmp file_second
@2:	rts

;---------------------------------------------------------------
; RECEIVE
;---------------------------------------------------------------
dos_acptr:
	BANKING_START
	phx
	phy

	lda cur_context
	bmi @nacptr_file

;---------------------------------------------------------------
; *** FILE
	jsr file_read
	bcs @acptr_end_file_eoi
@acptr_end_ok:
	stz ieee_status
@acptr_end:
	clc
	ply
	plx
	BANKING_END
	rts

@nacptr_file:
	cmp #CONTEXT_CMD
	bne @nacptr_status

;---------------------------------------------------------------
; *** STATUS
	jsr cmdch_read

@acptr_eval:
	bcc @acptr_end_ok
	bra @acptr_eoi

@nacptr_status:
	cmp #CONTEXT_DIR
	bne @acptr_none

;---------------------------------------------------------------
; *** DIR
	jsr dir_read
	bra @acptr_eval

;---------------------------------------------------------------
; *** NONE
@acptr_none:
	; #CONTEXT_NONE
	lda #$42 ; EOI + timeout/file not found
	ora ieee_status
	sta ieee_status
	lda #199
	bra @acptr_end


@acptr_end_file_eoi:
	pha ; data byte
	jsr file_close_clr_channel
	pla
@acptr_eoi:
	pha
	lda #$40 ; EOI
	ora ieee_status
	sta ieee_status
	pla ; data byte
	bra @acptr_end

;---------------------------------------------------------------
file_close_clr_channel:
	ldx channel
	lda context_for_channel,x
	bmi @1
	jsr file_close
@1:	ldx channel
	lda #CONTEXT_NONE
	sta context_for_channel,x
	rts

;---------------------------------------------------------------
; UNTALK
;---------------------------------------------------------------
dos_untlk:
	rts

;---------------------------------------------------------------
; BLOCK-WISE RECEIVE
;
; In:   y:x  pointer to data
;       a    number of bytes to read
;            =0: implementation decides; up to 512
; Out:  y:x  number of bytes read
;       c    =1: unsupported
;       (EOI flag in ieee_status)
;---------------------------------------------------------------
dos_macptr:
	BANKING_START
	bit cur_context
	bmi @1

	stz ieee_status

	jsr file_read_block ; read up to 256 bytes
	bcc @end

	phx
	phy
	jsr file_close_clr_channel
	lda #$40 ; EOI
	ora ieee_status
	sta ieee_status
	clc
	ply
	plx

@end:
	BANKING_END
	rts


@1:	sec ; error: unsupported
	bra @end


;---------------------------------------------------------------
.segment "IRQB"
	.word banked_nmi
	.word $ffff
	.word banked_irq

