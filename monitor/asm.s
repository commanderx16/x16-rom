.include "kernal.i"

.import __mnemos1_RUN__
.import __mnemos2_RUN__
.import __asmchars1_RUN__
.import __asmchars2_RUN__

.import zp1_plus_a_2
.import print_hex_16
.import LAD4B
.import basin_if_more
.import check_end
.import fill_kbd_buffer_a
.import get_hex_byte
.import get_hex_byte2
.import get_hex_byte3
.import get_hex_word
.import get_hex_word3
.import input_loop
.import input_loop2
.import load_byte
.import num_asm_bytes
.import prefix_suffix_bitfield
.import print_cr_dot
.import print_hex_byte2
.import print_space
.import print_up
.import reg_s
.import store_byte
.import swap_zp1_and_zp2
.import tmp10
.import tmp16
.import tmp17
.import tmp3
.import tmp4
.import tmp6
.import tmp8
.import tmp9
.import tmp_opcode
.importzp zp1

.export cmd_a
.export LAE7C
.export disassemble_line

.segment "monitor"

; ----------------------------------------------------------------
; "A" - assemble
; ----------------------------------------------------------------
cmd_a:
	jsr get_hex_word
	jsr LB030
	jsr LB05C
	ldx #0
	stx tmp6
LAE61:	ldx reg_s
	txs
	jsr LB08D
	jsr LB0AB
	jsr swap_zp1_and_zp2
	jsr LB0EF
	lda #'A'
	jsr LAE7C
	jsr fill_kbd_buffer_a
	jmp input_loop2

LAE7C:	pha
	jsr print_up
	pla
	tax
	jsr LAD4B
	jmp print_cr_dot

; ----------------------------------------------------------------
; assembler/disassembler
; ----------------------------------------------------------------
; prints the hex bytes consumed by an asm instruction
print_asm_bytes:
	pha
	ldy #0
LAF43:	cpy num_asm_bytes
	beq LAF52
	bcc LAF52
	jsr print_space
	jsr print_space
	bcc LAF58
LAF52:	jsr load_byte
	jsr print_hex_byte2
LAF58:	jsr print_space
	iny
	cpy #3
	bne LAF43
	pla
	rts

; returns mnemo index in A
decode_mnemo:
	ldy #0
	jsr load_byte; opcode
decode_mnemo_2:
.if .defined(CPU_65C02)
	sta tmp_opcode
.endif
.if .defined(CPU_6502)
	tay
	lsr a
	bcc @1 ; skip if opodes $x0, $x2, $x4, $x6, $x8, $xA, $xC, $xE
	; continue for opcodes $x1, $x3, $x5, $x7, $x9, $xB, $xD, $xF
	lsr a
	bcs @3 ; branch for opcodes $x3, $x7, $xC, $xF
	; continue for opcodes $x1, $x5, $x9, $xB
	cmp #$22
	beq @3 ; opcodes $89 of $8D?
	and #$07 ; opcode bits 4,3,2
	ora #$80 ; use special bytes past first 64
@1:	lsr a ; opcode bit 2 into carry
	tax
	lda addmode_table,x
	bcs @2 ; opcode bit 2 set, then use low nybble
	lsr a
	lsr a
	lsr a
	lsr a ; otherwise get hi nybble
@2:	and #$0F
	bne @4 ; if nybble is 0, Y = $80
@3:	ldy #$80
	lda #0
@4:	tax
	lda addmode_detail_table,x ; X = 0..13
	sta prefix_suffix_bitfield
	and #3
	sta num_asm_bytes
; mnemo: convert opcode in A to mnemo index (0-64)
	tya ; opcode
	and #%10001111
	tax
	tya ; opcode
	ldy #3
	cpx #%10001010 ; $8A/$9A/.../$FA?
	beq @7
@5:	lsr a
	bcc @7
	lsr a
@6:	lsr a
	ora #%00100000
	dey
	bne @6
	iny
@7:	dey
	bne @5
	rts
.elseif .defined(CPU_6502ILL) || .defined(CPU_65C02)
	tay
	lsr
	tax
	lda addmode_table,x
	bcs @1
	lsr
	lsr
	lsr
	lsr
@1:	and #$0f
	tax
	lda addmode_detail_table,x ; X = 0..13
	sta prefix_suffix_bitfield
	and #3
	sta num_asm_bytes
	lda mnemotab,y
	rts
