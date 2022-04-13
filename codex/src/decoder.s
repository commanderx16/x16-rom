;;;
;;; Assembly decoder for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020-2022 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.exportzp MODE_NONE, MODE_IMMED, MODE_ZP, MODE_ZP_X, MODE_ZP_Y, MODE_ZP_X_IND
	.exportzp MODE_ZP_IND, MODE_ZP_IND_Y, MODE_ABS, MODE_ABS_X, MODE_ABS_Y
	.exportzp MODE_IND, MODE_ABS_X_IND, MODE_ACC, MODE_BRANCH, MODE_ZP_BIT
	.exportzp MODE_ZP_REL, MODE_UNK, MODE_MASK, MODE_LAST

	.export mnemonics, decode_next_instruction, decode_get_byte_count, decode_next_argument, decode_append_next_argument
	.export decode_push_char, decode_terminate
	.export decode_get_entry, decode_push_hex, decode_push_hex_word, decode_push_label_or_hex_core

	.export inst_ADC, inst_AND, inst_ASL, inst_BBR, inst_BBS, inst_BCC, inst_BCS, inst_BEQ
	.export inst_BIT, inst_BMI, inst_BNE, inst_BPL, inst_BRA, inst_BRK, inst_BVC, inst_BVS
	.export inst_CLC, inst_CLD, inst_CLI, inst_CLV, inst_CMP, inst_CPX, inst_CPY, inst_DEC
	.export inst_DEX, inst_DEY, inst_EOR, inst_INC, inst_INX, inst_INY, inst_JMP, inst_JSR
	.export inst_LDA, inst_LDX, inst_LDY, inst_LSR, inst_NOP, inst_ORA, inst_PHA, inst_PHP
	.export inst_PHX, inst_PHY, inst_PLA, inst_PLP, inst_PLX, inst_PLY, inst_RMB, inst_ROL
	.export inst_ROR, inst_RTI, inst_RTS, inst_SBC, inst_SEC, inst_SED, inst_SEI, inst_SMB
	.export inst_STA, inst_STP, inst_STX, inst_STY, inst_STZ, inst_TAX, inst_TAY, inst_TRB
	.export inst_TSB, inst_TSX, inst_TXA, inst_TXS, inst_TYA, inst_WAI, inst_UNK

	.export str_decoder_po_byte, str_decoder_po_word, str_decoder_po_pstr, str_decoder_po_cstr
	
	.include "bank.inc"
	.include "bank_assy_vars.inc"
	.include "decoder_vars.inc"
	.include "encode.inc"
	.include "meta.inc"
	.include "meta_i.inc"
	.include "screen.inc"
	.include "x16_kernal.inc"

	
;; Decoder tries to keep r10 pointing to the decoded_str

;;
;; Raw instruction menmonics, created by an offline "compressor". Each entry point goes to a 3 character mnemonic.
;;
mnemonics
	
inst_STZ   .byte "STZ"
inst_BRK   .byte "BRK"
inst_SEC   .byte "SE"
inst_CPY   .byte "CPY"
inst_TXA   .byte "TXA"
inst_TSX   .byte "TSX"
inst_STX   .byte "S"
inst_TXS   .byte "TX"
inst_STY   .byte "S"
inst_TYA   .byte "TYA"
inst_BVS   .byte "BV"
inst_STP   .byte "ST"
inst_PLP   .byte "PL"
inst_PLY   .byte "PLY"
inst_NOP   .byte "NO"
inst_PHY   .byte "PHY"
inst_BVC   .byte "BV"
inst_CPX   .byte "CPX"
inst_TAY   .byte "TAY"
inst_BCS   .byte "BC"
inst_STA   .byte "S"
inst_TAX   .byte "TAX"
inst_BIT   .byte "BI"
inst_TRB   .byte "TR"
inst_BBS   .byte "BB"
inst_SMB   .byte "SM"
inst_BNE   .byte "BN"
inst_EOR   .byte "EO"
inst_RTS   .byte "R"
inst_TSB   .byte "T"
inst_SBC   .byte "S"
inst_BCC   .byte "BC"
inst_CMP   .byte "CM"
inst_PHA   .byte "PHA"
inst_JSR   .byte "JS" ; * 
inst_RMB   .byte "RM"
inst_BBR   .byte "B"
inst_BRA   .byte "BR"
inst_ADC   .byte "AD"
inst_CLC   .byte "CL"
inst_CLD   .byte "C"
inst_LDA   .byte "LD"
inst_AND   .byte "AN"
inst_DEC   .byte "DE"
inst_CLI   .byte "CL"
inst_INC   .byte "IN"
inst_CLV   .byte "CLV"
inst_LDX   .byte "LDX"
inst_RTI   .byte "RT"
inst_INX   .byte "INX"
inst_JMP   .byte "JM"
inst_PHP   .byte "PH"
inst_PHX   .byte "PHX"
inst_BEQ   .byte "BEQ"
inst_BPL   .byte "B"
inst_PLA   .byte "PL"
inst_ASL   .byte "AS"
inst_LDY   .byte "LDY"
inst_WAI   .byte "WA"
inst_INY   .byte "INY"
inst_PLX   .byte "PLX"
inst_ROL   .byte "RO"
inst_LSR   .byte "LS"
inst_ROR   .byte "R"
inst_ORA   .byte "ORA"
inst_BMI   .byte "BMI"
inst_DEX   .byte "DEX"
inst_SED   .byte "SE"
inst_DEY   .byte "DEY"
inst_SEI   .byte "SEI"
	
