;-----------------------------------------------------------------------------
; sdcard.s
; Copyright (C) 2020 Frank van den Hoef
;-----------------------------------------------------------------------------

	.include "lib.inc"
	.include "sdcard.inc"
	.include "spi.inc"

	.export sector_buffer, sector_buffer_end, sector_lba

	.import spi_ctrl, spi_read, spi_write, spi_select, spi_deselect, spi_read_sector, spi_write_sector

	.bss
cmd_idx = sdcard_param
cmd_arg = sdcard_param + 1
cmd_crc = sdcard_param + 5

sector_buffer:
	.res 512
sector_buffer_end:

sdcard_param:
	.res 1
sector_lba:
	.res 4 ; dword (part of sdcard_param) - LBA of sector to read/write
	.res 1

timeout_cnt:       .byte 0

	.code

;-----------------------------------------------------------------------------
; wait ready
;
; clobbers: A,X,Y
;-----------------------------------------------------------------------------
wait_ready:
	lda #2
	sta timeout_cnt

@1:	ldx #0		; 2
@2:	ldy #0		; 2
@3:	jsr spi_read	; 22
	cmp #$FF	; 2
	beq @done	; 2 + 1
	dey		; 2
	bne @3		; 2 + 1
	dex		; 2
	bne @2		; 2 + 1
	dec timeout_cnt
	bne @1

	; Total timeout: ~508 ms @ 8MHz

	; Timeout error
	clc
	rts

@done:	sec
	rts


;-----------------------------------------------------------------------------
; send_cmd - Send cmdbuf
;
; first byte of result in A, clobbers: Y
;-----------------------------------------------------------------------------
send_cmd:
	; Make sure card is deselected
	jsr spi_deselect

	; Select card
	jsr spi_select

	jsr wait_ready
	bcc @error

	; Send the 6 cmdbuf bytes
	lda cmd_idx
	jsr spi_write
	lda cmd_arg + 3
	jsr spi_write
	lda cmd_arg + 2
	jsr spi_write
	lda cmd_arg + 1
	jsr spi_write
	lda cmd_arg + 0
	jsr spi_write
	lda cmd_crc
	jsr spi_write

	; Wait for response
	ldy #(10 + 1)
@1:	dey
	beq @error	; Out of retries
	jsr spi_read
	bit #$80
	bne @1

	; Success
	sec
	rts

@error:	; Error
	jsr spi_deselect
	clc
	rts

;-----------------------------------------------------------------------------
; send_cmd_inline - send command with specified argument
;-----------------------------------------------------------------------------
.macro send_cmd_inline cmd, arg
	lda #(cmd | $40)
	sta cmd_idx

.if .hibyte(.hiword(arg)) = 0
	stz cmd_arg + 3
.else
	lda #(.hibyte(.hiword(arg)))
	sta cmd_arg + 3
.endif

.if ^arg = 0
	stz cmd_arg + 2
.else
	lda #^arg
	sta cmd_arg + 2
.endif

.if >arg = 0
	stz cmd_arg + 1
.else
	lda #>arg
	sta cmd_arg + 1
.endif

.if <arg = 0
	stz cmd_arg + 0
.else
	lda #<arg
	sta cmd_arg + 0
.endif

.if cmd = 0
	lda #$95
.else
.if cmd = 8
	lda #$87
.else
	lda #1
.endif
.endif
	sta cmd_crc
	jsr send_cmd
.endmacro

;-----------------------------------------------------------------------------
; sdcard_init
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
sdcard_init:
	; Deselect card and set slow speed (< 400kHz)
	lda #SPI_CTRL_SLOWCLK
	jsr spi_ctrl

	; Generate at least 74 SPI clock cycles with device deselected
	ldx #10
@1:	jsr spi_read
	dex
	bne @1

	; Enter idle state
	send_cmd_inline 0, 0
	bcs @2
	jmp @error
@2:
	cmp #1	; In idle state?
	beq @3
	jmp @error
@3:
	; SDv2? (SDHC/SDXC)
	send_cmd_inline 8, $1AA
	bcs @4
	jmp @error
@4:
	cmp #1	; No error?
	beq @5
	jmp @error