.if .defined(CPU_6502ILL)
mnemotab:
	.byte 15, 44, 36, 62, 43, 44, 6, 62, 46, 44, 6, 3, 43, 44, 6, 62, 14, 44, 36, 62, 43, 44, 6, 62, 18, 44, 43, 62, 43, 44, 6, 62, 35, 4, 36, 49, 11, 4, 50, 49, 48, 4, 50, 3, 11, 4, 50, 49, 12, 4, 36, 49, 43, 4, 50, 49, 57, 4, 43, 49, 43, 4, 50, 49, 53, 29, 36, 63, 43, 29, 42, 63, 45, 29, 42, 2, 34, 29, 42, 63, 16, 29, 36, 63, 43, 29, 42, 63, 20, 29, 43, 63, 43, 29, 42, 63, 54, 0, 36, 52, 43, 0, 51, 52, 47, 0, 51, 5, 34, 0, 51, 52, 17, 0, 36, 52, 43, 0, 51, 52, 59, 0, 43, 52, 43, 0, 51, 52, 43, 64, 43, 55, 66, 64, 65, 55, 28, 43, 71, 74, 66, 64, 65, 55, 8, 64, 36, 1, 66, 64, 65, 55, 73, 64, 72, 67, 61, 64, 60, 1, 41, 39, 40, 38, 41, 39, 40, 38, 69, 39, 68, 38, 41, 39, 40, 38, 9, 39, 36, 38, 41, 39, 40, 38, 21, 39, 70, 37, 41, 39, 40, 38, 24, 22, 43, 25, 24, 22, 26, 25, 32, 22, 27, 7, 24, 22, 26, 25, 13, 22, 36, 25, 43, 22, 26, 25, 19, 22, 43, 25, 43, 22, 26, 25, 23, 56, 43, 33, 23, 56, 30, 33, 31, 56, 43, 56, 23, 56, 30, 33, 10, 56, 36, 33, 43, 56, 30, 33, 58, 56, 43, 33, 43, 56, 30, 33
.elseif .defined(CPU_65C02)
mnemotab:
	.byte 13, 37, 36, 36, 64, 37, 2, 46, 39, 37, 2, 36, 64, 37, 2, 3, 11, 37, 37, 36, 63, 37, 2, 46, 16, 37, 27, 36, 63, 37, 2, 3, 31, 1, 36, 36, 8, 1, 47, 46, 43, 1, 47, 36, 8, 1, 47, 3, 9, 1, 1, 36, 8, 1, 47, 46, 52, 1, 23, 36, 8, 1, 47, 3, 49, 26, 36, 36, 36, 26, 35, 46, 38, 26, 35, 36, 30, 26, 35, 3, 14, 26, 26, 36, 36, 26, 35, 46, 18, 26, 41, 36, 36, 26, 35, 3, 50, 0, 36, 36, 60, 0, 48, 46, 42, 0, 48, 36, 30, 0, 48, 3, 15, 0, 0, 36, 60, 0, 48, 46, 54, 0, 45, 36, 30, 0, 48, 3, 12, 56, 36, 36, 59, 56, 58, 55, 25, 8, 66, 36, 59, 56, 58, 4, 5, 56, 56, 36, 59, 56, 58, 55, 68, 56, 67, 36, 60, 56, 60, 4, 34, 32, 33, 36, 34, 32, 33, 55, 62, 32, 61, 36, 34, 32, 33, 4, 6, 32, 32, 36, 34, 32, 33, 55, 19, 32, 65, 36, 34, 32, 33, 4, 22, 20, 36, 36, 22, 20, 23, 55, 29, 20, 24, 69, 22, 20, 23, 4, 10, 20, 20, 36, 36, 20, 23, 55, 17, 20, 40, 57, 36, 20, 23, 4, 21, 51, 36, 36, 21, 51, 27, 55, 28, 51, 36, 36, 21, 51, 27, 4, 7, 51, 51, 36, 36, 51, 27, 55, 53, 51, 44, 36, 36, 51, 27, 4
.endif
.else
.error "No CPU type specified!"
.endif

; prints name of mnemo in A
print_mnemo:
	tay
	lda __mnemos1_RUN__,y
	sta tmp10
	lda __mnemos2_RUN__,y
	sta tmp8
	ldx #3