inst_UNK        .byte "???"
	
	.macro instr str,count,mode
	   .byte (str-mnemonics)
	   .byte $ff & (count*$20 + mode)
	.endmacro

	.macro unkinst
	   .byte (inst_UNK-mnemonics)
	   .byte $20 + MODE_UNK
	.endmacro

	;; Use care if renumbering these enumerations.
	;; Encoder .encoder_parse_indexed relies upon the
	;; relative locations for proper operation. Also
	;; decode_arg_dispatch (this module) and edit_relocate
	;; has an order dependency.
	     
	MODE_NONE=0
	MODE_IMMED=1
	MODE_ZP=2
	MODE_ZP_X=3
	MODE_ZP_Y=4
	MODE_ZP_X_IND=5
	MODE_ZP_IND=6
	MODE_ZP_IND_Y=7
	MODE_ABS=8
	MODE_ABS_X=9
	MODE_ABS_Y=10
	MODE_IND=11
	MODE_ABS_X_IND=12
	MODE_ACC=13
	MODE_BRANCH=14
	MODE_ZP_BIT=15
	MODE_ZP_REL=16        
	MODE_UNK=17

	MODE_MASK=$1f
	MODE_LAST=$80           ; indicates last record in decoder/encoder tables.

;;
;; Decode table, with mnemonic, byte count, and addressing mode
;;
	     
decode_table

;; 0X
	instr  inst_BRK,1,MODE_NONE            ; 00
	instr  inst_ORA,2,MODE_ZP_X_IND        ; 01
	unkinst                                ; 02
	unkinst                                ; 03
	instr  inst_TSB,2,MODE_ZP              ; 04
	instr  inst_ORA,2,MODE_ZP              ; 05
	instr  inst_ASL,2,MODE_ZP              ; 06
	instr  inst_RMB,2,MODE_ZP_BIT          ; 07
	instr  inst_PHP,1,MODE_NONE            ; 08
	instr  inst_ORA,2,MODE_IMMED           ; 09
	instr  inst_ASL,1,MODE_ACC             ; 0A
	unkinst                                ; 0B
	instr  inst_TSB,3,MODE_ABS             ; 0C
	instr  inst_ORA,3,MODE_ABS             ; 0D
	instr  inst_ASL,3,MODE_ABS             ; 0E
	instr  inst_BBR,3,MODE_ZP_REL          ; 0F

;; 1X
	instr  inst_BPL,2,MODE_BRANCH          ; 10
	instr  inst_ORA,2,MODE_ZP_IND_Y        ; 11
	instr  inst_ORA,2,MODE_ZP_IND          ; 12
	unkinst                                ; 13
	instr  inst_TRB,2,MODE_ZP              ; 14
	instr  inst_ORA,2,MODE_ZP_X            ; 15
	instr  inst_ASL,2,MODE_ZP_X            ; 16
	instr  inst_RMB,2,MODE_ZP_BIT          ; 17
	instr  inst_CLC,1,MODE_NONE            ; 18
	instr  inst_ORA,3,MODE_ABS_Y           ; 19
	instr  inst_INC,1,MODE_ACC             ; 1A
	unkinst                                ; 1B
	instr  inst_TRB,3,MODE_ABS             ; 1C
	instr  inst_ORA,3,MODE_ABS_X           ; 1D
	instr  inst_ASL,3,MODE_ABS_X           ; 1E
	instr  inst_BBR,3,MODE_ZP_REL          ; 1F

;; 2x 
	instr inst_JSR,3,MODE_ABS              ; 20
	instr inst_AND,2,MODE_ZP_X_IND         ; 21
	unkinst                                ; 22
	unkinst                                ; 23
	instr inst_BIT,2,MODE_ZP               ; 24
	instr inst_AND,2,MODE_ZP               ; 25
	instr inst_ROL,2,MODE_ZP               ; 26
	instr inst_RMB,2,MODE_ZP_BIT           ; 27
	instr inst_PLP,1,MODE_NONE             ; 28
	instr inst_AND,2,MODE_IMMED            ; 29
	instr inst_ROL,1,MODE_ACC              ; 2A
	unkinst                                ; 2B
	instr inst_BIT,3,MODE_ABS              ; 2C
	instr inst_AND,3,MODE_ABS              ; 2D
	instr inst_ROL,3,MODE_ABS              ; 2E
	instr inst_BBR,3,MODE_ZP_REL           ; 2F
	
;; 3x
	instr inst_BMI,2,MODE_BRANCH           ; 30
	instr inst_AND,2,MODE_ZP_IND_Y         ; 31
	instr inst_AND,2,MODE_ZP_IND           ; 32
	unkinst                                ; 33
	instr inst_BIT,2,MODE_ZP_X             ; 34
	instr inst_AND,2,MODE_ZP_X             ; 35
	instr inst_ROL,2,MODE_ZP_X             ; 36
	instr inst_RMB,2,MODE_ZP_BIT           ; 37
	instr inst_SEC,1,MODE_NONE             ; 38
	instr inst_AND,3,MODE_ABS_Y            ; 39
	instr inst_DEC,1,MODE_ACC              ; 3A
	unkinst                                ; 3B
	instr inst_BIT,3,MODE_ABS_X            ; 3C
	instr inst_AND,3,MODE_ABS_X            ; 3D
	instr inst_ROL,3,MODE_ABS_X            ; 3E
	instr inst_BBR,3,MODE_ZP_REL           ; 3F

