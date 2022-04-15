plot = $fff0

bmt2 = $1120 ; XXX
xmon1 = $1121 ; XXX
ldtb1 = $1122 ; XXX
nlines = $1123 ; XXX
nlinesm1 = $1124 ; XXX
blnsw = $1125 ; XXX
gdbln = $1126 ; XXX
blnon = $1127 ; XXX
tblx = $1128 ; XXX
pnt = $1129 ; XXX

mjsrfar = $1112 ; XXX
LDTB1 = $1113 ; XXX
screen_set_char = $1114 ; XXX
GDBLN = $1115 ; XXX
BLNON = $1116 ; XXX
BLNSW = $1117 ; XXX
sadd_a_to_zp1 = $111C ; XXX
decode_mnemo = $111D ; XXX
TBLX = $111E ; XXX
;kbdbuf_clear = $111F ; XXX


cinv   := $0314 ; IRQ vector

; ----------------------------------------------------------------
; IRQ logic to handle F keys and scrolling
; ----------------------------------------------------------------
set_irq_vector:
	sei
	lda #<keyhandler
	sta $032e
	lda #>keyhandler
	sta $032f
	cli
	rts

	lda cinv
	cmp #<irq_handler
	bne LB6C1
	lda cinv + 1
	cmp #>irq_handler
	beq LB6D3
LB6C1:	lda cinv
	ldx cinv + 1
	sta irq_lo
	stx irq_hi
	lda #<irq_handler
	ldx #>irq_handler
	bne LB6D9 ; always
LB6D3:	lda irq_lo
	ldx irq_hi
LB6D9:	sei
	sta cinv
	stx cinv + 1
	cli
	rts

.segment "monitor_ram_code"

irq_handler:;XXX
keyhandler:
	ldy rom_bank
	phy
	ldy #BANK_MONITOR
	sty rom_bank
	jsr keyhandler2
	ply
	sty rom_bank
	rts

.segment "monitor"

keyhandler2:
	; F3: $04
	; F5: $03
	; DN: $E0/$72
	; UP: $E0/$75
	bcc :+ ; down
@ret:	rts
:	bit disable_f_keys
	bmi @ret
	cpx #0
	beq :+
@ret2:	clc
	rts
:	cmp #$83
	bne @not_f7

;	jsr kbdbuf_clear
	lda #'@'
	jsr kbdbuf_put
	lda #'$'
	jsr kbdbuf_put
	lda #CR
	jsr kbdbuf_put
	lda #0
	clc
	rts

@not_f7:
	cmp #3 ; F5
	bne @ret2
; F5
;	jsr kbdbuf_clear

	jsr clear_cursor
	sec
	jsr plot ; cursor position
	phy ; col
	jsr screen ; screen size
	tya
	tax
	dex
	ply
	clc
@xxx:	jsr plot

LB72E:

	lda #0
	clc
	rts


	lda #CSR_DOWN
	jsr kbdbuf_put
LB733:	cmp #KEY_F3
	bne LB74A
;	jsr kbdbuf_clear
	ldx #0
	cpx TBLX
	beq LB745
	jsr clear_cursor
	ldy pntr
	jsr LE50C ; KERNAL set cursor position
LB745:	lda #CSR_UP
	jsr kbdbuf_put

LB74A:	cmp #CSR_DOWN
	beq LB758
	cmp #CSR_UP
	bne LB6FA

; UP
	lda TBLX
	beq LB75E ; top of screen
	bne LB6FA

LB6FA:	rts

; DOWN
LB758:	lda TBLX
	cmp nlinesm1
	bne LB6FA

; SCROLL DOWN
LB75E:	jsr LB838
	bcc LB6FA
	jsr read_hex_word_from_screen
	php
	jsr LB8D4
	plp
	bcc :+
	jmp LB6FA
:	lda TBLX
	beq LB7E1
	lda tmp12
	cmp #','
	beq LB790
	cmp #'['
	beq LB7A2
	cmp #']'
	beq LB7AE
	cmp #$27 ; "'"
	beq LB7BC
	lda #8
	jsr add_a_to_zp1
	jsr print_cr
	jsr dump_hex_line
	jmp LB7C7

LB790:	jsr decode_mnemo
	lda num_asm_bytes
	jsr sadd_a_to_zp1
	jsr print_cr
	jsr dump_assembly_line
	jmp LB7C7

LB7A2:	jsr inc_zp1
	jsr print_cr
	jsr dump_char_line
	jmp LB7C7

LB7AE:	lda #3
	jsr add_a_to_zp1
	jsr print_cr
	jsr dump_sprite_line
	jmp LB7C7

