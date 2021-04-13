;;;
;;; Assembly decoder for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_DECODER__
	__X16_DECODER__=1
	
	.importzp MODE_NONE, MODE_IMMED, MODE_ZP, MODE_ZP_X, MODE_ZP_Y, MODE_ZP_X_IND
	.importzp MODE_ZP_IND, MODE_ZP_IND_Y, MODE_ABS, MODE_ABS_X, MODE_ABS_Y
	.importzp MODE_IND, MODE_ABS_X_IND, MODE_ACC, MODE_BRANCH, MODE_ZP_BIT
	.importzp MODE_ZP_REL, MODE_UNK, MODE_MASK, MODE_LAST

	.import mnemonics, decode_next_instruction, decode_get_byte_count, decode_next_argument, decode_append_next_argument
	.import decode_push_char, decode_terminate
	.import decode_get_entry, decode_push_hex, decode_push_hex_word, decode_push_label_or_hex_core
	.import str_decoder_po_byte, str_decoder_po_word, str_decoder_po_pstr, str_decoder_po_cstr

	.import inst_ADC, inst_AND, inst_ASL, inst_BBR, inst_BBS, inst_BCC, inst_BCS, inst_BEQ
	.import inst_BIT, inst_BMI, inst_BNE, inst_BPL, inst_BRA, inst_BRK, inst_BVC, inst_BVS
	.import inst_CLC, inst_CLD, inst_CLI, inst_CLV, inst_CMP, inst_CPX, inst_CPY, inst_DEC
	.import inst_DEX, inst_DEY, inst_EOR, inst_INC, inst_INX, inst_INY, inst_JMP, inst_JSR
	.import inst_LDA, inst_LDX, inst_LDY, inst_LSR, inst_NOP, inst_ORA, inst_PHA, inst_PHP
	.import inst_PHX, inst_PHY, inst_PLA, inst_PLP, inst_PLX, inst_PLY, inst_RMB, inst_ROL
	.import inst_ROR, inst_RTI, inst_RTS, inst_SBC, inst_SEC, inst_SED, inst_SEI, inst_SMB
	.import inst_STA, inst_STP, inst_STX, inst_STY, inst_STZ, inst_TAX, inst_TAY, inst_TRB
	.import inst_TSB, inst_TSX, inst_TXA, inst_TXS, inst_TYA, inst_WAI, inst_UNK

	.endif