;; 4x
	instr inst_RTI,1,MODE_NONE             ; 40
	instr inst_EOR,2,MODE_ZP_X_IND         ; 41
	unkinst                                ; 42
	unkinst                                ; 43
	unkinst                                ; 44
	instr inst_EOR,2,MODE_ZP               ; 45
	instr inst_LSR,2,MODE_ZP               ; 46
	instr inst_RMB,2,MODE_ZP_BIT           ; 47
	instr inst_PHA,1,MODE_NONE             ; 48
	instr inst_EOR,2,MODE_IMMED            ; 49
	instr inst_LSR,1,MODE_ACC              ; 4A
	unkinst                                ; 4B
	instr inst_JMP,3,MODE_ABS              ; 4C
	instr inst_EOR,3,MODE_ABS              ; 4D
	instr inst_LSR,3,MODE_ABS              ; 4E
	instr inst_BBR,3,MODE_ZP_REL           ; 4F

;; 5x
	instr inst_BVC,2,MODE_BRANCH           ; 50
	instr inst_EOR,2,MODE_ZP_IND_Y         ; 51
	instr inst_EOR,2,MODE_ZP_IND           ; 52
	unkinst                                ; 53
	unkinst                                ; 54
	instr inst_EOR,2,MODE_ZP_X             ; 55
	instr inst_LSR,2,MODE_ZP_X             ; 56
	instr inst_RMB,2,MODE_ZP_BIT           ; 57
	instr inst_CLI,1,MODE_NONE             ; 58
	instr inst_EOR,3,MODE_ABS_Y            ; 59
	instr inst_PHY,1,MODE_NONE             ; 5A
	unkinst                                ; 5B
	unkinst                                ; 5C
	instr inst_EOR,3,MODE_ABS_X            ; 5D
	instr inst_LSR,3,MODE_ABS_X            ; 5E
	instr inst_BBR,3,MODE_ZP_REL           ; 5F
	
;; 6x
	instr inst_RTS,1,MODE_NONE             ; 60
	instr inst_ADC,2,MODE_ZP_X_IND         ; 61
	unkinst                                ; 62
	unkinst                                ; 63
	instr inst_STZ,2,MODE_ZP               ; 64
	instr inst_ADC,2,MODE_ZP               ; 65
	instr inst_ROR,2,MODE_ZP               ; 66
	instr  inst_RMB,2,MODE_ZP_BIT          ; 67
	instr inst_PLA,1,MODE_NONE             ; 68
	instr inst_ADC,2,MODE_IMMED            ; 69
	instr inst_ROR,1,MODE_ACC              ; 6A
	unkinst                                ; 6B
	instr inst_JMP,3,MODE_IND              ; 6C
	instr inst_ADC,3,MODE_ABS              ; 6D
	instr inst_ROR,3,MODE_ABS              ; 6E
	instr inst_BBS,3,MODE_ZP_REL           ; 6F

;; 7x
	instr inst_BVS,2,MODE_BRANCH           ; 70
	instr inst_ADC,2,MODE_ZP_IND_Y         ; 71
	instr inst_ADC,2,MODE_ZP_IND           ; 72
	unkinst                                ; 73
	instr inst_STZ,2,MODE_ZP_X             ; 74
	instr inst_ADC,2,MODE_ZP_X             ; 75
	instr inst_ROR,2,MODE_ZP_X             ; 76
	instr inst_RMB,2,MODE_ZP_BIT           ; 77
	instr inst_SEI,1,MODE_NONE             ; 78
	instr inst_ADC,3,MODE_ABS_Y            ; 79
	instr inst_PLY,1,MODE_NONE             ; 7A
	unkinst                                ; 7B
	instr inst_JMP,3,MODE_ABS_X_IND        ; 7C
	instr inst_ADC,3,MODE_ABS_X            ; 7D
	instr inst_ROR,3,MODE_ABS_X            ; 7E
	instr inst_BBR,3,MODE_ZP_REL           ; 7F

;; 8x
	instr inst_BRA,2,MODE_BRANCH           ; 80
	instr inst_STA,2,MODE_ZP_X_IND         ; 81
	unkinst                                ; 82
	unkinst                                ; 83
	instr inst_STY,2,MODE_ZP               ; 84
	instr inst_STA,2,MODE_ZP               ; 85
	instr inst_STX,2,MODE_ZP               ; 86
	unkinst                                ; 87
	instr inst_DEY,1,MODE_NONE             ; 88
	instr inst_BIT,2,MODE_IMMED            ; 89
	instr inst_TXA,1,MODE_NONE             ; 8A
	unkinst                                ; 8B
	instr inst_STY,3,MODE_ABS              ; 8C
	instr inst_STA,3,MODE_ABS              ; 8D
	instr inst_STX,3,MODE_ABS              ; 8E
	instr inst_BBS,3,MODE_ZP_REL           ; 8F

;; 9x
	instr inst_BCC,2,MODE_BRANCH           ; 90
	instr inst_STA,2,MODE_ZP_IND_Y         ; 91
	instr inst_STA,2,MODE_ZP_IND           ; 92
	unkinst                                ; 93
	instr inst_STY,2,MODE_ZP_X             ; 94
	instr inst_STA,2,MODE_ZP_X             ; 95
	instr inst_STX,2,MODE_ZP_Y             ; 96
	unkinst                                ; 97
	instr inst_TYA,1,MODE_NONE             ; 98
	instr inst_STA,3,MODE_ABS_Y            ; 99
	instr inst_TXS,1,MODE_NONE             ; 9A
	unkinst                                ; 9B
	instr inst_STZ,3,MODE_ABS              ; 9C
	instr inst_STA,3,MODE_ABS_X            ; 9D
	instr inst_STZ,3,MODE_ABS_X            ; 9E
	instr inst_BBS,3,MODE_ZP_REL           ; 9F