LAFBE:	lda #0
	ldy #5
LAFC2:	asl tmp8
	rol tmp10
	rol a
	dey
	bne LAFC2
	adc #$3F
	jsr bsout
	dex
	bne LAFBE
.ifdef CPU_65C02
	; add numeric suffix to BBR/BBS
	lda tmp_opcode
	and #$0f
	cmp #$0f
	bne :+
	lda tmp_opcode
	lsr
	lsr
	lsr
	lsr
	and #$07
	ora #'0'
	jsr bsout
:
.endif
	jmp print_space

; Go through the list of prefixes (3) and suffixes (3),
; and if the corresponding one of six bits is set in
; prefix_suffix_bitfield, print it.
; Between the prefixes and the suffixes, print the one
; or two byte operand
print_operand:
	ldx #6 ; start with last prefix
LAFD9:	cpx #3
	bne LAFF4 ; between prefixes and suffixes?, print operand
	ldy num_asm_bytes
	beq LAFF4 ; no operands
:	lda prefix_suffix_bitfield
.ifdef CPU_65C02
	cmp #<(S_ZPREL | 2) << 3 ; zp, relative addressing mode
	beq print_zprel
.endif
	cmp #<(S_RELATIVE | 1) << 3 ; relative addressing mode
	php
	jsr load_byte
	plp
	bcs print_branch_target
	jsr print_hex_byte2
	dey
	bne :-
LAFF4:	asl prefix_suffix_bitfield
	bcc :+ ; nothing to print
	lda __asmchars1_RUN__ - 1,x
	jsr bsout
	lda __asmchars2_RUN__ - 1,x
	beq :+ ; no second character
	jsr bsout
:	dex
	bne LAFD9
	rts

print_branch_target:
	jsr zp1_plus_a_2
	tax
	inx
	bne :+
	iny
:	tya
	jsr print_hex_byte2
	txa
	jmp print_hex_byte2

.ifdef CPU_65C02
print_zprel:
	dey
	jsr load_byte
	jsr print_hex_byte2
	lda #','
	jsr bsout
	lda #'$'
	jsr bsout
	iny
	jsr load_byte
	tax
	lda zp1
	pha
	lda zp1+1
	pha
	inc zp1
	bne :+
	inc zp1+1
:	txa
	sec
	jsr print_branch_target
	pla
	sta zp1+1
	pla
	sta zp1
	rts
.endif

LB030:	ldx #0
	stx tmp17
LB035:	jsr basin_if_more
	cmp #' '
	beq LB030
	sta BUF,x
	inx
	cpx #3
	bne LB035
LB044:	dex
	bmi LB05B
	lda BUF,x
	sec
	sbc #$3F
	ldy #5
LB04F:	lsr a
	ror tmp17
	ror tmp16
	dey
	bne LB04F
	beq LB044
LB05B:	rts

LB05C:	ldx #2
LB05E:	jsr basin
	cmp #CR
	beq LB089
	cmp #':'
	beq LB089
	cmp #' '
	beq LB05E
	jsr is_hex_character
	bcs LB081
	jsr get_hex_byte3
	ldy zp1
	sty zp1 + 1
	sta zp1
	lda #'0'
	sta tmp16,x
	inx
LB081:	sta tmp16,x
	inx
	cpx #$17
	bcc LB05E
LB089:	stx tmp10
	rts

LB08D:	ldx #0
	stx tmp4
	lda tmp6 ; opcode
	jsr decode_mnemo_2
	ldx prefix_suffix_bitfield
	stx tmp8
	tax
	lda __mnemos2_RUN__,x
	jsr LB130
	lda __mnemos1_RUN__,x
	jmp LB130

LB0AB:	ldx #6
LB0AD:	cpx #3
	bne LB0C5
	ldy num_asm_bytes
	beq LB0C5
LB0B6:	lda prefix_suffix_bitfield
	cmp #<(S_RELATIVE | 1) << 3 ; relative addressing mode
	lda #$30
	bcs decode_rel
	jsr LB12D
	dey
	bne LB0B6
LB0C5:	asl prefix_suffix_bitfield
	bcc LB0D8
	lda __asmchars1_RUN__ - 1,x
	jsr LB130
	lda __asmchars2_RUN__ - 1,x
	beq LB0D8
	jsr LB130
LB0D8:	dex
	bne LB0AD
	beq LB0E3

