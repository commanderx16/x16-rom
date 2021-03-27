;-----------------------------------------------------------------------------
; sdcard.s
; Copyright (C) 2020 Frank van den Hoef
;-----------------------------------------------------------------------------

	.include "lib.inc"
	.include "sdcard.inc"

	.export sector_buffer, sector_buffer_end, sector_lba

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

; XXX disabled for now; on real hardware, this returns
; XXX all 0xFE bytes with all tested SD cards
;FAST_READ=1
;FAST_WRITE=1

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
; deselect card
;
; clobbers: A
;-----------------------------------------------------------------------------
deselect:
	lda SPI_CTRL
	and #(SPI_CTRL_SELECT_MASK ^ $FF)
	sta SPI_CTRL

	jmp spi_read

;-----------------------------------------------------------------------------
; select card
;
; clobbers: A,X,Y
;-----------------------------------------------------------------------------
select:	lda SPI_CTRL
	ora #SPI_CTRL_SELECT_SDCARD
	sta SPI_CTRL

	jsr spi_read
	jsr wait_ready
	bcc @error
	rts

@error:	jsr deselect
	clc
	rts

;-----------------------------------------------------------------------------
; spi_read
;
; result in A
;-----------------------------------------------------------------------------
spi_read:
	lda #$FF	; 2
	sta SPI_DATA	; 4
@1:	bit SPI_CTRL	; 4
	bmi @1		; 2 + 1 if branch
	lda SPI_DATA	; 4
	rts		; 6
			; >= 22 cycles

.macro spi_read_macro
	.local @1
	lda #$FF	; 2
	sta SPI_DATA	; 4
@1:	bit SPI_CTRL	; 4
	bmi l1		; 2 + 1 if branch
	lda SPI_DATA	; 4
.endmacro

;-----------------------------------------------------------------------------
; spi_write
;
; byte to write in A
;-----------------------------------------------------------------------------
spi_write:
	sta SPI_DATA
@1:	bit SPI_CTRL
	bmi @1
	rts

.macro spi_write_macro
	.local @1
	sta SPI_DATA
@1:	bit SPI_CTRL
	bmi @1
.endmacro

;-----------------------------------------------------------------------------
; send_cmd - Send cmdbuf
;
; first byte of result in A, clobbers: Y
;-----------------------------------------------------------------------------
send_cmd:
	; Make sure card is deselected
	jsr deselect

	; Select card
	jsr select
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
	sta SPI_CTRL

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
	jsr deselect
	lda #0
	sta SPI_CTRL

	; Success
	sec
	rts

@error:	jsr deselect

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
	jsr deselect
	clc
	rts

.ifdef FAST_READ
@start:	; Enable auto-tx mode
	lda SPI_CTRL
	ora #SPI_CTRL_AUTOTX
	sta SPI_CTRL

	; Start first read transfer
	lda SPI_DATA			; Auto-tx
	ldy #0				; 2

	; Efficiently read first 256 bytes (hide SPI transfer time)
 	ldy #0				; 2
@3:	lda SPI_DATA			; 4
	sta sector_buffer + 0, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 1, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 2, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 3, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 4, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 5, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 6, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 7, y	; 5
	tya				; 2
	clc				; 2
	adc #8				; 2
	tay				; 2
	bne @3				; 2+1

	; Efficiently read second 256 bytes (hide SPI transfer time)
@4:	lda SPI_DATA			; 4
	sta sector_buffer + 256 + 0, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 256 + 1, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 256 + 2, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 256 + 3, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 256 + 4, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 256 + 5, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 256 + 6, y	; 5
	lda SPI_DATA			; 4
	sta sector_buffer + 256 + 7, y	; 5
	tya				; 2
	clc				; 2
	adc #8				; 2
	tay				; 2
	bne @4				; 2+1

	; Disable auto-tx mode
	lda SPI_CTRL
	and #(SPI_CTRL_AUTOTX ^ $FF)
	sta SPI_CTRL

	; Next read is now already done (first CRC byte), read second CRC byte
	jsr spi_read

.else
@start:	; Read 512 bytes of sector data
	ldx #$FF
	ldy #0
@3:	stx SPI_DATA		; 4
@4:	bit SPI_CTRL		; 4
	bmi @4			; 2 + 1 if branch

	lda SPI_DATA		; 4
	sta sector_buffer + 0, y
	iny
	bne @3

	; Y already 0 at this point
@5:	stx SPI_DATA		; 4
@6:	bit SPI_CTRL		; 4
	bmi @6			; 2 + 1 if branch
	lda SPI_DATA		; 4
	sta sector_buffer + 256, y
	iny
	bne @5

	; Read CRC bytes
	jsr spi_read
	jsr spi_read
.endif
	; Success
	jsr deselect
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

.ifdef FAST_WRITE
	; Send 512 bytes of sector data
	; NOTE: Direct access of SPI registers to speed up.
	;       Make sure 9 CPU clock cycles take longer than 640 ns (eg. CPU max 14MHz)
	ldy #0
@1:	lda sector_buffer, y		; 4
	sta SPI_DATA			; 4
	iny				; 2
	bne @1				; 2 + 1

	; Y already 0 at this point
@2:	lda sector_buffer + 256, y	; 4
	sta SPI_DATA			; 4
	iny				; 2
	bne @2				; 2 + 1
.else
	; Send 512 bytes of sector data
	ldy #0
@1:	lda sector_buffer, y		; 4
	spi_write_macro
	iny				; 2
	bne @1				; 2 + 1

	; Y already 0 at this point
@2:	lda sector_buffer + 256, y	; 4
	spi_write_macro
	iny				; 2
	bne @2				; 2 + 1
.endif
	; Dummy CRC
	lda #0
	jsr spi_write
	jsr spi_write

	; Success
	jsr deselect
	sec
	rts

@error:	; Error
	jsr deselect
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
	jsr deselect
	plp
	rts