;; Ax
	instr inst_LDY,2,MODE_IMMED            ; A0
	instr inst_LDA,2,MODE_ZP_X_IND         ; A1
	instr inst_LDX,2,MODE_IMMED            ; A2
	unkinst                                ; A3
	instr inst_LDY,2,MODE_ZP               ; A4
	instr inst_LDA,2,MODE_ZP               ; A5
	instr inst_LDX,2,MODE_ZP               ; A6
	unkinst                                ; A7
	instr inst_TAY,1,MODE_NONE             ; A8
	instr inst_LDA,2,MODE_IMMED            ; A9
	instr inst_TAX,1,MODE_NONE             ; AA
	unkinst                                ; AB
	instr inst_LDY,3,MODE_ABS              ; AC
	instr inst_LDA,3,MODE_ABS              ; AD
	instr inst_LDX,3,MODE_ABS              ; AE
	instr inst_BBS,3,MODE_ZP_REL           ; AF

;; Bx
	instr inst_BCS,2,MODE_BRANCH           ; B0
	instr inst_LDA,2,MODE_ZP_IND_Y         ; B1
	instr inst_LDA,2,MODE_ZP_IND           ; B2
	unkinst                                ; B3
	instr inst_LDY,2,MODE_ZP_X             ; B4
	instr inst_LDA,2,MODE_ZP_X             ; B5
	instr inst_LDX,2,MODE_ZP_Y             ; B6
	unkinst                                ; B7
	instr inst_CLV,1,MODE_NONE             ; B8
	instr inst_LDA,3,MODE_ABS_Y            ; B9
	instr inst_TSX,1,MODE_NONE             ; BA
	unkinst                                ; BB
	instr inst_LDY,3,MODE_ABS_X            ; BC
	instr inst_LDA,3,MODE_ABS_X            ; BD
	instr inst_LDX,3,MODE_ABS_Y            ; BE
	instr inst_BBS,3,MODE_ZP_REL           ; BF

;; Cx
	instr inst_CPY,2,MODE_IMMED            ; C0
	instr inst_CMP,2,MODE_ZP_X_IND         ; C1
	unkinst                                ; C2
	unkinst                                ; C3
	instr inst_CPY,2,MODE_ZP               ; C4
	instr inst_CMP,2,MODE_ZP               ; C5
	instr inst_DEC,2,MODE_ZP               ; C6
	unkinst                                ; C7
	instr inst_INY,1,MODE_NONE             ; C8
	instr inst_CMP,2,MODE_IMMED            ; C9
	instr inst_DEX,1,MODE_NONE             ; CA
	unkinst                                ; CB
	instr inst_CPY,3,MODE_ABS              ; CC
	instr inst_CMP,3,MODE_ABS              ; CD
	instr inst_DEC,3,MODE_ABS              ; CE
	instr inst_BBS,3,MODE_ZP_REL           ; CF

;; Dx
	instr inst_BNE,2,MODE_BRANCH           ; D0
	instr inst_CMP,2,MODE_ZP_IND_Y         ; D1
	instr inst_CMP,2,MODE_ZP_IND           ; D2
	unkinst                                ; D3
	unkinst                                ; D4
	instr inst_CMP,2,MODE_ZP_X             ; D5
	instr inst_DEC,2,MODE_ZP_X             ; D6
	unkinst                                ; D7
	instr inst_CLD,1,MODE_NONE             ; D8
	instr inst_CMP,3,MODE_ABS_Y            ; D9
	instr inst_PHX,1,MODE_NONE             ; DA
	unkinst                                ; DB
	unkinst                                ; DC
	instr inst_CMP,3,MODE_ABS_X            ; DD
	instr inst_DEC,3,MODE_ABS_X            ; DE
	instr inst_BBR,3,MODE_ZP_REL           ; DF
	
	;; Ex
	instr inst_CPX,2,MODE_IMMED            ; E0
	instr inst_SBC,2,MODE_ZP_X_IND         ; E1
	unkinst                                ; E2
	unkinst                                ; E3
	instr inst_CPX,2,MODE_ZP               ; E4
	instr inst_SBC,2,MODE_ZP               ; E5
	instr inst_INC,2,MODE_ZP               ; E6
	unkinst                                ; E7
	instr inst_INX,1,MODE_NONE             ; E8
	instr inst_SBC,2,MODE_IMMED            ; E9
	instr inst_NOP,1,MODE_NONE             ; EA
	unkinst                                ; EB
	instr inst_CPX,3,MODE_ABS              ; EC
	instr inst_SBC,3,MODE_ABS              ; ED
	instr inst_INC,3,MODE_ABS              ; EE
	instr inst_BBS,3,MODE_ZP_REL           ; EF