decode_rel:
	jsr LB12D
	jsr LB12D
LB0E3:	lda tmp10
	cmp tmp4
	beq LB0EE
	jmp LB13B
LB0EE:	rts

LB0EF:	ldy num_asm_bytes
	beq LB123
	lda tmp8
	cmp #$9D
	bne LB11A
	jsr check_end
	bcc LB10A
	tya
	bne LB12A
	ldx tmp9
	bmi LB12A
	bpl LB112
LB10A:	iny
	bne LB12A
	ldx tmp9
	bpl LB12A
LB112:	dex
	dex
	txa
	ldy num_asm_bytes
	bne LB11D
LB11A:	lda zp1 + 1,y
LB11D:	jsr store_byte
	dey
	bne LB11A
LB123:	lda tmp6
	jsr store_byte
	rts

LB12A:	jmp input_loop

LB12D:	jsr LB130
LB130:	stx tmp3
	ldx tmp4
	cmp tmp16,x
	beq LB146
LB13B:	inc tmp6
	beq LB143
	jmp LAE61

LB143:	jmp input_loop

LB146:	inx
	stx tmp4
	ldx tmp3
	rts

; ----------------------------------------------------------------
; assembler tables
; ----------------------------------------------------------------
addmode_table:
.if .defined(CPU_6502)
	.byte ADDMODE_IM2 << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ZPG
	.byte ADDMODE_IM2 << 4 | ADDMODE_IM3
	.byte ADDMODE_IMP << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ZPX
	.byte ADDMODE_IM2 << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ABX

	.byte ADDMODE_ABS << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IM2 << 4 | ADDMODE_IM3
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ZPX
	.byte ADDMODE_IM2 << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ABX

	.byte ADDMODE_IM2 << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ZPG
	.byte ADDMODE_IM2 << 4 | ADDMODE_IM3
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ZPX
	.byte ADDMODE_IM2 << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ABX

	.byte ADDMODE_IM2 << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ZPG
	.byte ADDMODE_IM2 << 4 | ADDMODE_IM3
	.byte ADDMODE_IND << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ZPX
	.byte ADDMODE_IM2 << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ABX

	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IM2 << 4 | ADDMODE_IM2
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPY
	.byte ADDMODE_IM2 << 4 | ADDMODE_IM2
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP

	.byte ADDMODE_IMM << 4 | ADDMODE_IMM
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IM2 << 4 | ADDMODE_IM2
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPY
	.byte ADDMODE_IM2 << 4 | ADDMODE_IM2
	.byte ADDMODE_ABX << 4 | ADDMODE_ABY

	.byte ADDMODE_IMM << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IM2 << 4 | ADDMODE_IM2
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ZPX
	.byte ADDMODE_IM2 << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ABX

	.byte ADDMODE_IMM << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IM2 << 4 | ADDMODE_IM2
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ZPX
	.byte ADDMODE_IM2 << 4 | ADDMODE_IMP
	.byte ADDMODE_IMP << 4 | ADDMODE_ABX

	.byte ADDMODE_IZX << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMM << 4 | ADDMODE_ABS
	.byte ADDMODE_IZY << 4 | ADDMODE_ZPX
	.byte ADDMODE_ABY << 4 | ADDMODE_ABX
