; ----------------------------------------------------------------
; Monitor
; ----------------------------------------------------------------
;
; Data input and dumping:
;
; | out | in  | description
; +-----+-----+---------------
; |  M	|  :  | 8 hex bytes
; |  I	|  '  | 32 PETSCII characters
; |  EC |  [  | 1 binary byte (character data)
; |  ES |  ]  | 3 binary bytes (sprite data)
; |  D	|  ,  | disassemble
; |  R	|  ;  | registers
;
; Other commands:
;
; "F"/"H"/"C"/"T" - find, hunt, compare, transfer
; "A" - assemble
; "G" - run code
; "$" - convert hex to decimal
; "#" - convert decimal to hex
; "X" - exit monitor
; "O" - set bank
; "L"/"S" - load/save file
; "@" - send drive command
;
; Unique features of this monitor include:
; * "I" command to dump 32 PETSCII characters, which even renders
;   control characters correctly.
; * F3/F5 scroll more lines in (disassembly, dump, ...) on either
;   the top or the bottom of the screen. This includes backwards
;   disassembly.
; * "OD" switches all memory dumps/input to the drive's memory.

.feature labels_without_colons

.include "kernal.i"

; common
.export get_hex_byte
.export get_hex_byte2
.export load_byte
.export tmp16

; asm
.import cmd_a
.import LAE7C
.import disassemble_line
.export zp1_plus_a_2
.export print_hex_16
.export LAD4B
.export basin_if_more
.export check_end
.export fill_kbd_buffer_a
.export get_hex_byte3
.export get_hex_word
.export get_hex_word3
.export input_loop
.export input_loop2
.export num_asm_bytes
.export prefix_suffix_bitfield
.export print_cr_dot
.export print_hex_byte2
.export print_space
.export print_up
.export reg_s
.export store_byte
.export swap_zp1_and_zp2
.export tmp10
.export tmp17
.export tmp3
.export tmp4
.export tmp6
.export tmp8
.export tmp9
.export tmp_opcode
.export zp1

; io
.export LBC4C
.export basin_cmp_cr
.export basin_if_more
.export basin_skip_spaces_cmp_cr
.export basin_skip_spaces_if_more
.export command_index
.export command_index_l
.export command_index_s
.export get_hex_word3
.export input_loop
.export input_loop2
.export print_cr
.export print_cr_then_input_loop
.export store_byte
.export swap_zp1_and_zp2
.export syntax_error
.export zp1
.export zp2
.export zp3
.export mon_fa
.export byte_to_hex_ascii
.import cmd_at
.import cmd_ls

zp              = $22
zp1		= zp+0
zp2		= zp+2
zp3		= zp+4
mon_fa		= zp+6
bank		= zp+7
f_keys_disabled	= zp+8
tmp1		= zp+9
tmp2		= zp+10
bank_flags	= zp+11 ; $80: video, $40: I2C

DEFAULT_BANK	:= 0

tmp3		:= BUF + 3
tmp4		:= BUF + 4
num_asm_bytes	:= BUF + 5
tmp6		:= BUF + 6
prefix_suffix_bitfield := BUF + 7
tmp8		:= BUF + 8
tmp9		:= BUF + 9
tmp10		:= BUF + 10
tmp11		:= BUF + 11
tmp12		:= BUF + 12
tmp13		:= BUF + 13
tmp14		:= BUF + 14
tmp16		:= BUF + 16
tmp17		:= BUF + 17
.if .defined(CPU_65C02)
tmp_opcode	:= tmp12
.endif

ram_code_end = __monitor_ram_code_RUN__ + __monitor_ram_code_SIZE__
reg_pc_hi	:= ram_code_end + 5
reg_pc_lo	:= ram_code_end + 6
reg_p		:= ram_code_end + 7

registers	:= ram_code_end + 8
reg_a		:= ram_code_end + 8
reg_x		:= ram_code_end + 9
reg_y		:= ram_code_end + 10
reg_s		:= ram_code_end + 11

irq_lo		:= ram_code_end + 12
irq_hi		:= ram_code_end + 13

entry_type	:= ram_code_end + 14
command_index	:= ram_code_end + 15 ; index from "command_names", or 'C'/'S' in EC/ES case
.assert command_index < $0200 + 2*40+1, error, "must not overflow KERNAL editor's buffer"

.segment "monitor"

.import __monitor_ram_code_LOAD__
.import __monitor_ram_code_RUN__
.import __monitor_ram_code_SIZE__