;; Fx
	instr inst_BEQ,2,MODE_BRANCH           ; F0
	instr inst_SBC,2,MODE_ZP_IND_Y         ; F1
	instr inst_SBC,2,MODE_ZP_IND           ; F2
	unkinst                                ; F3
	unkinst                                ; F4
	instr inst_SBC,2,MODE_ZP_X             ; F5
	instr inst_INC,2,MODE_ZP_X             ; F6
	unkinst                                ; F7
	instr inst_SED,1,MODE_NONE             ; F8
	instr inst_SBC,3,MODE_ABS_Y            ; F9
	instr inst_PLX,1,MODE_NONE             ; FA
	unkinst                                ; FB
	unkinst                                ; FC
	instr inst_SBC,3,MODE_ABS_X            ; FD
	instr inst_INC,3,MODE_ABS_X            ; FE
	instr inst_BBS,3,MODE_ZP_REL           ; FF

	;; Fix for 6502 jmp ($xxff,x) bug
	.align 2
	     
	;; Pseudo Ops
str_decoder_po_byte .byte ".BYTE",0
str_decoder_po_word .byte ".WORD",0
str_decoder_po_pstr .byte ".PSTR",0
str_decoder_po_cstr .byte ".CSTR",0

;; Argument decode methods
decode_arg_dispatch
	.word   decode_arg_unknown      ; MODE_NONE=0, shouldn't be called.... 
	.word   decode_arg_immediate    ; MODE_IMMED=1
	.word   decode_arg_zp           ; MODE_ZP=2
	.word   decode_arg_zp_x         ; MODE_ZP_X=3
	.word   decode_arg_zp_y         ; MODE_ZP_Y=4
	.word   decode_arg_zp_x_ind     ; MODE_ZP_X_IND=5
	.word   decode_arg_zp_ind       ; MODE_ZP_IND=6
	.word   decode_arg_zp_ind_y     ; MODE_ZP_IND_Y=7
	.word   decode_arg_abs          ; MODE_ABS=8
	.word   decode_arg_abs_x        ; MODE_ABS_X=9
	.word   decode_arg_abs_y        ; MODE_ABS_Y=10
	.word   decode_arg_abs_ind      ; MODE_IND=11
	.word   decode_arg_abs_x_ind    ; MODE_ABS_X_IND=12
	.word   decode_arg_acc          ; MODE_ACC=13
	.word   decode_arg_branch       ; MODE_BRANCH=14
	.word   decode_arg_zp_bit      ; MODE_ZP_BIT=15
	.word   decode_arg_zp_rel      ; MODE_ZP_REL=16
	.word   decode_arg_unknown      ; MODE_UNK=17
	
;;
;; Decode next instruction
;; Index into the decode table, get mnemonic index, convert index to address, return in r1
;; Input   A - Opcode byte
;;        r1 - Adddress of instruction
;; Output r0 - String buffer with decoded instruction
;; Clobbers A
;;
decode_next_instruction
	phy

	;; don't use +ld16 here, it clobber A!
	ldx     #<code_buffer
	stx     r10L
	ldx     #>code_buffer
	stx     r10H
	     
	;; Check for data statements first
	lda     (r1)
	pha
	jsr     meta_find_expr
	bne     @decoder_next_instruction_actual
	pushBankVar bank_meta_i
	ldy     #2
	lda     (r1),y
	and     #META_FN_DATA_MASK
	beq     @decoder_next_instruction_pop
	jsr     @decode_pseudo_op
	popBank
	pla
	ply
	rts

@decoder_next_instruction_pop
	popBank              ; came here from inside of the meta check
	     
@decoder_next_instruction_actual
	pla
	  
	jsr     decode_get_entry

	;; Load instruction IDX from table
	lda    (M1)            ; A == idx of mnemonics
	pha                    ; Save it to add to mnemonics
	     
	;;
	;; Add offset to mnemonics starts
	;;
	lda    #>mnemonics
	sta    M2H

	clc
	pla    
	adc    #<mnemonics
	sta    M2L
	bcc    :+
	inc    M2H

:  
	;; 
	;; build string
	;;
	ldy    #0
	lda    (M2),y
	sta    (r10),y
	iny
	lda    (M2),y
	sta    (r10),y
	iny
	lda    (M2),y
	sta    (r10),y
	iny
	lda     #0
	sta    (r10),y 
	sty    decoded_str_next

	MoveW   r10,r0
	ply
	rts

;;
;; Decode a pseudo operation
;; Input r1 - Pointer to expression
;;
@decode_pseudo_op
	ldy     #2
	lda     (r1),y
	and     #META_FN_MASK
	sec
	sbc     #META_DATA_BYTE
	asl
	tay
	LoadW    TMP2,@decode_po_table
	lda     (TMP2),y
	sta     r1L
	iny
	lda     (TMP2),y
	sta     r1H

	stz     decoded_str_next
	ldy     #0
@decode_pseudo_op_loop
	lda     (r1),y
	beq     @decode_pseudo_op_exit
	iny
	phy
	ldy     decoded_str_next
	sta     (r10),y
	inc     decoded_str_next
	ply
	bra     @decode_pseudo_op_loop
	     
@decode_pseudo_op_exit
	rts

@decode_po_table
	.word str_decoder_po_byte
	.word str_decoder_po_word
	.word str_decoder_po_pstr
	.word str_decoder_po_cstr
	               
;;
;; Get the byte count for the instruction in A
;; Input r1 - Address of opcode
;; Output A - The byte count
;;
decode_get_byte_count
	phy
	PushW	r1
	lda     (r1)
	pha
	     
	;; Check to see if it's a data expression
	jsr     meta_find_expr
	bne     @decode_get_instruction_byte_count
	pushBankVar bank_meta_i
	ldy     #2
	lda     (r1),y
	and     #META_FN_DATA_MASK
	beq     @decode_get_non_data_expr
	iny
	lda     (r1),y
	tax                                           ; stash momentarily
	popBank
	ply                                           ; discard old A
	PopW	r1
	ply
	txa
	rts
	     
