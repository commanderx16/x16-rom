	.segment "UART"

uart_loader_addrl = 0
uart_loader_addrh = 1

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

@check_uart
	; Check status
	lda_vaddr $0F, uart_status
	and #1
	beq @done

	; Read byte from RX FIFO
	ldx_vaddr_lo uart_data

	; Branch to current statemachine state
	lda uart_loader_state
	cmp #0
	beq @state_cmd
	cmp #1
	beq @state_addrl
	cmp #2
	beq @state_addrh
	cmp #3
	beq @state_wrdata

	; Invalid state
	jmp @go_idle

@done	; Clear UART IRQ
	lda #8
	sta veraisr

	jsr vera_restore

	; Return from interrupt
	irq_return

@go_idle
	lda #0
	sta uart_loader_state
	jmp @check_uart

@state_cmd
	stx uart_loader_cmd

	; Check command index range
	dex
	cpx #3
	bcs @check_uart ; index out of range

	; Command ok, next state
	inc uart_loader_state
	jmp @check_uart

@state_addrl
	; Store lower address byte
	stx uart_loader_addrl

	inc uart_loader_state
	jmp @check_uart

@state_addrh
	; Store upper address byte
	stx uart_loader_addrh

	; Check for read/jump command
	lda uart_loader_cmd
	cmp #2		; Read command?
	beq @read
	cmp #3		; Jump command?
	beq @jump

	; Write command, next state
	inc uart_loader_state
	bne @check_uart

	; Command 2: read
@read	jsr vera_restore

	ldy #0
	lda (uart_loader_addrl), y
	tax

	jsr vera_save

	; Transmit the read byte
	vera_vaddr $0F, uart_data
	stx veradat

	; Return to idle state
	jmp @go_idle

	; Command 3: jump
@jump	jsr vera_restore
	jmp (uart_loader_addrl)

	; Command 1: write
@state_wrdata
	jsr vera_restore

	txa
	ldy #0
	sta (uart_loader_addrl), y

	jsr vera_save

	; Return to idle state
	jmp @go_idle