monitor:
	lda #<brk_entry
	sta cbinv
	lda #>brk_entry
	sta cbinv + 1 ; BRK vector
	lda #'C'
	sta entry_type
	lda #DEFAULT_BANK
	sta bank
	ldx #<(__monitor_ram_code_SIZE__ - 1)
:	lda __monitor_ram_code_LOAD__,x
	sta __monitor_ram_code_RUN__,x
	dex
	bpl :-
	brk ; <- nice!

.segment "monitor_ram_code"
; code that will be copied to $0220
goto_user:
	;XXX what do we do if video bank is active?
	sta ram_bank	 ;set RAM bank
	and #$07
	sta rom_bank	 ;set ROM bank
	lda reg_a
	rti

brk_entry:
	pha
	; XXX TODO save banks
	lda #BANK_MONITOR
	sta rom_bank
	pla
	jmp brk_entry2

.segment "monitor"

brk_entry2:
.ifp02
	cld
.endif
	pla
	sta reg_y
	pla
	sta reg_x
	pla
	sta reg_a
	pla
	sta reg_p
	pla
	sta reg_pc_lo
	pla
	sta reg_pc_hi
	tsx
	stx reg_s
	lda #8
	sta mon_fa
	jsr enable_f_keys
	jsr print_cr
	lda entry_type
	cmp #'C'
	bne :+
	bra :++
:	lda #'B'
:	ldx #'*'
	jsr print_a_x
	clc
	lda reg_pc_lo
	adc #$FF
	sta reg_pc_lo
	lda reg_pc_hi
	adc #$FF
	sta reg_pc_hi ; decrement PC
	lda #'B'
	sta entry_type
	bne dump_registers ; always

; ----------------------------------------------------------------
; "R" - dump registers
; ----------------------------------------------------------------
cmd_r:
	jsr basin_cmp_cr
	bne syntax_error
dump_registers:
	ldx #0
:	lda s_regs,x ; "PC	IRQ  BK AC XR YR SP NV#BDIZC"
	beq dump_registers2
	jsr bsout
	inx
	bne :-
dump_registers2:
	ldx #';'
	jsr print_dot_x
	lda reg_pc_hi
	jsr print_hex_byte2 ; address hi
	lda reg_pc_lo
	jsr print_hex_byte2 ; address lo
	jsr print_space
	lda irq_hi
	jsr print_hex_byte2 ; IRQ hi
	lda irq_lo
	jsr print_hex_byte2 ; IRQ lo
	jsr print_space
	bit  bank_flags
	bpl  :+
	lda #'V'
@1:	jsr bsout
	lda bank
	jsr byte_to_hex_ascii
	tya
	jsr bsout
	bne LABEB
:	bvc :+
	lda #'I'
	bne @1
:
	lda bank
	jsr print_hex_byte2 ; bank
LABEB:	ldy #0
:	jsr print_space
	lda registers,y
	jsr print_hex_byte2 ; registers...
	iny
	cpy #4
	bne :-
	jsr print_space
	lda reg_p
	jsr print_bin
	beq input_loop ; always

syntax_error:
	lda #'?'
	bra :+
print_cr_then_input_loop
	lda #CR
:
	jsr bsout

input_loop:
	ldx reg_s
	txs
	lda #0
	sta disable_f_keys
	jsr print_cr_dot
input_loop2:
	jsr basin_if_more
	cmp #'.'
	beq input_loop2 ; skip dots
	cmp #' '
	beq input_loop2 ; skip spaces
	ldx #command_names_end - command_names - 1
LAC27:	cmp command_names,x
	bne LAC3B
	stx command_index
	txa
	asl a
	tax
	lda function_table + 1,x
	pha
	lda function_table,x
	pha
	rts
LAC3B:	dex
	bpl LAC27
	bmi syntax_error ; always

; ----------------------------------------------------------------
; "EC"/"ES"/"D" - dump character or sprite data
; ----------------------------------------------------------------
cmd_e:
	jsr basin
	cmp #'C'
	beq cmd_mid2
	cmp #'S'
	beq cmd_mid2
	jmp syntax_error

fill_kbd_buffer_with_csr_right:
	lda #CSR_UP
	ldx #CR
	jsr print_a_x
	lda #CSR_RIGHT
	ldx #0
:
	jsr kbdbuf_put
	inx
	cpx #7
	bne :-
	jmp input_loop2

cmd_mid2:
	sta command_index ; write 'C' or 'S'