@decode_get_non_data_expr
	popBank                      ; Came here from inside of the meta check
	      
@decode_get_instruction_byte_count
	pla
	jsr     decode_get_entry
	PopW	r1
	ldy     #1
	lda     (M1),y                  ; Get byte count and mode
	lsr
	lsr
	lsr 
	lsr
	lsr                             ; Reduce complex count/mode to just count
	ply
	rts

;;
;; Decode the next argument for the instruction currently pointed at by r2
;; Input r2 - Address pointing to next instruction
;; Output r0 - Decoded string
;;
decode_next_argument
	stz     decoded_str_next
	stz     code_buffer

;; An entry point that does not zero out code_buffer
decode_append_next_argument
;        PushW   r2
;        MoveW   r2,r1
;        saves 4 bytes over the two macros
	lda     r2L
	sta     r1L
	pha
	lda     r2H
	sta     r1H
	pha     
;

	ldx     #<code_buffer
	stx     r10L
	stx     r0L
	ldx     #>code_buffer
	stx     r10H
	stx     r0H

	jsr     meta_find_expr
	bne     @decode_next_arg_instruction

	;; Check to make sure only data statements are handled here.
	MoveW   r1,r4
	jsr     meta_expr_iter_next
	lda     r12L
	and     #META_FN_DATA_MASK
	beq     @decode_next_arg_instruction
	jsr     decode_next_pseudo_arg
	PopW    r2
	LoadW   r1,code_buffer
	rts

@decode_next_arg_instruction
	PopW    r2
	lda     (r2)
	jsr     decode_get_entry
	ldy     #1
	lda     (M1),y                  ; Get byte count and mode
	and     #MODE_MASK              ; Reduce to mode
	asl
	tax
	beq     @decode_next_argument_exit

	jmp     (decode_arg_dispatch,x)
	;; Will never return, arg decoders perform the final rts
	     
@decode_next_argument_exit
	rts

;;
;; Argument formatters
;;

;;
;; Argument represented by ???
;;
decode_arg_unknown
	lda     #'?'
	tay
	tax
	jsr     decode_push_dual_char
	jsr     decode_push_char
	jsr     decode_terminate
	rts

;;
decode_arg_immediate
	lda     #'#'
	jsr     decode_push_char
	PushW   r1
	MoveW   r2,r1
	jsr     meta_find_expr
	bne     @decode_arg_immed_straight

	MoveW   r1,M2
	pla                                ; discard saved r1
	pla                                ; discard saved r1
	jsr     decode_next_pseudo_arg
	rts

@decode_arg_immed_straight
	PopW    r1
	lda     #'$'
	jsr     decode_push_char

	ldy     #1
	lda     (r2),y
	jsr     decode_push_hex

	jsr     decode_terminate
	rts

;;
decode_arg_zp
	ldy     #1
	lda     (r2),y

	jsr     decode_push_label_or_hex_zp
	
	jsr     decode_terminate
	rts

;;
decode_arg_zp_x
	jsr     decode_arg_zp
	             
	ldx     #','
	ldy     #'X'
	jsr     decode_push_dual_char

	jsr     decode_terminate
	rts

;;
decode_arg_zp_y
	jsr     decode_arg_zp
	             
	ldx     #','
	ldy     #'Y'
	jsr     decode_push_dual_char

	jsr     decode_terminate
	rts

;;
decode_arg_zp_x_ind
	lda     #'('
	jsr     decode_push_char

	jsr     decode_arg_zp_x

	ldx     #')'
	ldy     #0
	jsr     decode_push_dual_char

	rts

;;
decode_arg_zp_ind
	lda     #'('
	jsr     decode_push_char

	jsr     decode_arg_zp

	ldx     #')'
	ldy     #0
	jsr     decode_push_dual_char

	rts

;;
decode_arg_zp_ind_y
	lda     #'('
	jsr     decode_push_char

	jsr     decode_arg_zp

	ldx     #')'
	ldy     #','
	jsr     decode_push_dual_char

	ldx     #'Y'
	ldy     #0
	jsr     decode_push_dual_char

	rts

;;
decode_arg_abs
	jsr     decode_push_label_or_hex

	jsr     decode_terminate
	rts

;;
decode_arg_abs_x
	jsr     decode_arg_abs
	             
	ldx     #','
	ldy     #'X'
	jsr     decode_push_dual_char

	jsr     decode_terminate

	rts

;;
decode_arg_abs_x_ind
	lda     #'('
	jsr     decode_push_char

	jsr     decode_arg_abs_x

	ldx     #')'
	ldy     #0
	jsr     decode_push_dual_char

	rts

;;
decode_arg_abs_y
	jsr     decode_arg_abs

	ldx     #','
	ldy     #'Y'
	jsr     decode_push_dual_char

	jsr     decode_terminate

	rts

;;
decode_arg_abs_ind
	lda     #'('
	jsr     decode_push_char

	jsr     decode_arg_abs

	ldx     #')'
	ldy     #0
	jsr     decode_push_dual_char

	rts

;;
decode_arg_acc
	ldx     #'A'
	ldy     #0
	jsr     decode_push_dual_char

	rts