.elseif .defined(CPU_6502ILL)
	.byte ADDMODE_IMP << 4 | ADDMODE_IZX
	.byte ADDMODE_IMP << 4 | ADDMODE_IZX
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IMP << 4 | ADDMODE_IZY
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABS << 4 | ADDMODE_IZX
	.byte ADDMODE_IMP << 4 | ADDMODE_IZX
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IMP << 4 | ADDMODE_IZY
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_IMP << 4 | ADDMODE_IZX
	.byte ADDMODE_IMP << 4 | ADDMODE_IZX
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IMP << 4 | ADDMODE_IZY
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_IMP << 4 | ADDMODE_IZX
	.byte ADDMODE_IMP << 4 | ADDMODE_IZX
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IND << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IMP << 4 | ADDMODE_IZY
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IMP << 4 | ADDMODE_IZY
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPY << 4 | ADDMODE_ZPY
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABY << 4 | ADDMODE_ABY
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IMP << 4 | ADDMODE_IZY
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPY << 4 | ADDMODE_ZPY
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABY << 4 | ADDMODE_ABY
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IMP << 4 | ADDMODE_IZY
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IMP << 4 | ADDMODE_IZY
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
.elseif .defined(CPU_65C02)
	.byte ADDMODE_IMP << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ZPR
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IZP << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ZPR
	.byte ADDMODE_ABS << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ZPR
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IZP << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ZPR
	.byte ADDMODE_IMP << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ZPR
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IZP << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ZPR
	.byte ADDMODE_IMP << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_IND << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ZPR
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IZP << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_IAX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ZPR
	.byte ADDMODE_REL << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ZPR
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IZP << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPY << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ZPR
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ZPR
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IZP << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPY << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABX << 4 | ADDMODE_ABX
	.byte ADDMODE_ABY << 4 | ADDMODE_ZPR
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ZPR
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IZP << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ZPR
	.byte ADDMODE_IMM << 4 | ADDMODE_IZX
	.byte ADDMODE_IMM << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_ZPG << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_IMM
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABS
	.byte ADDMODE_ABS << 4 | ADDMODE_ZPR
	.byte ADDMODE_REL << 4 | ADDMODE_IZY
	.byte ADDMODE_IZP << 4 | ADDMODE_IMP
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPX
	.byte ADDMODE_ZPX << 4 | ADDMODE_ZPG
	.byte ADDMODE_IMP << 4 | ADDMODE_ABY
	.byte ADDMODE_IMP << 4 | ADDMODE_IMP
	.byte ADDMODE_ABS << 4 | ADDMODE_ABX
	.byte ADDMODE_ABX << 4 | ADDMODE_ZPR
.else
.error "No CPU type specified!"
.endif

P_NONE     = 0
P_DOLLAR   = 1 << 7
P_PAREN    = 1 << 6
P_HASH     = 1 << 5
S_X        = 1 << 4
S_PAREN    = 1 << 3
S_Y        = 1 << 2
; use otherwise illegal combinations for the special cases
S_RELATIVE = S_X | S_PAREN | S_Y
.ifdef CPU_65C02
S_ZPREL    = S_X | S_Y
.endif

.macro addmode_detail symbol, bytes, flags
	symbol = * - addmode_detail_table
	.byte flags | bytes
.endmacro

addmode_detail_table:
	addmode_detail ADDMODE_IMP, 0, P_NONE ; implied
	addmode_detail ADDMODE_IMM, 1, P_HASH ; immediate
	addmode_detail ADDMODE_ZPG, 1, P_DOLLAR ; zero page
	addmode_detail ADDMODE_ABS, 2, P_DOLLAR ; absolute
.ifdef CPU_6502
	addmode_detail ADDMODE_IM2, 0, P_NONE ; implied
	addmode_detail ADDMODE_IM3, 0, P_NONE ; implied
.endif
	addmode_detail ADDMODE_IZX, 1, P_PAREN | S_X | S_PAREN ; X indexed indirect
	addmode_detail ADDMODE_IZY, 1, P_PAREN | S_PAREN | S_Y ; indirect Y indexed
	addmode_detail ADDMODE_ZPX, 1, P_DOLLAR | S_X ; zero page X indexed
	addmode_detail ADDMODE_ABX, 2, P_DOLLAR | S_X ; absolute X indexed
	addmode_detail ADDMODE_ABY, 2, P_DOLLAR | S_Y ; absolute Y indexed
	addmode_detail ADDMODE_IND, 2, P_PAREN | S_PAREN ; absolute indirect
	addmode_detail ADDMODE_ZPY, 1, P_DOLLAR | S_Y ; zero page Y indexed
	addmode_detail ADDMODE_REL,1, P_DOLLAR | S_RELATIVE ; relative
.ifdef CPU_65C02
	addmode_detail ADDMODE_IAX, 2, P_PAREN | S_X | S_PAREN ; X indexed indirect
	addmode_detail ADDMODE_IZP, 1, P_PAREN | S_PAREN ; zp indirect
	addmode_detail ADDMODE_ZPR, 2, P_DOLLAR | S_ZPREL ; zp, relative
.endif

.macro asmchars c1, c2
.segment "asmchars1"
	.byte c1
.segment "asmchars2"
	.byte c2