; ----------------------------------------------------------------
; "M"/"I"/"D" - dump 8 hex byes, 32 ASCII bytes, or disassemble
;		("EC" and "ES" also end up here)
; ----------------------------------------------------------------
cmd_mid:
	jsr get_hex_word
	jsr basin_cmp_cr
	bne LAC80 ; second argument
	jsr copy_zp2_to_zp1
	jmp LAC86

is_h:	jmp LAEAC

; ----------------------------------------------------------------
; "F"/"H"/"C"/"T" - find, hunt, compare, transfer
; ----------------------------------------------------------------
cmd_fhct:
	jsr get_hex_word
	jsr basin_if_more
LAC80:	jsr swap_zp1_and_zp2
	jsr get_hex_word3
LAC86:	lda command_index
	beq is_mie ; 'M' (hex dump)
	cmp #command_index_i
	beq is_mie ; 'I' (ASCII dump)
	cmp #command_index_d
	beq is_d ; 'D' (disassemble)
	cmp #command_index_f
	beq is_f ; 'F' (fill)
	cmp #command_index_h
	beq is_h ; 'H' (hunt)
	cmp #'C'
	beq is_mie ; 'EC'
	cmp #'S'
	beq is_mie ; 'ES'
	jmp LAE88

LACA6:	jsr LB64D
	bcs is_mie
LACAB:	jmp fill_kbd_buffer_with_csr_right

is_mie:
	jsr print_cr
	lda command_index
	beq LACC4 ; 'M'
	cmp #'S'
	beq LACD0
	cmp #'C'
	beq LACCA
	jsr dump_ascii_line
	jmp LACA6

LACC4:	jsr dump_hex_line
	jmp LACA6

; EC
LACCA:	jsr dump_char_line
	jmp LACA6

; ES
LACD0:	jsr dump_sprite_line
	jmp LACA6

LACD6:	jsr LB64D
	bcc LACAB
is_d:	jsr print_cr
	jsr dump_assembly_line
	jmp LACD6

is_f:	jsr basin_if_more
	jsr get_hex_byte
	jsr LB22E
	jmp print_cr_then_input_loop

dump_sprite_line:
	ldx #']'
	jsr print_dot_x
	jsr print_hex_16
	jsr print_space
	ldy #0
LACFD:	jsr load_byte
	jsr print_bin
	iny
	cpy #3
	bne LACFD
	jsr print_8_spaces
	tya ; 3
	jmp add_a_to_zp1

dump_char_line:
	ldx #'['
	jsr print_dot_x
	jsr print_hex_16
	jsr print_space
	ldy #0
	jsr load_byte
	jsr print_bin
	jsr print_8_spaces
	jmp inc_zp1

dump_hex_line:
	ldx #':'
	jsr print_dot_x
	jsr print_hex_16
	jsr dump_8_hex_bytes
	jsr print_space
	jmp dump_8_ascii_characters

dump_ascii_line:
	ldx #$27  ; "'"
	jsr print_dot_x
	jsr print_hex_16
	jsr print_space
	ldx #$20
	jmp dump_ascii_characters

dump_assembly_line:
	ldx #','
LAD4B:	jsr print_dot_x
	jsr disassemble_line; XXX why not inline?
	jsr print_8_spaces
	lda num_asm_bytes
	jsr zp1_plus_a
	sta zp1
	sty zp1 + 1
	rts

; ----------------------------------------------------------------

LAE88:	jsr check_end
	bcs LAE90
	jmp syntax_error

LAE90:	sty tmp10
	jsr basin_if_more
	jsr get_hex_word3
	lda command_index
	cmp #command_index_c
	beq LAEA6
	jsr LB1CB
	jmp print_cr_then_input_loop

LAEA6:	jsr LB245
	jmp input_loop

LAEAC:	jsr basin_if_more
	ldx #0
	stx tmp11 ; XXX unused
	jsr basin_if_more
	cmp #$22
	bne LAECF
LAEBB:	jsr basin_cmp_cr
	beq LAEE7
	cmp #$22
	beq LAEE7
	sta BUF,x
	inx
	cpx #$20
	bne LAEBB
	jmp syntax_error

LAECF:	jsr get_hex_byte2
	bcs LAEDC
LAED4:	jsr basin_cmp_cr
	beq LAEE7
	jsr get_hex_byte
LAEDC:	sta BUF,x
	inx
	cpx #$20
	bne LAED4
syn_err2:
	jmp syntax_error

LAEE7:	stx command_index
	txa
	beq syn_err2
	jsr LB293
	jmp input_loop

