	.segment "UART"

loader_state = $FC
loader_cmd   = $FD
loader_addrl = $FE
loader_addrh = $FF

; Commands
; 01 AL AH DD  - Write data to address
; 02 AL AH     - Read data from address and send back over UART
; 03 AL AH     - Jump to address

uartirq
	; Check for UART IRQ
	lda veraisr
	and #8
	bne @handle_uart

	; Jump to original handler
	jmp key

@handle_uart
	jsr vera_save

@done	; Clear UART IRQ
	lda #8
	sta veraisr

	; Restore VERA registers
	lda vera_irq_save+1
	sta verahi
	lda vera_irq_save+2
	sta veramid
	lda vera_irq_save+3
	sta veralo
	lda vera_irq_save+0
	sta veractl

	; Return from interrupt
	pla             ; restore registers
	tay
	pla
	tax
	pla
	rti             ; exit from irq routines

@check_uart
	; Check status
	lda_vaddr $0F, uart_status
	and #1
	beq @done

	; Read byte from RX FIFO
	ldx_vaddr_lo uart_data

	; Branch to current statemachine state
	lda loader_state
	cmp #0
	beq @state_cmd
	cmp #1
	beq @state_addrl
	cmp #2
	beq @state_addrh
	cmp #3
	beq @state_wrdata

	; Invalid state
	lda #0
	sta loader_state
	jmp @check_uart

@state_cmd
	stx loader_cmd

	; Check command index range
	dex
	cpx #3
	bcs @check_uart ; index out of range

	; Command ok, next state
	inc loader_state
	jmp @check_uart

@state_addrl
	; Store lower address byte
	stx loader_addrl
	inc loader_state
	jmp @check_uart

@state_addrh
	; Store upper address byte
	stx loader_addrh

	; Check for read/jump command
	lda loader_cmd
	cmp #2		; Read command?
	beq @read
	cmp #3		; Jump command?
	beq @jump

	; Write command
	inc loader_state
	bne @check_uart

	; Command 2: read
@read	jsr vera_restore

	txa
	ldy #0
	lda (loader_addrl), y
	tax

	jsr vera_save

	; Transmit the read byte
	vera_addr $0F, uart_data
	stx veradat

	; Return to idle state
	lda #0
	sta loader_state
	jmp @check_uart

	; Command 3: jump
@jump	jsr vera_restore
	jmp (loader_addrl)

	; Command 1: write
@state_wrdata
	jsr vera_restore

	txa
	ldy #0
	sta (loader_addrl), y

	jsr vera_save

	; Return to idle state
	lda #0
	sta loader_state
	jmp @check_uart