;;
decode_arg_branch
	ldy     #1
	lda     (r2),y
	ldx     #2                   ; two bytes for a branch
	jsr     decode_push_offset_or_label

	jsr     decode_terminate
	rts
	             
decode_push_offset_or_label
	;; calc absolute address
	;; Prep for addition later
	pha
	lda     r2H
	sta     M1H

	txa                 ; Offset by byte count
	clc
	adc     r2L
	sta     M1L

	bcc     @decode_branch_arg_check
	inc     M1H                
	             
@decode_branch_arg_check
	;; Figure out if adding or subtracting
	pla
	cmp     #0
	bmi     @decode_branch_negative
	             
	;; Add offset to r1 and print_label_or_hex
	clc
	adc     M1L
	sta     M1L
	bcc     @decode_branch_exit
	inc     M1H                
	bra     @decode_branch_exit

@decode_branch_negative
	;; Add negative offset, but carry changes sense because of 2's complement
	clc
	adc     M1L
	sta     M1L
	bcs     @decode_branch_exit
	dec     M1H

@decode_branch_exit
	jsr     decode_push_label_or_hex_core
	rts

;;
;; Special for BBR, BBS, RMB, SMB
;;
decode_arg_zp_bit
	ldy     #0
	lda     (r2),y
	lsr                 ; get bit number
	lsr     
	lsr     
	lsr
	and     #7
	clc
	adc     #$30
	tax
	lda     #','
	tay
	jsr     decode_push_dual_char
	
	ldy     #1
	lda     (r2),y

	jsr     decode_push_label_or_hex_zp

	jsr     decode_terminate
	rts

;;
;; Mode for bbs abd bbr instructions
;;
decode_arg_zp_rel
	jsr	decode_arg_zp_bit
	lda     #','
	jsr     decode_push_char

	;; Get offset
	ldy     #2
	lda     (r2),y
	ldx     #3
	jsr     decode_push_offset_or_label

	;; Calc address

	;; done
	jsr     decode_terminate
	rts
	             
;;
;; Called when an address is a pseudo op
;; Input r1 - ptr to pseudo expression
decode_next_pseudo_arg
	pushBankVar   bank_meta_i
	ldy      #2
	lda      (r1),y
	and      #META_FN_MASK
	asl
	tax
	iny
	lda      (r1),y
	sta      r0L
	iny
	lda      (r1),y
	sta      r0H
	popBank
	jmp      (decode_pseudo_arg_dispatch,x)
	;;  Never return from JMP, will do RTS there

decode_pseudo_arg_dispatch
	.word decode_pseudo_none          ; 0
	.word decode_pseudo_hi_byte       ; 1
	.word decode_pseudo_lo_byte       ; 2
	.word decode_pseudo_byte          ; 3
	.word decode_pseudo_word          ; 4
	.word decode_pseudo_pstr          ; 5
	.word decode_pseudo_cstr	       ; 6

;;
;; Pseudo decoders
;; Input
;;       r2  - instruction ptr
;;       r10 - code_buffer
;;       M1  - Expression ptr
;;
decode_pseudo_none
	rts

	;;
	;; High byte pseudo arg decode.
	;; Shares termination code with Low byte decoder
	;;
decode_pseudo_hi_byte
	lda     #'>'
	bra     decode_pseudo_terminate_value
	      
	;;
	;; Low byte pseudo arg decode
	;; Shares termination code with High byte decoder
	;;
decode_pseudo_lo_byte
	lda     #'<'
	
decode_pseudo_terminate_value
	jsr     decode_push_char
	jsr     decode_push_pseudo_hex_or_label
	rts
	      
	;;
	;;	Decode Pseudo Word works by signaling to decode_pseduo byte to consume two bytes at a time.
	;; R0L is the byte count
	;; R0H is use as the signal flag. 1 == Word sized arguments, 0 == Byte sized arguments
	;;
decode_pseudo_word
	inc 		r0H        ; Indicate that word sized arguments are to be decoded
	
decode_pseudo_byte
	ldy     #$0
@decode_pseudo_byte_loop
	tya
	beq		@decode_pseudo_byte_skip
	lda		#','
	jsr		decode_push_char
@decode_pseudo_byte_skip
	lda 		#'$'
	jsr		decode_push_char
	lda		(r2),y
	sta		TMP1
	lda      r0H	; Check to see if MSB is to be consumed first (e.g. '.word' meta)
	beq      @decode_single_byte
	iny
	lda		(r2),y
	jsr		decode_push_hex
@decode_single_byte
	lda		TMP1
	jsr		decode_push_hex
	iny
	cpy		r0
	bmi		@decode_pseudo_byte_loop
	jsr		decode_terminate
	rts

	;;
	;; Turn a CSTR pseudo into the string representation
	;; Shares exist with the PSTR pseudo decoder
	;;
decode_pseudo_cstr
	lda   #DBL_QUOTE
	jsr   decode_push_char
	ldy   #0
@decode_pseudo_cstr_loop
	lda   (r2),y
	beq   decode_pseudo_string_exit
	jsr   decode_push_char
	iny
	bra   @decode_pseudo_cstr_loop

decode_pseudo_string_exit
	ldx   #DBL_QUOTE
	ldy   #0
	jsr   decode_push_dual_char
	rts

	;;
	;; Turn a PSTR pseudo into the string representation
	;; Shares exist with the CSTR pseudo decoder
	;;