LB293:	jsr print_cr
LB296:	jsr check_end
	bcc LB2B3
	ldy #0
LB29D:	jsr load_byte
	cmp BUF,y
	bne LB2AE
	iny
	cpy command_index
	bne LB29D
	jsr print_space_hex_16
LB2AE:	jsr inc_zp1
	bne LB296
LB2B3:	rts

LB245:	jsr print_cr
	clc
	lda zp1
	adc tmp9
	sta tmp9
	lda zp1 + 1
	adc tmp10
	sta tmp10
	ldy #0
LB25B:	jsr load_byte
	sta command_index
	jsr swap_zp1_and_zp2
	jsr load_byte
	pha
	jsr swap_zp1_and_zp2
	pla
	cmp command_index
	beq LB274
	jsr print_space_hex_16
LB274:	jsr stop
	beq LB292
	lda zp1 + 1
	cmp tmp10
	bne LB287
	lda zp1
	cmp tmp9
	beq LB292
LB287:	inc zp2
	bne LB28D
	inc zp2 + 1
LB28D:	jsr inc_zp1
	bne LB25B
LB292:	rts

LB1CB:	lda zp2
	cmp zp1
	lda zp2 + 1
	sbc zp1 + 1
	bcs LB1FC
	ldy #0
	ldx #0
LB1D9:	jsr load_byte
	pha
	jsr swap_zp1_and_zp2
	pla
	jsr store_byte
	jsr swap_zp1_and_zp2
	cpx tmp10
	bne LB1F1
	cpy tmp9
	beq LB1FB
LB1F1:	iny
	bne LB1D9
	inc zp1 + 1
	inc zp2 + 1
	inx
	bne LB1D9
LB1FB:	rts

LB1FC:	clc
	ldx tmp10
	txa
	adc zp1 + 1
	sta zp1 + 1
	clc
	txa
	adc zp2 + 1
	sta zp2 + 1
	ldy tmp9
LB20E:	jsr load_byte
	pha
	jsr swap_zp1_and_zp2
	pla
	jsr store_byte
	jsr swap_zp1_and_zp2
	cpy #0
	bne LB229
	cpx #0
	beq LB22D
	dec zp1 + 1
	dec zp2 + 1
	dex
LB229:	dey
	jmp LB20E

LB22D:	rts

; ----------------------------------------------------------------
; "[" - input character data
; ----------------------------------------------------------------
cmd_leftbracket:
	jsr get_hex_word
	jsr copy_zp2_to_zp1
	jsr basin_skip_spaces_if_more
	jsr LB4DB
	ldy #0
	jsr store_byte
	jsr print_up
	jsr dump_char_line
	jsr print_cr_dot
	jsr fill_kbd_buffer_leftbracket
	jmp input_loop2

; ----------------------------------------------------------------
; "]" - input sprite data
; ----------------------------------------------------------------
cmd_rightbracket:
	jsr get_hex_word
	jsr copy_zp2_to_zp1
	jsr basin_skip_spaces_if_more
	jsr LB4DB
	ldy #0
	beq LAD9F
LAD9C:	jsr get_bin_byte
LAD9F:	jsr store_byte
	iny
	cpy #3
	bne LAD9C
	jsr print_up
	jsr dump_sprite_line
	jsr print_cr_dot
	jsr fill_kbd_buffer_rightbracket
	jmp input_loop2

; ----------------------------------------------------------------
; "'" - input 32 ASCII characters
; ----------------------------------------------------------------
cmd_singlequote:
	jsr get_hex_word
	jsr read_ascii
	jsr print_up
	jsr dump_ascii_line
	jsr print_cr_dot
	jsr fill_kbd_buffer_singlequote
	jmp input_loop2

; ----------------------------------------------------------------
; ":" - input 8 hex bytes
; ----------------------------------------------------------------
cmd_colon:
	jsr get_hex_word
	jsr read_8_bytes
	jsr print_up
	jsr dump_hex_line
	jsr print_cr_dot
	jsr fill_kbd_buffer_semicolon
	jmp input_loop2

; ----------------------------------------------------------------
; ";" - set registers
; ----------------------------------------------------------------
cmd_semicolon:
	jsr get_hex_word
	lda zp2 + 1
	sta reg_pc_hi
	lda zp2
	sta reg_pc_lo
	jsr basin_if_more
	jsr get_hex_word3
	lda zp2
	sta irq_lo
	lda zp2 + 1
	sta irq_hi
	jsr basin_if_more ; skip upper nybble of bank
	; XXX X16
	jsr basin_if_more
	cmp #'D' ; "drive"
	bne LAE12
	jsr basin_if_more
	cmp #'R'
	bne syn_err1
	ora #$80 ; XXX why not lda #$80?
	bmi LAE1B ; always