LB7BC:	lda #$20
	jsr add_a_to_zp1
	jsr print_cr
	jsr dump_ascii_line
LB7C7:	lda #CSR_UP
	ldx #CR
	bne LB7D1
LB7CD:	lda #CR
	ldx #CSR_HOME
LB7D1:	ldy #0
;	jsr kbdbuf_clear
	sty disable_f_keys
	jsr print_a_x
	jsr print_7_csr_right
	jmp LB6FA

LB7E1:	jsr scroll_down
	lda tmp12
	cmp #','
	beq LB800
	cmp #'['
	beq LB817
	cmp #']'
	beq LB822
	cmp #$27 ; "'"
	beq LB82D
	jsr LB8EC
	jsr dump_hex_line
	jmp LB7CD

LB800:	jsr swap_zp1_and_zp2
	jsr LB90E
	inc num_asm_bytes
	lda num_asm_bytes
	eor #$FF
	jsr sadd_a_to_zp1
	jsr dump_assembly_line
	clc
	bcc LB7CD
LB817:	lda #1
	jsr LB8EE
	jsr dump_char_line
	jmp LB7CD

LB822:	lda #3
	jsr LB8EE
	jsr dump_sprite_line
	jmp LB7CD

LB82D:	lda #$20
	jsr LB8EE
	jsr dump_ascii_line
	jmp LB7CD

LB838:	lda pnt
	ldx pnt + 1
	sta zp2
	stx zp2 + 1
	lda nlines
	sta tmp13
LB845:	ldy #1 ; column 1
	jsr get_screen_char
	cmp #':'
	beq LB884
	cmp #','
	beq LB884
	cmp #'['
	beq LB884
	cmp #']'
	beq LB884
	cmp #$27 ; "'"
	beq LB884
	dec tmp13
	beq LB889
	jsr kbdbuf_peek
	cmp #CSR_DOWN
	bne LB877
	dec zp2 + 1
	bne LB845
LB877:
	inc zp2 + 1
	bne LB845
LB884:	sec
	sta tmp12
	rts

LB889:	clc
	rts

get_screen_char:
	tya
	asl
	clc
	adc zp2
	sta VERA_ADDR_L
	lda zp2+1
	adc #>screen_addr
	sta VERA_ADDR_M
	lda #$10 | ^screen_addr
	sta VERA_ADDR_H
	lda VERA_DATA0
	iny
	and #$7F
	cmp #$20
	bcs LB896
	ora #$40
LB896:	rts

read_hex_word_from_screen:
	cpy #$16
	bne :+
	sec
	rts
:	jsr get_screen_char
	cmp #$20
	beq read_hex_word_from_screen
	dey
	jsr read_hex_byte_from_screen
	sta zp1 + 1
	jsr read_hex_byte_from_screen
	sta zp1
	clc
	rts

read_hex_byte_from_screen:
	jsr get_screen_char
	jsr hex_digit_to_nybble
	asl a
	asl a
	asl a
	asl a
	sta tmp11
	jsr get_screen_char
	jsr hex_digit_to_nybble
	ora tmp11
	rts

LB8D4:	lda #$FF
	sta disable_f_keys
clear_cursor:
;	lda #$FF
;	sta BLNSW
;	lda BLNON
;	beq LB8EB ; rts
;	lda GDBLN
;	ldy pntr
;	jsr screen_set_char
;	lda #0
;	sta BLNON
LB8EB:	rts

LB8EC:	lda #8
LB8EE:	sta tmp14
	sec
	lda zp1
	sbc tmp14
	sta zp1
	bcs LB8FD
	dec zp1 + 1
LB8FD:	rts

scroll_down:
	ldx #0
	jsr LE96C ; insert line at top of screen
	lda LDTB1
	ora #$80 ; first line is not an extension
	sta LDTB1
	lda #CSR_HOME
	jmp bsout

LB90E:	lda #16 ; number of bytes to scan backwards
	sta tmp13
LB913:	sec
	lda zp2
	sbc tmp13
	sta zp1
	lda zp2 + 1
	sbc #0
	sta zp1 + 1 ; look this many bytes back
:	jsr decode_mnemo
	lda num_asm_bytes
	jsr sadd_a_to_zp1
	jsr check_end
	beq :+
	bcs :-
	dec tmp13
	bne LB913
:	rts

LE96C:
	jsr mjsrfar
	.word bmt2  ; insert line at top of screen
	.byte BANK_KERNAL
	rts

LE50C:
	jsr mjsrfar
	.word xmon1 ; set cursor position
	.byte BANK_KERNAL
	rts