decode_pseudo_pstr
	lda   #DBL_QUOTE
	jsr   decode_push_char
	lda   (r2)
	inc                              ; For end of loop comparison purposes
	sta   TMP1L
	ldy   #1
@decode_pseudo_pstr_loop
	lda   (r2),y
	jsr   decode_push_char
	iny
	cpy   TMP1L
	bmi   @decode_pseudo_pstr_loop

	bra   decode_pseudo_string_exit

;;
;; If the expression has a label, push that, otherwise push the raw value
;; Only called for byte expressions (hi, low, etc)
;;
;; Input M2 - expression ptr
;;
decode_push_pseudo_hex_or_label
	pushBankVar  bank_meta_i
	PushW   r1
	ldy     #3
	lda     (M2),y
	sta     r1L
	iny
	lda     (M2),y
	sta     r1H
	jsr     decoder_find_and_push_label
	PopW    r1
	bra     @decode_push_hex_or_label_exit
	             
@decode_push_hex
	ldy     #'$'
	jsr     decode_push_dual_char
	ldy     #4
	lda     (M2),y
	jsr     decode_push_hex
	dey
	lda     (M2),y
	jsr     decode_push_hex

@decode_push_hex_or_label_exit
	popBank
	jsr     decode_terminate
	rts
	      
;;
;; Given ZP in A, push a label, if found, or just the ZP hex
;; Input A - ZP address
;; Output decode_str - label or zp 
;;
decode_push_label_or_hex_zp
	pha
	stz     r1H
	sta     r1L
	jsr     decoder_find_and_push_label
	bne     @decode_label_or_hex_not_found_zp
	pla                          ; Discard A
	rts

@decode_label_or_hex_not_found_zp
	pla
	pha
	lda     #'$'
	jsr     decode_push_char
	pla
	
	jsr     decode_push_hex

	rts

;;
;; Load address, push a label, if found, or just the ZP hex
;; Input (r2),1 and (r2),2 - address
;; Output decode_str - label or zp 
;;
decode_push_label_or_hex
	ldy     #1
	lda     (r2),y
	sta     M1L

	ldy     #2
	lda     (r2),y
	sta     M1H

	jsr     decode_push_label_or_hex_core
	rts

;;
;; Push a label, if found, or just the hex value
;; Input M1 - Value to push
;;
decode_push_label_or_hex_core
	MoveW   M1,r1
	jsr     decoder_find_and_push_label
	bne     @decode_pl_core_hex
	rts

@decode_pl_core_hex
	lda     #'$'
	jsr     decode_push_char
	lda     r1H
	jsr     decode_push_hex
	lda     r1L
	jsr     decode_push_hex

	rts

;;
;; Push the label, if found
;; Input r1 - Value being searched for
;; If NOT found Z == 0
;; if found Z == 1
;;
decoder_find_and_push_label                
	jsr     meta_find_label
	bne     @decode_label_or_hex_fail

	pushBankVar bank_meta_l
	ldy     #0
@decode_label_or_hex_copy_loop
	lda     (r0),y
	beq     @decode_push_label_exit
	phy
	ldy     decoded_str_next
	inc     decoded_str_next
	sta     (r10),y
	ply
	iny
	bra     @decode_label_or_hex_copy_loop

@decode_push_label_exit
	popBank
	lda     #SUCCESS
	rts
	             
@decode_label_or_hex_fail
	lda     #FAIL
	rts

;;
;; Push character to decode string
;; Input A  - Character to push
;; Clobbers Y
;;
decode_push_char
	phy
	ldy     decoded_str_next
	sta     (r10),y
	inc     decoded_str_next
	ply
	rts

;;
;; Push terminate code_buffer
;; Clobbers Y, A
;;
decode_terminate
	ldy     decoded_str_next
	lda     #0
	sta     (r10),y
	rts

;;
;; Push 2 characters to decode string
;; Input X - first char
;;       Y - second char
;; Clobbers A,Y
;;
decode_push_dual_char
	phy
	ldy     decoded_str_next
	txa
	sta     (r10),y
	iny
	pla
	sta     (r10),y
	iny
	sty     decoded_str_next
	rts

;;
;; Push hex characters as equiv of binary in A
;;
decode_push_hex
	pha
	lsr
	lsr    
	lsr
	lsr
	cmp     #10
	bpl     @decode_push_hex_a1
	adc     #'0'
	bra     @decode_push_hex_do_second
@decode_push_hex_a1
	adc     #'A'-11

@decode_push_hex_do_second
	jsr     decode_push_char

	pla
	and     #$0f

	cmp     #10
	bpl     @decode_push_hex_a2
	adc     #'0'
	bra     @decode_push_hex_done
@decode_push_hex_a2
	adc     #'A'-11

@decode_push_hex_done
	jsr     decode_push_char
	rts
	
;; 
;; Push the entire value of r1 into the decode_buffer
;; 
decode_push_hex_word
	lda     r1H
	jsr     decode_push_hex
	lda     r1L
	jsr     decode_push_hex
	rts

;;
;; Set r1 to point to the table entry for the opcode in A
;; Input A - Opcode
;; Clobbers A
;; Side effect, sets up M1 to point to decode_table
;;
decode_get_entry
	pha
	lda     #>decode_table
	sta     M1H

	pla
	pha
	clc
	adc     #<decode_table
	sta     M1
	bcc     :+
	inc     M1H       
:  
	pla
	clc
	adc     M1
	sta     M1
	bcc     :+
	inc     M1H
:  
	rts