LAE12:	jsr get_hex_byte2
	cmp #8
	bcs syn_err1
LAE1B:	sta bank
	ldx #0
LAE20:	jsr basin_if_more
	jsr get_hex_byte
	sta registers,x ; registers
	inx
	cpx #4
	bne LAE20
	jsr basin_if_more
	jsr get_bin_byte
	sta reg_p
	jsr print_up
	jmp dump_registers2

syn_err1:
	jmp syntax_error

; ----------------------------------------------------------------
; "," - input up to three hex values
; ----------------------------------------------------------------
cmd_comma:
	jsr get_hex_word3
	ldx #3
	jsr read_x_bytes
	lda #$2C
	jsr LAE7C
	jsr fill_kbd_buffer_comma
	jmp input_loop2

; ----------------------------------------------------------------
; "G" - run code
; ----------------------------------------------------------------
cmd_g:
	jsr basin_cmp_cr
	beq LAF03
	jsr get_hex_word2
	jsr basin_cmp_cr
	beq LAF06
	jmp syntax_error

LAF03:	jsr copy_pc_to_zp2_and_zp1
LAF06:
	jsr disable_f_keys
	ldx reg_s
	txs
	lda zp2 + 1
	pha
	lda zp2
	pha
	lda reg_p
	pha
	ldx reg_x
	ldy reg_y
	lda bank
	jmp goto_user

; ----------------------------------------------------------------
; "$" - convert hex to decimal
; ----------------------------------------------------------------
cmd_dollar:
	jsr get_hex_word
	jsr print_up_dot
	jsr copy_zp2_to_zp1
	jsr print_dollar_hex_16
	jsr LB48E
	jsr print_hash
	jsr LBC50
	jmp input_loop

; ----------------------------------------------------------------
; "#" - convert decimal to hex
; ----------------------------------------------------------------
cmd_hash:
	ldy #0
	sty zp1
	sty zp1 + 1
	jsr basin_skip_spaces_if_more
LB16F:	and #$0F
	clc
	adc zp1
	sta zp1
	bcc LB17A
	inc zp1 + 1
LB17A:	jsr basin
	cmp #$30
	bcc LB19B
	pha
	lda zp1
	ldy zp1 + 1
	asl a
	rol zp1 + 1
	asl a
	rol zp1 + 1
	adc zp1
	sta zp1
	tya
	adc zp1 + 1
	asl zp1
	rol a
	sta zp1 + 1
	pla
	bcc LB16F
LB19B:	jsr print_up_dot
	jsr print_hash
	lda zp1
	pha
	lda zp1 + 1
	pha
	jsr LBC50
	pla
	sta zp1 + 1
	pla
	sta zp1
	jsr LB48E
	jsr print_dollar_hex_16
	jmp input_loop

; ----------------------------------------------------------------
; "X" - exit monitor
; ----------------------------------------------------------------
cmd_x:
	jsr disable_f_keys
	ldx reg_s
	txs
	clc ; warm start
	jmp enter_basic

; ----------------------------------------------------------------

LB22E:	ldy #0
LB230:	jsr store_byte
	ldx zp1
	cpx zp2
	bne LB23F
	ldx zp1 + 1
	cpx zp2 + 1
	beq LB244
LB23F:	jsr inc_zp1
	bne LB230
LB244:	rts

; ----------------------------------------------------------------
; memory load/store
; ----------------------------------------------------------------

; loads a byte at (zp1),y from RAM with the correct ROM config
load_byte:
	sei
	bit bank_flags
	bmi @video
	bvs @i2c
; RAM
	stx tmp1
	ldx bank
	lda #zp1
	sei
	jsr fetch
	cli
	ldx tmp1
	rts
; video RAM
@video:	tya
	clc
	adc zp1
	sta VERA_ADDR_L
	lda zp1 + 1
	adc #0
	sta VERA_ADDR_M
	lda bank
	sta VERA_ADDR_H
	lda VERA_DATA0
	rts
; I2C
@i2c:	phx
	phy
	jsr get_i2c_addr
	lda #$ee
	bcs :+
	jsr i2c_read_byte
:	ply
	plx
	cli
	rts

