;----------------------------------------------------------------------
; CBDOS Main
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
.import dir_open, dir_read

; functions.s
.export cbdos_init, cbdos_unit
.import cur_medium

; parser.s
.import buffer
.import buffer_len, buffer_overflow

; file.s
.export channel, context_for_channel, ieee_status

; jumptab.s
.export cbdos_secnd, cbdos_tksa, cbdos_acptr, cbdos_ciout, cbdos_untlk, cbdos_unlsn, cbdos_listn, cbdos_talk
.export cbdos_set_time

.include "banks.inc"

.include "file.inc"

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
cbdos_unit:
	.byte 0
no_sdcard_active: ; $00: SD card active; $80: no SD card active
	.byte 0
listen_cmd:
	.byte 0
channel:
	.byte 0
is_receiving_filename:
	.byte 0

context_for_channel:
	.res 16, 0
CONTEXT_NONE = $ff
CONTEXT_DIR  = $fe

.segment "cbdos"

;---------------------------------------------------------------
; Initialize CBDOS
;
; This is called once on a system RESET.
;---------------------------------------------------------------
cbdos_init:
	BANKING_START
	lda #8
	sta cbdos_unit
	; SD card needs detection and init
	lda #$80
	sta no_sdcard_active
	; SD card detection will trigger a call to reset_dos
	BANKING_END
	rts

;---------------------------------------------------------------
; sdcard_check
;
; This is called by every TALK and LISTEN:
; * If there is an active SD card, verify it is still present.
; * If there is no active SD card, try to detect one.
;
; Out:  c  =0: OK
;          =1: device not present
;---------------------------------------------------------------
sdcard_check:
	BANKING_START

	cmp cbdos_unit
	beq @1
	sec
	rts

@1:	bit no_sdcard_active
	bmi @not_active

	; SD card was there - make sure it is still there
	jsr sdcard_check_alive; cheap, not state destructive
	bcs @yes
	bra @no

@not_active:
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
; Reset CBDOS after a new SD card has been inserted
;
; The SD card is considered a drive, not a medium. When there is
; no SD card, this is the equivalent of an IEEE layer timeout,
; not a "74,DRIVE NOT READY,00,00".
; Therefore, whenever an SD card is inserted, all of DOS is
; reset.
;---------------------------------------------------------------
reset_dos:
	ldx #14
	lda #CONTEXT_NONE
:	sta context_for_channel,x
	dex
	bpl :-

	lda #$73
	jsr set_status

	jsr fat32_init

	lda #1
	sta cur_medium

	rts

;---------------------------------------------------------------
; cbdos_set_time
;---------------------------------------------------------------
cbdos_set_time:
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
cbdos_listn:
	jmp sdcard_check

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
	jsr file_second
	bra @secnd_rts

;---------------------------------------------------------------
; CLOSE
@second_close:
	ldx channel
	lda context_for_channel,x
	bmi @secnd_rts

	jsr file_close_clr_channel
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
	ldx channel
	lda context_for_channel,x
	bmi @not_open

	jsr file_close

@not_open:
	jsr file_open
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
cbdos_talk:
	jmp sdcard_check


;---------------------------------------------------------------
; SECOND (after TALK)
;---------------------------------------------------------------
cbdos_tksa: ; after talk
	BANKING_START
	phx
	phy

	and #$0f
	sta channel

	jsr file_second

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

; *** NONE
	; #CONTEXT_NONE
	lda #$42 ; EOI + timeout/file not found
	ora ieee_status
	sta ieee_status
	lda #199
	bra @acptr_end

; *** FILE
@acptr_file:
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

@acptr_end_file_eoi:
	ldx channel
	ldy context_for_channel,x
	bmi @acptr_eoi

	pha ; data byte
	tya
	jsr file_close_clr_channel

@acptr_eoi:
	lda #$40 ; EOI
	ora ieee_status
	sta ieee_status
	pla ; data byte
	bra @acptr_end

@acptr_dir:
; *** DIR
	jsr dir_read
	bra @acptr_eval

; *** STATUS
@acptr_status:
	jsr cmdch_read

@acptr_eval:
	bcc @acptr_end_ok
	pha
	bra @acptr_eoi


;---------------------------------------------------------------
file_close_clr_channel:
	jsr file_close
	ldx channel
	lda #CONTEXT_NONE
	sta context_for_channel,x
	rts

;---------------------------------------------------------------
; UNTALK
;---------------------------------------------------------------
cbdos_untlk:
	rts

.segment "IRQB"
	.word banked_irq

