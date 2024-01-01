;-----------------------------------------------------------------------------
; spi.s
; Copyright (C) 2020 Frank van den Hoef
;-----------------------------------------------------------------------------

	.include "../vera.inc"
	.include "spi.inc"

	.import sector_buffer

	.export spi_ctrl, spi_read, spi_write, spi_select, spi_deselect, spi_read_sector, spi_write_sector


; XXX disabled for now; on real hardware, this returns
; XXX all 0xFE bytes with all tested SD cards
;FAST_READ=1
;FAST_WRITE=1


;-----------------------------------------------------------------------------
; Registers
;-----------------------------------------------------------------------------
SPI_CTRL      = VERA_SPI_CTRL
SPI_DATA      = VERA_SPI_DATA

SPI_CTRL_SELECT_SDCARD = $01
SPI_CTRL_SELECT_MASK   = $01

;-----------------------------------------------------------------------------
; deselect card
;
; clobbers: A
;-----------------------------------------------------------------------------
spi_deselect:
	lda SPI_CTRL
	and #(SPI_CTRL_SELECT_MASK ^ $FF)
	sta SPI_CTRL

	jmp spi_read

;-----------------------------------------------------------------------------
; select card
;
; clobbers: A,X,Y
;-----------------------------------------------------------------------------
spi_select:
	lda SPI_CTRL
	ora #SPI_CTRL_SELECT_SDCARD
	sta SPI_CTRL

	jmp spi_read

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


;.macro spi_read_macro
;	.local @1
;	lda #$FF	; 2
;	sta SPI_DATA	; 4
;@1:	bit SPI_CTRL	; 4
;	bmi l1		; 2 + 1 if branch
;	lda SPI_DATA	; 4
;.endmacro

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

;.macro spi_write_macro
;	.local @1
;	sta SPI_DATA
;@1:	bit SPI_CTRL
;	bmi @1
;.endmacro

;-----------------------------------------------------------------------------
; sdcard_init
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
spi_ctrl:
	sta SPI_CTRL
	rts


;-----------------------------------------------------------------------------
; dummy

.macro spi_write_macro
.endmacro


;-----------------------------------------------------------------------------
; spi_read_sector
; read 512 bytes from SPI to sector_buffer
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
spi_read_sector:

.ifdef FAST_READ
@start: ; Enable auto-tx mode
        lda SPI_CTRL
        ora #SPI_CTRL_AUTOTX
        sta SPI_CTRL

        ; Start first read transfer
        lda SPI_DATA                    ; Auto-tx
        ldy #0                          ; 2

        ; Efficiently read first 256 bytes (hide SPI transfer time)
        ldy #0                          ; 2
@3:     lda SPI_DATA                    ; 4
        sta sector_buffer + 0, y        ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 1, y        ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 2, y        ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 3, y        ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 4, y        ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 5, y        ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 6, y        ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 7, y        ; 5
        tya                             ; 2
        clc                             ; 2
        adc #8                          ; 2
        tay                             ; 2
        bne @3                          ; 2+1

        ; Efficiently read second 256 bytes (hide SPI transfer time)
@4:     lda SPI_DATA                    ; 4
        sta sector_buffer + 256 + 0, y  ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 256 + 1, y  ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 256 + 2, y  ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 256 + 3, y  ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 256 + 4, y  ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 256 + 5, y  ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 256 + 6, y  ; 5
        lda SPI_DATA                    ; 4
        sta sector_buffer + 256 + 7, y  ; 5
        tya                             ; 2
        clc                             ; 2
        adc #8                          ; 2
        tay                             ; 2
        bne @4                          ; 2+1

        ; Disable auto-tx mode
        lda SPI_CTRL
        and #(SPI_CTRL_AUTOTX ^ $FF)
        sta SPI_CTRL

        ; Next read is now already done (first CRC byte), read second CRC byte
        jsr spi_read

.else
@start: ; Read 512 bytes of sector data
        ldx #$FF
        ldy #0
@3:     stx SPI_DATA            ; 4
@4:     bit SPI_CTRL            ; 4
        bmi @4                  ; 2 + 1 if branch

        lda SPI_DATA            ; 4
        sta sector_buffer + 0, y
        iny
        bne @3

        ; Y already 0 at this point
@5:     stx SPI_DATA            ; 4
@6:     bit SPI_CTRL            ; 4
        bmi @6                  ; 2 + 1 if branch
        lda SPI_DATA            ; 4
        sta sector_buffer + 256, y
        iny
        bne @5

        ; Read CRC bytes
        jsr spi_read
        jsr spi_read
.endif
	rts

;-----------------------------------------------------------------------------
; spi_write_sector
; write 512 bytes of data from sector_buffer
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
spi_write_sector:

.ifdef FAST_WRITE
        ; Send 512 bytes of sector data
        ; NOTE: Direct access of SPI registers to speed up.
        ;       Make sure 9 CPU clock cycles take longer than 640 ns (eg. CPU max 14MHz)
        ldy #0
@1:     lda sector_buffer, y            ; 4
        sta SPI_DATA                    ; 4
        iny                             ; 2
        bne @1                          ; 2 + 1

        ; Y already 0 at this point
@2:     lda sector_buffer + 256, y      ; 4
        sta SPI_DATA                    ; 4
        iny                             ; 2
        bne @2                          ; 2 + 1
.else
        ; Send 512 bytes of sector data
        ldy #0
@1:     lda sector_buffer, y            ; 4
        spi_write_macro
        iny                             ; 2
        bne @1                          ; 2 + 1

        ; Y already 0 at this point
@2:     lda sector_buffer + 256, y      ; 4
        spi_write_macro
        iny                             ; 2
        bne @2                          ; 2 + 1
.endif
        rts