; stores a byte at (zp1),y in RAM with the correct ROM config
store_byte:
	bit bank_flags
	bmi @video
	bvs @i2c
; RAM
	stx tmp1
	ldx #zp1
	stx stavec
	ldx bank
	sei
	jsr stash
	cli
	ldx tmp1
	rts
; video RAM
@video:	pha
	tya
	clc
	adc zp1
	sta VERA_ADDR_L
	lda zp1 + 1
	adc #0
	sta VERA_ADDR_M
	lda bank
	sta VERA_ADDR_H
	pla
	sta VERA_DATA0
	rts
@i2c:	phx
	phy
	pha
	jsr get_i2c_addr
	pla
	bcs :+
	jsr i2c_write_byte
:	ply
	plx
	rts

; convert zp1+y into device:register (page:offset)
; C=1: illegal I2C device
get_i2c_addr:
	tya
	clc
	adc zp1
	tay
	lda #0
	adc zp1+1
	tax
	cpx #$08
	bcc @bad
	cpx #$78
	rts
@bad:	sec
	rts

; ----------------------------------------------------------------
; "O" - set bank
;	C64: * 0 to 7 map to a $01 value of $30-$37
;	     * "D" switches to drive memory
;	TED: * 0 to C, Shift+D and E to F map to banks 0-F
;	     * "D" switches to drive memory
;	X16: * 00 to FF are set as both ROM and RAM bank
; ----------------------------------------------------------------
cmd_o:
	lda #0
	sta bank_flags
:	jsr basin_cmp_cr
	beq LB33F ; without arguments: bank 7
	cmp #' '
	beq :-
	cmp #'V'
	bne not_video
	lda #$80
	sta bank_flags
video_loop:
	jsr basin_cmp_cr
	beq default_video_bank
	cmp #' '
	beq video_loop
	jsr hex_digit_to_nybble
	bra		:+
default_video_bank:
	lda #0
:
	jmp store_bank

not_video:
	cmp #'I'
	bne not_i2c
	lda #$40
	sta bank_flags
	bra default_video_bank

not_i2c:
	jsr get_hex_byte2
	bra :+
LB33F	lda #DEFAULT_BANK
:
	bra store_bank
LB34A:	lda #$80 ; drive
store_bank:
	sta bank
	jmp print_cr_then_input_loop

; ----------------------------------------------------------------

LB48E:	jsr print_space
	lda #'='
	ldx #' '
	bne print_a_x

print_up:
	ldx#CSR_UP
	bra:+
print_cr_dot:
	ldx #'.'
:
	lda #CR
	bra print_a_x
print_dot_x:
	lda #'.'
print_a_x:
	jsr bsout
	txa
	jmp bsout

print_up_dot:
	jsr print_up
	lda #'.'
	bra :+
; XXX unused?
	lda #CSR_RIGHT
	bra :+
print_hash
	lda #'#'
	bra :+
print_space
	lda #' '
	bra :+
print_cr
	lda #CR
:
	jmp bsout

basin_skip_spaces_if_more:
	jsr basin_skip_spaces_cmp_cr
	bra LB4C5

; get a character; if it's CR, return to main input loop
basin_if_more:
	jsr basin_cmp_cr
LB4C5:	bne :+
	jmp input_loop
:	rts

basin_skip_spaces_cmp_cr:
	jsr basin
	cmp #' '
	beq basin_skip_spaces_cmp_cr ; skip spaces
	cmp #CR
	rts

basin_cmp_cr:
	jsr basin
	cmp #CR
	rts

LB4DB:	pha
	ldx #8
	bne LB4E6

get_bin_byte:
	ldx #8
LB4E2:	pha
	jsr basin_if_more
LB4E6:	cmp #'*'
	beq LB4EB
	clc
LB4EB:	pla
	rol a
	dex
	bne LB4E2
	rts

; get a 16 bit ASCII hex number from the user, return it in zp2
get_hex_word:
	jsr basin_if_more
get_hex_word2:
	cmp #' ' ; skip spaces
	beq get_hex_word
	jsr get_hex_byte2
	bcs LB500 ; ??? always
get_hex_word3:
	jsr get_hex_byte
LB500:	sta zp2 + 1
	jsr get_hex_byte
	sta zp2
	rts

; get a 8 bit ASCII hex number from the user, return it in A
get_hex_byte:
	lda #0
	sta tmp2 ; XXX not necessary
	jsr basin_if_more
get_hex_byte2:
	jsr validate_hex_digit