.endmacro

	; suffixes
	asmchars ',', 'Y' ; 1
	asmchars ')', 0	  ; 2
	asmchars ',', 'X' ; 3
	; prefixes
	asmchars '#', '$' ; 4
	asmchars '(', '$' ; 5
	asmchars '$', 0	  ; 6

; encoded mnemos:
; every combination of a byte of mnemos1 and mnemos2
; encodes 3 ascii characters

.macro mnemo c1, c2, c3
.segment "mnemos1"
	.byte (c1 - $3F) << 3 | (c2 - $3F) >> 2
.segment "mnemos2"
	.byte <((c2 - $3F) << 6 | (c3 - $3F) << 1)
.endmacro

.if .defined(CPU_6502)
; 64 entries
	mnemo 'B','R','K'
	mnemo 'P','H','P'
	mnemo 'B','P','L'
	mnemo 'C','L','C'
	mnemo 'J','S','R'
	mnemo 'P','L','P'
	mnemo 'B','M','I'
	mnemo 'S','E','C'
	mnemo 'R','T','I'
	mnemo 'P','H','A'
	mnemo 'B','V','C'
	mnemo 'C','L','I'
	mnemo 'R','T','S'
	mnemo 'P','L','A'
	mnemo 'B','V','S'
	mnemo 'S','E','I'
	mnemo '?','?','?'
	mnemo 'D','E','Y'
	mnemo 'B','C','C'
	mnemo 'T','Y','A'
	mnemo 'L','D','Y'
	mnemo 'T','A','Y'
	mnemo 'B','C','S'
	mnemo 'C','L','V'
	mnemo 'C','P','Y'
	mnemo 'I','N','Y'
	mnemo 'B','N','E'
	mnemo 'C','L','D'
	mnemo 'C','P','X'
	mnemo 'I','N','X'
	mnemo 'B','E','Q'
	mnemo 'S','E','D'
	mnemo '?','?','?'
	mnemo 'B','I','T'
	mnemo 'J','M','P'
	mnemo 'J','M','P'
	mnemo 'S','T','Y'
	mnemo 'L','D','Y'
	mnemo 'C','P','Y'
	mnemo 'C','P','X'
	mnemo 'T','X','A'
	mnemo 'T','X','S'
	mnemo 'T','A','X'
	mnemo 'T','S','X'
	mnemo 'D','E','X'
	mnemo '?','?','?'
	mnemo 'N','O','P'
	mnemo '?','?','?'
	mnemo 'A','S','L'
	mnemo 'R','O','L'
	mnemo 'L','S','R'
	mnemo 'R','O','R'
	mnemo 'S','T','X'
	mnemo 'L','D','X'
	mnemo 'D','E','C'
	mnemo 'I','N','C'
	mnemo 'O','R','A'
	mnemo 'A','N','D'
	mnemo 'E','O','R'
	mnemo 'A','D','C'
	mnemo 'S','T','A'
	mnemo 'L','D','A'
	mnemo 'C','M','P'
	mnemo 'S','B','C'
.elseif .defined(CPU_6502ILL)
	mnemo 'A','D','C'
	mnemo 'A','H','X'
	mnemo 'A','L','R'
	mnemo 'A','N','C'
	mnemo 'A','N','D'
	mnemo 'A','R','R'
	mnemo 'A','S','L'
	mnemo 'A','X','S'
	mnemo 'B','C','C'
	mnemo 'B','C','S'
	mnemo 'B','E','Q'
	mnemo 'B','I','T'
	mnemo 'B','M','I'
	mnemo 'B','N','E'
	mnemo 'B','P','L'
	mnemo 'B','R','K'
	mnemo 'B','V','C'
	mnemo 'B','V','S'
	mnemo 'C','L','C'
	mnemo 'C','L','D'
	mnemo 'C','L','I'
	mnemo 'C','L','V'
	mnemo 'C','M','P'
	mnemo 'C','P','X'
	mnemo 'C','P','Y'
	mnemo 'D','C','P'
	mnemo 'D','E','C'
	mnemo 'D','E','X'
	mnemo 'D','E','Y'
	mnemo 'E','O','R'
	mnemo 'I','N','C'
	mnemo 'I','N','X'
	mnemo 'I','N','Y'
	mnemo 'I','S','C'
	mnemo 'J','M','P'
	mnemo 'J','S','R'
	mnemo 'K','I','L'
	mnemo 'L','A','S'
	mnemo 'L','A','X'
	mnemo 'L','D','A'
	mnemo 'L','D','X'
	mnemo 'L','D','Y'
	mnemo 'L','S','R'
	mnemo 'N','O','P'
	mnemo 'O','R','A'
	mnemo 'P','H','A'
	mnemo 'P','H','P'
	mnemo 'P','L','A'
	mnemo 'P','L','P'
	mnemo 'R','L','A'
	mnemo 'R','O','L'
	mnemo 'R','O','R'
	mnemo 'R','R','A'
	mnemo 'R','T','I'
	mnemo 'R','T','S'
	mnemo 'S','A','X'
	mnemo 'S','B','C'
	mnemo 'S','E','C'
	mnemo 'S','E','D'
	mnemo 'S','E','I'
	mnemo 'S','H','X'
	mnemo 'S','H','Y'
	mnemo 'S','L','O'
	mnemo 'S','R','E'
	mnemo 'S','T','A'
	mnemo 'S','T','X'
	mnemo 'S','T','Y'
	mnemo 'T','A','S'
	mnemo 'T','A','X'
	mnemo 'T','A','Y'
	mnemo 'T','S','X'
	mnemo 'T','X','A'
	mnemo 'T','X','S'
	mnemo 'T','Y','A'
	mnemo 'X','A','A'