@5:
@sdv2:	; Receive remaining 4 bytes of R7 response
	jsr spi_read
	jsr spi_read
	jsr spi_read
	jsr spi_read

	; Wait for card to leave idle state
@6:	send_cmd_inline 55, 0
	bcs @7
	bra @error
@7:
	send_cmd_inline 41, $40000000
	bcs @8
	bra @error
@8:
	cmp #0
	bne @6

	; Check CCS bit in OCR register
	send_cmd_inline 58, 0
	cmp #0
	jsr spi_read
	and #$40	; Check if this card supports block addressing mode
	beq @error
	jsr spi_read
	jsr spi_read
	jsr spi_read

	; Select full speed
	jsr spi_deselect
	lda #0
	jsr spi_ctrl

	; Success
	sec
	rts

@error:	jsr spi_deselect

	; Error
	clc
	rts


;-----------------------------------------------------------------------------
; sdcard_read_sector
; Set sector_lba prior to calling this function.
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
sdcard_read_sector:
	; Send READ_SINGLE_BLOCK command
	lda #($40 | 17)
	sta cmd_idx
	lda #1
	sta cmd_crc
	jsr send_cmd

	; Wait for start of data packet
	ldx #0
@1:	ldy #0
@2:	jsr spi_read
	cmp #$FE
	beq @start
	dey
	bne @2
	dex
	bne @1

	; Timeout error
	jsr spi_deselect
	clc
	rts

@start:	jsr spi_read_sector		; fast read of 512 bytes into sector_buffer

	; Success
	jsr spi_deselect
	sec
	rts

;-----------------------------------------------------------------------------
; sdcard_write_sector
; Set sector_lba prior to calling this function.
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
sdcard_write_sector:
	; Send WRITE_BLOCK command
	lda #($40 | 24)
	sta cmd_idx
	lda #1
	sta cmd_crc
	jsr send_cmd
	cmp #00
	bne @error

	; Wait for card to be ready
	jsr wait_ready
	bcc @error

	; Send start of data token
	lda #$FE
	jsr spi_write

	jsr spi_write_sector

	; Dummy CRC
	lda #0
	jsr spi_write
	jsr spi_write

	; Success
	jsr spi_deselect
	sec
	rts

@error:	; Error
	jsr spi_deselect
	clc
	rts

;-----------------------------------------------------------------------------
; sdcard_check_alive
;
; Check whether the current SD card is still present, or whether it has been
; removed or replaced with a different card.
;
; Out:  c  =1: SD card is alive
;          =0: SD card has been removed, or replaced with a different card
;
; The SEND_STATUS command (CMD13) sends 16 error bits:
;  byte 0: 7  always 0
;          6  parameter error
;          5  address error
;          4  erase sequence error
;          3  com crc error
;          2  illegal command
;          1  erase reset
;          0  in idle state
;  byte 1: 7  out of range | csd overwrite
;          6  erase param
;          5  wp violation
;          4  card ecc failed
;          3  CC error
;          2  error
;          1  wp erase skip | lock/unlock cmd failed
;          0  Card is locked
; Under normal circumstances, all 16 bits should be zero.
; This command is not legal before the SD card has been initialized.
; Tests on several cards have shown that this gets respected in practice;
; the test cards all returned $1F, $FF if sent before CMD0.
; So we use CMD13 to detect whether we are still talking to the same SD
; card, or a new card has been attached.
;-----------------------------------------------------------------------------
sdcard_check_alive:
	; save sector
	ldx #0
@1:	lda sector_lba, x
	pha
	inx
	cpx #4
	bne @1

	send_cmd_inline 13, 0 ; CMD13: SEND_STATUS
	bcc @no ; card did not react -> no card
	tax
	bne @no ; first byte not $00 -> different card
	jsr spi_read
	tax
	bne @no ; second byte not $00 -> different card
	sec
	bra @yes

@no:	clc

@yes:	; restore sector
	; (this code preserves the C flag!)
	ldx #3
@2:	pla
	sta sector_lba, x
	dex
	bpl @2

	php
	jsr spi_deselect
	plp
	rts