get_hex_byte3:
	jsr hex_digit_to_nybble
	asl a
	asl a
	asl a
	asl a
	sta tmp2 ; low nybble
	jsr get_hex_digit
	jsr hex_digit_to_nybble
	ora tmp2
	sec
	rts

hex_digit_to_nybble:
	cmp #'9' + 1
	and #$0F
	bcc LB530
	adc #'A' - '9'
LB530:	rts


; get character and check for legal ASCII hex digit
; XXX this also allows ":;<=>?" (0x39-0x3F)!!!
get_hex_digit:
	jsr basin_if_more
validate_hex_digit:
	cmp #'0'
	bcc syn_err5
	cmp #'@' ; XXX should be: '9' + 1
	bcc LB546 ; ok
	cmp #'A'
	bcc syn_err5
	cmp #'F' + 1
	bcs syn_err5
LB546:	rts
syn_err5:
	jmp syntax_error

print_dollar_hex_16:
	lda #'$'
	bra :+
print_space_hex_16
	lda #' '
:
	jsr bsout
print_hex_16:
	lda zp1 + 1
	jsr print_hex_byte2
	lda zp1

print_hex_byte2:
	sty tmp1
	jsr print_hex_byte
	ldy tmp1
	rts

print_bin:
	ldx	#8
LB565:	rol a
	pha
	lda #'*'
	bcs :+
	lda #'.'
:	jsr bsout
	pla
	dex
	bne LB565
	rts

inc_zp1:
	clc
	inc zp1
	bne :+
	inc zp1 + 1
	sec
:	rts

dump_8_hex_bytes:
	ldx #8
	ldy #0
:	jsr print_space
	jsr load_byte
	jsr print_hex_byte2
	iny
	dex
	bne :-
	rts

dump_8_ascii_characters:
	ldx #8
dump_ascii_characters:
	ldy #0
LB594:	lda #$80 ; enable verbatim mode for 1 char
	jsr bsout
	jsr load_byte
	jsr bsout
	iny
	dex
	bne LB594
	tya ; number of bytes consumed
	jmp add_a_to_zp1

read_ascii:
	ldx #32 ; number of characters
	ldy #0
	jsr copy_zp2_to_zp1
	jsr basin_if_more
LB5C8:	lda #$80
	jsr bsout
	jsr basin_if_more
	cmp #0
	beq :+ ; skip if non-ASCII
	jsr store_byte
:	iny
	dex
	bne LB5C8
	rts

read_8_bytes:
	ldx #8
read_x_bytes:
	ldy #0
	jsr copy_zp2_to_zp1
	jsr basin_skip_spaces_if_more
	jsr get_hex_byte2
	jmp LB607

LB5F5:	jsr basin_if_more_cmp_space ; ignore character where space should be
	jsr basin_if_more_cmp_space
	bne LB604 ; not space
	jsr basin_if_more_cmp_space
	bne syn_err6 ; not space
	beq LB60A ; always

LB604:	jsr get_hex_byte2
LB607:	jsr store_byte
LB60A:	iny
	dex
	bne LB5F5
	rts

basin_if_more_cmp_space:
	jsr basin_cmp_cr
	bne :+
	pla
	pla
:	cmp #' '
	rts

syn_err6:
	jmp syntax_error

swap_zp1_and_zp2:
	lda zp2 + 1
	pha
	lda zp1 + 1
	sta zp2 + 1
	pla
	sta zp1 + 1
	lda zp2
	pha
	lda zp1
	sta zp2
	pla
	sta zp1
	rts

copy_pc_to_zp2_and_zp1:
	lda reg_pc_hi
	sta zp2 + 1
	lda reg_pc_lo
	sta zp2

copy_zp2_to_zp1:
	lda zp2
	sta zp1
	lda zp2 + 1
	sta zp1 + 1
	rts

LB64D:	lda zp1 + 1
	bne check_end
	bcc check_end
	clc
	rts

check_end:
	jsr stop
	beq :+
	lda zp2
	ldy zp2 + 1
	sec
	sbc zp1
	sta tmp9 ; zp2 - zp1
	tya
	sbc zp1 + 1
	tay ; (zp2 + 1) - (zp1 + 1)
	ora tmp9
	rts
:	clc
	rts

fill_kbd_buffer_comma:
	lda #','
	bra :+
fill_kbd_buffer_semicolon
	lda #':'
	bra :+
fill_kbd_buffer_a
	lda #'A'
	bra :+
fill_kbd_buffer_leftbracket
	lda #'['
	bra :+
fill_kbd_buffer_rightbracket
	lda #']'
	bra :+