.elseif .defined(CPU_65C02)
	mnemo 'A','D','C'
	mnemo 'A','N','D'
	mnemo 'A','S','L'
	mnemo 'B','B','R'
	mnemo 'B','B','S'
	mnemo 'B','C','C'
	mnemo 'B','C','S'
	mnemo 'B','E','Q'
	mnemo 'B','I','T'
	mnemo 'B','M','I'
	mnemo 'B','N','E'
	mnemo 'B','P','L'
	mnemo 'B','R','A'
	mnemo 'B','R','K'
	mnemo 'B','V','C'
	mnemo 'B','V','S'
	mnemo 'C','L','C'
	mnemo 'C','L','D'
	mnemo 'C','L','I'
	mnemo 'C','L','V'
	mnemo 'C','M','P'
	mnemo 'C','P','X'
	mnemo 'C','P','Y'
	mnemo 'D','E','C'
	mnemo 'D','E','X'
	mnemo 'D','E','Y'
	mnemo 'E','O','R'
	mnemo 'I','N','C'
	mnemo 'I','N','X'
	mnemo 'I','N','Y'
	mnemo 'J','M','P'
	mnemo 'J','S','R'
	mnemo 'L','D','A'
	mnemo 'L','D','X'
	mnemo 'L','D','Y'
	mnemo 'L','S','R'
	mnemo 'N','O','P'
	mnemo 'O','R','A'
	mnemo 'P','H','A'
	mnemo 'P','H','P'
	mnemo 'P','H','X'
	mnemo 'P','H','Y'
	mnemo 'P','L','A'
	mnemo 'P','L','P'
	mnemo 'P','L','X'
	mnemo 'P','L','Y'
	mnemo 'R','M','B'
	mnemo 'R','O','L'
	mnemo 'R','O','R'
	mnemo 'R','T','I'
	mnemo 'R','T','S'
	mnemo 'S','B','C'
	mnemo 'S','E','C'
	mnemo 'S','E','D'
	mnemo 'S','E','I'
	mnemo 'S','M','B'
	mnemo 'S','T','A'
	mnemo 'S','T','P'
	mnemo 'S','T','X'
	mnemo 'S','T','Y'
	mnemo 'S','T','Z'
	mnemo 'T','A','X'
	mnemo 'T','A','Y'
	mnemo 'T','R','B'
	mnemo 'T','S','B'
	mnemo 'T','S','X'
	mnemo 'T','X','A'
	mnemo 'T','X','S'
	mnemo 'T','Y','A'
	mnemo 'W','A','I'
.else
.error "No CPU type specified!"
.endif

; XXX this detects :;<=>?@ as hex characters, see also get_hex_digit
is_hex_character:
	cmp #'0'
	bcc :+
	cmp #'F' + 1
	rts
:	sec
	rts

disassemble_line:
	jsr print_hex_16
	jsr print_space
	jsr decode_mnemo
	jsr print_asm_bytes
	jsr print_mnemo
	jmp print_operand