fill_kbd_buffer_singlequote
	lda #$27 ; "'"
:
	jsr kbdbuf_put
	lda zp1 + 1
	jsr byte_to_hex_ascii
	jsr kbdbuf_put
	tya
	jsr kbdbuf_put
	lda zp1
	jsr byte_to_hex_ascii
	jsr kbdbuf_put
	tya
	jsr kbdbuf_put
	lda #' '
	jsr kbdbuf_put
	rts

; print 7x cursor right
print_7_csr_right:
	lda #CSR_RIGHT
	ldx #7
	bne LB6AC ; always

; print 8 spaces - this is used to clear some leftover characters
; on the screen when re-dumping a line with proper spacing after the
; user may have entered it with condensed spacing
print_8_spaces:
	lda #' '
	ldx #8
LB6AC:	jsr bsout
	dex
	bne LB6AC
	rts

.segment "monitor"

; ----------------------------------------------------------------

s_regs: .byte	CR, "   PC  IRQ  BK AC XR YR SP NV#BDIZC", CR, 0

; ----------------------------------------------------------------


command_names:
	.byte "M" ; N.B.: code relies on "M" being the first entry of this table!
command_index_d = * - command_names
	.byte "D"
	.byte ":"
	.byte "A"
	.byte "G"
	.byte "X"
command_index_f = * - command_names
	.byte "F"
command_index_h = * - command_names
	.byte "H"
command_index_c = * - command_names
	.byte "C"
	.byte "T"
	.byte "R"
command_index_l = * - command_names
	.byte "L"
command_index_s = * - command_names
	.byte "S"
	.byte ","
	.byte "O"
	.byte "@"
	.byte "$"
	.byte "#"
	.byte "E"
	.byte "["
	.byte "]"
command_index_i = * - command_names
	.byte "I"
	.byte "'"
	.byte ";"
command_names_end:

function_table:
	.word cmd_mid-1
	.word cmd_mid-1
	.word cmd_colon-1
	.word cmd_a-1
	.word cmd_g-1
	.word cmd_x-1
	.word cmd_fhct-1
	.word cmd_fhct-1
	.word cmd_fhct-1
	.word cmd_fhct-1
	.word cmd_r-1
	.word cmd_ls-1
	.word cmd_ls-1
	.word cmd_comma-1
	.word cmd_o-1
	.word cmd_at-1
	.word cmd_dollar-1
	.word cmd_hash-1
	.word cmd_e-1
	.word cmd_leftbracket-1
	.word cmd_rightbracket-1
	.word cmd_mid-1
	.word cmd_singlequote-1
	.word cmd_semicolon-1

; ----------------------------------------------------------------

print_hex_byte:
	jsr byte_to_hex_ascii
	jsr bsout
	tya
	jmp bsout

; convert byte into hex ASCII in A/Y
byte_to_hex_ascii:
	pha
	and #$0F
	jsr LBCC8
	tay
	pla
	lsr a
	lsr a
	lsr a
	lsr a
LBCC8:	clc
	adc #$F6
	bcc LBCCF
	adc #$06
LBCCF:	adc #$3A
	rts

LBC4C:	stx zp1
	sta zp1 + 1
LBC50:	lda #$31
	sta zp2
	ldx #4
LBC56:	dec zp2
LBC58:	lda #$2F
	sta zp2 + 1
	sec
	ldy zp1
	bra :+
LBC60	sta zp1 + 1
:
	sty zp1
	inc zp2 + 1
	tya
	sbc pow10lo2,x
	tay
	lda zp1 + 1
	sbc pow10hi2,x
	bcs LBC60
	lda zp2 + 1
	cmp zp2
	beq LBC7D
	jsr bsout
	dec zp2
LBC7D:	dex
	beq LBC56
	bpl LBC58
	rts

; adds signed A to 16 bit zp1
zp1_plus_a:
	sec
zp1_plus_a_2:
	ldy zp1 + 1
	tax
	bpl :+
	dey
:	adc zp1
	bcc :+
	iny
:	rts

sadd_a_to_zp1:
	jsr zp1_plus_a
	sta zp1
	sty zp1 + 1
	rts

add_a_to_zp1:
	clc
	adc zp1
	sta zp1
	bcc LB8D3
	inc zp1 + 1
LB8D3:	rts

pow10lo2:
	.byte <1, <10, <100, <1000, <10000
pow10hi2:
	.byte >1, >10, >100, >1000, >10000

.include "irq.s"
