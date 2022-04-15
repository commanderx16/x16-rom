;;;
;;; Single line assemblers for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020-2022 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.export encode_parse_expression, encode_get_entry, encode_string

	.include "decoder.inc"
	.include "decoder_vars.inc"
	.include "encode_vars.inc"
	.include "meta.inc"
	.include "meta_i.inc"
	.include "screen.inc"
	.include "utility.inc"
	.include "x16_kernal.inc"

	;;
	;; This macro perviously stored offsets instead of pointers. (V 0.5 & earlier)
	;; Offsets could be used for mnemonic references, but keeping the sizes the
	;; same makes the search math (binary search) much easier. The extra 70
	;; bytes are worth it (imho)
	;;
	.macro einstr inst,args
	   .word inst
	   .word args
	.endmacro

	ENCODE_PSEUDO_FLAG='.'
	       
encode_table
	einstr  inst_ADC,args_ADC
	einstr  inst_AND,args_AND
	einstr  inst_ASL,args_ASL
	einstr  inst_BBR,args_BBR
	einstr  inst_BBS,args_BBS
	einstr  inst_BCC,args_BCC
	einstr  inst_BCS,args_BCS
	einstr  inst_BEQ,args_BEQ
	einstr  inst_BIT,args_BIT
	einstr  inst_BMI,args_BMI
	einstr  inst_BNE,args_BNE
	einstr  inst_BPL,args_BPL
	einstr  inst_BRA,args_BRA
	einstr  inst_BRK,args_BRK
	einstr  inst_BVC,args_BVC
	einstr  inst_BVS,args_BVS
	einstr  inst_CLC,args_CLC
	einstr  inst_CLD,args_CLD
	einstr  inst_CLI,args_CLI
	einstr  inst_CLV,args_CLV
	einstr  inst_CMP,args_CMP
	einstr  inst_CPX,args_CPX
	einstr  inst_CPY,args_CPY
	einstr  inst_DEC,args_DEC
	einstr  inst_DEX,args_DEX
	einstr  inst_DEY,args_DEY
	einstr  inst_EOR,args_EOR
	einstr  inst_INC,args_INC
	einstr  inst_INX,args_INX
	einstr  inst_INY,args_INY
	einstr  inst_JMP,args_JMP
	einstr  inst_JSR,args_JSR
	einstr  inst_LDA,args_LDA
	einstr  inst_LDX,args_LDX
	einstr  inst_LDY,args_LDY
	einstr  inst_LSR,args_LSR
	einstr  inst_NOP,args_NOP
	einstr  inst_ORA,args_ORA
	einstr  inst_PHA,args_PHA
	einstr  inst_PHP,args_PHP
	einstr  inst_PHX,args_PHX
	einstr  inst_PHY,args_PHY
	einstr  inst_PLA,args_PLA
	einstr  inst_PLP,args_PLP
	einstr  inst_PLX,args_PLX
	einstr  inst_PLY,args_PLY
	einstr  inst_RMB,args_RMB
	einstr  inst_ROL,args_ROL
	einstr  inst_ROR,args_ROR
	einstr  inst_RTI,args_RTI
	einstr  inst_RTS,args_RTS
	einstr  inst_SBC,args_SBC
	einstr  inst_SEC,args_SEC
	einstr  inst_SED,args_SED
	einstr  inst_SEI,args_SEI
	einstr  inst_SMB,args_SMB
	einstr  inst_STA,args_STA
	einstr  inst_STP,args_STP
	einstr  inst_STX,args_STX
	einstr  inst_STY,args_STY
	einstr  inst_STZ,args_STZ
	einstr  inst_TAX,args_TAX
	einstr  inst_TAY,args_TAY
	einstr  inst_TRB,args_TRB
	einstr  inst_TSB,args_TSB
	einstr  inst_TSX,args_TSX
	einstr  inst_TXA,args_TXA
	einstr  inst_TXS,args_TXS
	einstr  inst_TYA,args_TYA
	einstr  inst_WAI,args_WAI
encode_table_end
	
encode_arguments_table

args_ADC
	.byte MODE_IMMED,                $69
	.byte MODE_ZP,                   $65
	.byte MODE_ZP_X,                 $75
	.byte MODE_ABS,                  $6d
	.byte MODE_ABS_X,                $7d
	.byte MODE_ABS_Y,                $79
	.byte MODE_ZP_X_IND,             $61
	.byte MODE_ZP_IND_Y,             $71
	.byte MODE_ZP_IND | MODE_LAST,   $72

args_AND
	.byte MODE_IMMED,                $29
	.byte MODE_ZP,                   $25
	.byte MODE_ZP_X,                 $35
	.byte MODE_ABS,                  $2d
	.byte MODE_ABS_X,                $3d
	.byte MODE_ABS_Y,                $39
	.byte MODE_ZP_X_IND,             $21
	.byte MODE_ZP_IND_Y,             $31
	.byte MODE_ZP_IND | MODE_LAST,   $32
	
args_ASL
	.byte MODE_NONE,                 $0a
	.byte MODE_ZP,                   $06
	.byte MODE_ZP_X,                 $16
	.byte MODE_ABS,                  $0e
	.byte MODE_ABS_X | MODE_LAST,    $1e
	
args_BBR
	.byte MODE_ZP_REL | MODE_LAST,   $0f         ; Will need bit number added in the parser/encoder
	
args_BBS
	.byte MODE_ZP_REL | MODE_LAST,   $8f         ; Will need bit number added in the parser/encoder
	
args_BCC
	.byte MODE_BRANCH | MODE_LAST,   $90         ; Syntactically it looks ABS, but mode will be matched in get_arg_template
	
args_BCS
	.byte MODE_BRANCH | MODE_LAST,   $B0         ; Syntactically it looks ABS, but mode will be matched in get_arg_template
	
args_BEQ
	.byte MODE_BRANCH | MODE_LAST,   $F0         ; Syntactically it looks ABS, but mode will be matched in get_arg_template
	
args_BIT
	.byte MODE_IMMED,                $89
	.byte MODE_ZP,                   $24
	.byte MODE_ZP_X,                 $34
	.byte MODE_ABS,                  $2c
	.byte MODE_ABS_X | MODE_LAST,    $3c
	
args_BMI
	.byte MODE_BRANCH | MODE_LAST,   $30         ; Syntactically it looks ABS, but mode will be matched in get_arg_template
	
args_BNE
	.byte MODE_BRANCH | MODE_LAST,   $D0         ; Syntactically it looks ABS, but mode will be matched in get_arg_template
	
args_BPL
	.byte MODE_BRANCH | MODE_LAST,   $10         ; Syntactically it looks ABS, but mode will be matched in get_arg_template
	
args_BRA
	.byte MODE_BRANCH | MODE_LAST,   $80         ; Syntactically it looks ABS, but mode will be matched in get_arg_template
	
args_BRK
	.byte MODE_NONE | MODE_LAST,     $00
	
args_BVC
	.byte MODE_BRANCH | MODE_LAST,   $50         ; Syntactically it looks ABS, but mode will be matched in get_arg_template
	
args_BVS
	.byte MODE_BRANCH | MODE_LAST,   $70         ; Syntactically it looks ABS, but mode will be matched in get_arg_template
	
args_CLC
	.byte MODE_NONE | MODE_LAST,     $18
	
args_CLD
	.byte MODE_NONE | MODE_LAST,     $d8
	
args_CLI
	.byte MODE_NONE | MODE_LAST,     $58
	
args_CLV
	.byte MODE_NONE | MODE_LAST,     $b8
	
args_CMP
	.byte MODE_IMMED,                $c9
	.byte MODE_ZP,                   $c5
	.byte MODE_ZP_X,                 $d5
	.byte MODE_ABS,                  $cd
	.byte MODE_ABS_X,                $ee
	.byte MODE_ABS_Y,                $d9
	.byte MODE_ZP_X_IND,             $c1
	.byte MODE_ZP_IND_Y,             $d1
	.byte MODE_ZP_IND | MODE_LAST,   $d2
	
args_CPX
	.byte MODE_IMMED,                $e0
	.byte MODE_ZP,                   $e4
	.byte MODE_ABS | MODE_LAST,      $ec
	
args_CPY
	.byte MODE_IMMED,                $c0
	.byte MODE_ZP,                   $c4
	.byte MODE_ABS | MODE_LAST,      $cc
	
args_DEC
	.byte MODE_NONE,                 $3a
	.byte MODE_ZP,                   $c6
	.byte MODE_ZP_X,                 $ce
	.byte MODE_ABS,                  $ce
	.byte MODE_ABS_X | MODE_LAST,    $de
	
args_DEX
	.byte MODE_NONE | MODE_LAST,     $ca
	
args_DEY
	.byte MODE_NONE | MODE_LAST,     $88
	
args_EOR
	.byte MODE_IMMED,                $49
	.byte MODE_ZP,                   $45
	.byte MODE_ZP_X,                 $55
	.byte MODE_ABS,                  $4D
	.byte MODE_ABS_X,                $5D
	.byte MODE_ABS_Y,                $59
	.byte MODE_ZP_X_IND,             $41
	.byte MODE_ZP_IND_Y,             $51
	.byte MODE_ZP_IND | MODE_LAST,   $52
	
args_INC
	.byte MODE_NONE,                 $1a
	.byte MODE_ZP,                   $e6
	.byte MODE_ZP_X,                 $f6
	.byte MODE_ABS,                  $ee
	.byte MODE_ABS_X | MODE_LAST,    $fe
	
args_INX
	.byte MODE_NONE | MODE_LAST,     $e8
	
args_INY
	.byte MODE_NONE | MODE_LAST,     $c8
	
args_JMP
	.byte MODE_ABS,                   $4c
	.byte MODE_IND,                   $6c
	.byte MODE_ABS_X_IND | MODE_LAST, $7c
	
args_JSR
	.byte MODE_ABS | MODE_LAST,      $20
	
args_LDA
	.byte MODE_IMMED,                $a9
	.byte MODE_ZP,                   $a5
	.byte MODE_ZP_X,                 $b5
	.byte MODE_ABS,                  $ad
	.byte MODE_ABS_X,                $bd
	.byte MODE_ABS_Y,                $b9
	.byte MODE_ZP_X_IND,             $a1
	.byte MODE_ZP_IND_Y,             $b1
	.byte MODE_ZP_IND | MODE_LAST,   $b2
	
args_LDX
	.byte MODE_IMMED,                $a2
	.byte MODE_ZP,                   $a6
	.byte MODE_ZP_Y,                 $b6
	.byte MODE_ABS,                  $ae
	.byte MODE_ABS_Y | MODE_LAST,    $be
	
args_LDY
	.byte MODE_IMMED,                $a0
	.byte MODE_ZP,                   $a4
	.byte MODE_ZP_Y,                 $b4
	.byte MODE_ABS,                  $ac
	.byte MODE_ABS_Y | MODE_LAST,    $bc
	
args_LSR
	.byte MODE_NONE,                 $4a
	.byte MODE_ZP,                   $46
	.byte MODE_ZP_X,                 $56
	.byte MODE_ABS,                  $4e
	.byte MODE_ABS_X | MODE_LAST,    $5e
	
args_NOP
	.byte MODE_NONE | MODE_LAST,     $ea
	
args_ORA
	.byte MODE_IMMED,                $09
	.byte MODE_ZP,                   $05
	.byte MODE_ZP_X,                 $15
	.byte MODE_ABS,                  $0d
	.byte MODE_ABS_X,                $1d
	.byte MODE_ABS_Y,                $19
	.byte MODE_ZP_X_IND,             $01
	.byte MODE_ZP_IND_Y,             $11
	.byte MODE_ZP_IND | MODE_LAST,   $12
	
args_PHA
	.byte MODE_NONE | MODE_LAST,     $48
	
args_PHP
	.byte MODE_NONE | MODE_LAST,     $08
	
args_PHX
	.byte MODE_NONE | MODE_LAST,     $da
	
args_PHY
	.byte MODE_NONE | MODE_LAST,     $5a
	
args_PLA
	.byte MODE_NONE | MODE_LAST,     $68
	
args_PLP
	.byte MODE_NONE | MODE_LAST,     $28
	
args_PLX
	.byte MODE_NONE | MODE_LAST,     $fa
	
args_PLY
	.byte MODE_NONE | MODE_LAST,     $7a
	
args_RMB
	.byte MODE_ZP_BIT | MODE_LAST,   $07         ; Will need bit number added in the parser/encoder
	
args_ROL
	.byte MODE_NONE,                 $2a
	.byte MODE_ZP,                   $26
	.byte MODE_ZP_X,                 $36
	.byte MODE_ABS,                  $2e
	.byte MODE_ABS_X | MODE_LAST,    $3e
	
args_ROR
	.byte MODE_NONE,                 $6a
	.byte MODE_ZP,                   $66
	.byte MODE_ZP_X,                 $76
	.byte MODE_ABS,                  $6e
	.byte MODE_ABS_X | MODE_LAST,    $7e
	
args_RTI
	.byte MODE_NONE | MODE_LAST,     $40
  
args_RTS
	.byte MODE_NONE | MODE_LAST,     $60
	
args_SBC
	.byte MODE_IMMED,                $e9
	.byte MODE_ZP,                   $e5
	.byte MODE_ZP_X,                 $f5
	.byte MODE_ABS,                  $eD
	.byte MODE_ABS_X,                $fD
	.byte MODE_ABS_Y,                $f9
	.byte MODE_ZP_X_IND,             $e1
	.byte MODE_ZP_IND_Y,             $f1
	.byte MODE_ZP_IND | MODE_LAST,   $f2
	
args_SEC
	.byte MODE_NONE | MODE_LAST,     $38
	
args_SED
	.byte MODE_NONE | MODE_LAST,     $f8
	
args_SEI
	.byte MODE_NONE | MODE_LAST,     $78
	
args_SMB
	.byte MODE_ZP_BIT | MODE_LAST,   $87         ; Will need bit number added in the parser/encoder
	
args_STA
	.byte MODE_ZP,                   $85
	.byte MODE_ZP_X,                 $95
	.byte MODE_ABS,                  $8d
	.byte MODE_ABS_X,                $9d
	.byte MODE_ABS_Y,                $99
	.byte MODE_ZP_X_IND,             $81
	.byte MODE_ZP_IND_Y,             $91
	.byte MODE_ZP_IND | MODE_LAST,   $92
	
args_STP
	.byte MODE_NONE | MODE_LAST,     $db
	
args_STX
	.byte MODE_ZP,                   $86
	.byte MODE_ZP_X,                 $96
	.byte MODE_ABS | MODE_LAST,      $8e
	
args_STY
	.byte MODE_ZP,                   $84
	.byte MODE_ZP_X,                 $94
	.byte MODE_ABS | MODE_LAST,      $8c
	
args_STZ
	.byte MODE_ZP,                   $64
	.byte MODE_ZP_X,                 $74
	.byte MODE_ABS,                  $9c
	.byte MODE_ABS_X | MODE_LAST,    $9e
	
args_TAX
	.byte MODE_NONE | MODE_LAST,     $aa
	
args_TAY
	.byte MODE_NONE | MODE_LAST,     $a8
	
args_TRB
	.byte MODE_ZP,                   $14
	.byte MODE_ABS | MODE_LAST,      $1c
	
args_TSB
	.byte MODE_ZP,                   $04
	.byte MODE_ABS | MODE_LAST,      $0c
	
args_TSX
	.byte MODE_NONE | MODE_LAST,     $ba
	
args_TXA 
	.byte MODE_NONE | MODE_LAST,     $8a
  
args_TXS
	.byte MODE_NONE | MODE_LAST,     $9a
	
args_TYA
	.byte MODE_NONE | MODE_LAST,     $98
	
args_WAI
	.byte MODE_NONE | MODE_LAST,     $cb
	

;;
;; Encode string - Given a string, encode as a series of bytes
;;
;;                 Does a binary search on instructions to find the matching instruction
;;                 then decodes arguments based on argument candidates
;;
;; Input  r1        - String pointer, must be trimmed
;; Output r1        - Output buffer bytes
;;        r2L       - byte count
;;        Carry = 1 - Unknown instruction
;;              = 0 - Output valid
;; Reg usage (direct use and in get entry)
;;        r2 - Table start
;;        r3 - Table end
;;        r4 - tmp
;;        M1 - pointer into encode_table
;;        M2 - pointer to menmonics for comparison, temporary after menmonic parse
;;
encode_string
	stz      encode_buffer_size
	      
	lda      #' '
	jsr      util_split_string
	PushW    r2                   ; Save argument string

	lda      (r1)
	cmp      #ENCODE_PSEUDO_FLAG
	beq      @encode_string_do_pseudo_op
	      
	jsr      encode_get_entry     ; Return in M1 (r12)
	bcs      @encode_string_pop_then_error

	PopW     r1
	jsr      util_trim_string
	jsr      encode_parse_arguments
	bcs      @encode_string_error
	      
	;; Get matching argument descriptor
	;; A == current parsed mode (possibly might not match)
	jsr      encode_get_argument_template
	bcs      @encode_string_error
	      
	;; emit bytes, r2L = mode, r2H = opcode as extracted from argument template
	lda      r2L
	asl
	tax
	jmp      (encode_parse_emitter_table,x)

	;; Will not return here, emitters will perform the rts

@encode_string_pop_then_error
	pla                           ; Discard pushed r2 from early on in the routine
	pla
	      
@encode_string_error
	sec
	rts

@encode_string_do_pseudo_op
	LoadW    r2,str_decoder_po_byte
	jsr      util_strcmp
	bne      @encode_string_po_chk2
	PopW     r1
	jsr      encode_byte_string
	bcs      @encode_string_po_error
	rts

@encode_string_po_chk2
	LoadW    r2,str_decoder_po_word
	jsr      util_strcmp
	bne      @encode_string_po_chk3
	PopW     r1
	jsr      encode_word_string
	rts
	      
@encode_string_po_chk3
	LoadW    r2,str_decoder_po_pstr
	jsr      util_strcmp
	bne      @encode_string_po_chk4
	PopW     r1
	jsr      encode_pstr_string
	rts

@encode_string_po_chk4
	LoadW    r2,str_decoder_po_cstr
	jsr      util_strcmp
	bne      @encode_string_po_error
	PopW     r1
	jsr      encode_cstr_string
	rts

@encode_string_po_error
	pla
	pla                                    ; discard pushed string pointer
	sec
	rts

	;;
	;; Encode a series of bytes, eg: .byte $01,$02,$42
	;; Input r1 - pointer to string of word values
	;; Output bytes in buffer (encode buffer)
	;;
	;; Shares exist points with encode_word_string
	;;
encode_byte_string
	;; extract a series of bytes and push into the byte buffer
	stz      encode_buffer_size
	LoadW    M1,code_buffer
	PushW    r1

@encode_string_byte_loop
	PopW     r1
	lda      #','
	jsr      util_split_string
	PushW    r2
	lda      (r1)
	beq      encode_byte_word_exit
	jsr      encode_parse_expression
	bcs      encode_byte_word_error
	      
	lda      r1H
	bne      encode_byte_word_error
	lda      r1L
	ldy      encode_buffer_size
	sta      (M1),y
	inc      encode_buffer_size
	      
	lda      encode_dry_run
	bne      @encode_string_byte_loop
	      
	stz      r1H
	lda      #1	; Byte count
	sta      r1L
	lda      encode_pc
	sta      r2L
	lda      encode_pc+1
	sta      r2H
	ldx      #(META_DATA_BYTE|META_FN_DATA_MASK)

	jsr      meta_save_expr

	IncW     encode_pc
	      
	bra      @encode_string_byte_loop

encode_byte_word_exit
	pla                                    ; Discard pushed ptr
	pla
	clc
	rts
	      
encode_byte_word_error
	pla                                    ; Discard pushed ptr
	pla   
	sec
	rts


	;;
	;; Encode a series of words, eg: .word $1234,$abcd,$4242
	;; Input r1 - pointer to string of word values
	;; Output bytes in buffer (encode buffer)
	;;
	;; Shares exist points with encode_byte_string
	;;
encode_word_string
	;; extract a series of words and push into the byte buffer
	stz      encode_buffer_size
	LoadW    M1,code_buffer
	PushW    r1

@encode_string_word_loop
	PopW     r1
	lda      #','
	jsr      util_split_string
	PushW    r2			; will become r1 on the next loop
	lda      (r1)
	beq      encode_byte_word_exit
	jsr      encode_parse_expression
	bcs      encode_byte_word_error
	      
	ldy      encode_buffer_size
	lda      r1L
	sta      (M1),y
	iny
	lda      r1H
	sta      (M1),y
	iny
	sty      encode_buffer_size

	lda      encode_dry_run
	bne      @encode_string_word_loop
	      
	;; save expression
	stz      r1H
	lda      #2
	sta      r1L
	lda      encode_pc
	sta      r2L
	lda      encode_pc+1
	sta      r2H
	ldx      #(META_DATA_WORD|META_FN_DATA_MASK)

	jsr      meta_save_expr

	;; Next address
	lda      encode_pc
	clc
	adc      #2
	sta      encode_pc
	bcc      :+
	inc      encode_pc
:  
	      
	bra      @encode_string_word_loop

;;
;; Pseudo op CSTR
;; Input r1 - pointer to string of character values, terminated with a NUL character
;; Output bytes in buffer (encode buffer)
;;
encode_cstr_string
	stz         encode_buffer_size
	jsr         encode_string_parse
	bcs         @encode_cstr_error

	lda         #0                         ; Terminate the C string
	sta         (r2),y
	iny
	sty         encode_buffer_size
	      
	lda      encode_dry_run
	bne      @encode_cstr_no_error
	      
	stz      r1H
	lda      encode_buffer_size
	sta      r1L
	lda      encode_pc
	sta      r2L
	lda      encode_pc+1
	sta      r2H
	ldx      #(META_DATA_CSTR|META_FN_DATA_MASK)
	jsr      meta_save_expr

@encode_cstr_no_error
	clc
	rts
	      
@encode_cstr_error
	sec
	rts
	
;;
;; Pseudo op PSTR
;; Input r1 - pointer to string of word values
;; Output bytes in buffer (encode buffer)
;;
encode_pstr_string
	lda         #1
	sta         encode_buffer_size
	jsr         encode_string_parse
	bcs         @encode_pstr_error

@encode_pstr_exit
	tya                                     ; Terminate the C string
	sta         code_buffer
	iny
	sty         encode_buffer_size
	
	lda      encode_dry_run
	bne      @encode_pstr_no_error
	      
	stz      r1H
	lda      encode_buffer_size
	sta      r1L
	lda      encode_pc
	sta      r2L
	lda      encode_pc+1
	sta      r2H
	ldx      #(META_DATA_PSTR|META_FN_DATA_MASK)
	jsr      meta_save_expr

@encode_pstr_no_error
	clc
	rts
	      
@encode_pstr_error
	sec
	rts
	      
;;
;; Sub parse routine to read a double quoted string. 
;; Used from cstr and pstr encoders
;; Input r1 - Ptr to "string"
;; Output Y - length of string
;;       r2 - Points to encode buffer
;;	
encode_string_parse
	lda         (r1)
	cmp         #DBL_QUOTE
	bne         @encode_string_error

	LoadW       r2,code_buffer
	
	lda         encode_buffer_size
	sta         TMP1L
	
	IncW        r1
	ldy         #0
@encode_string_loop
	lda         (r1),y
	beq         @encode_string_exit
	cmp         #DBL_QUOTE
	beq         @encode_string_exit
	phy
	ldy         TMP1L
	sta         (r2),y
	inc         TMP1L
	ply
	iny
	bra         @encode_string_loop

@encode_string_exit
	clc
	rts
	      
@encode_string_error
	sec
	rts
	
;;
;; Lookup the argument template matching the parsed mode
;; Input  A - parsed mode
;;        r1 - parsed value (not used, but need to preserve)
;;        M1 - ptr into encode_table
;; Output r2H - opcode
;;        r2L - mode, will match input A if found, $ff otherwise, indicating error (and carry == 1)
;;
encode_get_argument_template
	sta      M2L            ; preserve parsed mode
	      
	ldy      #2
	lda      (M1),y
	sta      r2L            ; Get low byte argument list
	iny
	lda      (M1),y         ; Get high byte argument list
	sta      r2H

	;; r2 currently pointing to argument templates for current instruction
	;; Find a template matching the parsed mode

	ldy      #0
@encode_get_argument_loop
	lda      (r2),y         ; get mode, for comparison
	and      #MODE_MASK
	cmp      M2L
	beq      @encode_get_argument_exit

	;; special case, if arg parsed as abs, and there is a branch available, take it.
	cmp      #MODE_BRANCH
	bne      :+
	lda      #MODE_ABS
	cmp      M2L
	bne      :+
	lda      #MODE_BRANCH
	sta      M2L            ; update preserved parse mode.
	bra      @encode_get_argument_exit
:  
	lda      (r2),y         ; If current template is last in the list, didn't find one.
	bmi      @encode_get_argument_template_error
	iny
	iny
	bra      @encode_get_argument_loop

@encode_get_argument_exit
	iny                     ; point to opcode
	lda      (r2),y
	sta      r2H
	lda      M2L
	sta      r2L
	      
	clc
	rts

@encode_get_argument_template_error
	;; special case, if arg parsed is MODE_ZP_IN, temp use MODE_IND as a backup
	lda      M2L
	cmp      #MODE_ZP_IND
	bne      :+
	lda      #MODE_IND
	bra      encode_get_argument_template 
:	
	sec
	rts

get_argument_size = @encode_get_argument_template_error - encode_get_argument_template
	      
;;
;; parse switch table
;;
encode_parse_emitter_table
	.word @encode_one_byte       ; MODE_NONE=0
	.word @encode_two_bytes      ; MODE_IMMED=1
	.word @encode_two_bytes      ; MODE_ZP=2
	.word @encode_two_bytes      ; MODE_ZP_X=3
	.word @encode_two_bytes      ; MODE_ZP_Y=4
	.word @encode_two_bytes      ; MODE_ZP_X_IND=5
	.word @encode_two_bytes      ; MODE_ZP_IND=6
	.word @encode_two_bytes      ; MODE_ZP_IND_Y=7
	.word @encode_three_bytes    ; MODE_ABS=8
	.word @encode_three_bytes    ; MODE_ABS_X=9
	.word @encode_three_bytes    ; MODE_ABS_X_IND=10
	.word @encode_three_bytes    ; MODE_ABS_Y=11
	.word @encode_three_bytes    ; MODE_IND=12
	.word @encode_one_byte       ; MODE_ACC=13
	.word @encode_branch_bytes   ; MODE_BRANCH=14
	.word encode_zp_bit_bytes    ; MODE_ZP_BIT=15
	.word encode_zp_bit_bytes    ; MODE_ZP_REL=16
	.word @encode_unknown        ; MODE_UNK=17

;;
;; One byte of code
;; Input r2H - opcode
;;       r1  - value (not needed)
@encode_one_byte
	lda      #1
	bra      @encode_stuff_bytes  ; Common code, saves space
	      
;;
;; Two bytes of code
;; Input r2H - opcode
;;       r1  - value
@encode_two_bytes
	lda      #2
	bra      @encode_stuff_bytes  ; Common code, saves space
	      
;;
;; Three bytes of code
;; Input r2H - opcode
;;       r1  - value
@encode_three_bytes
	lda      #3
	
@encode_stuff_bytes
	sta      encode_buffer_size

	lda      r2H
	sta      code_buffer
	      
	lda      r1L
	sta      code_buffer+1
	      
	lda      r1H
	sta      code_buffer+2
	      
	clc
	rts
	      
;;
;; Two bytes of code, argument is branch offset
;; Input r2H - opcode, gets stomped on during execution
;;       r1  - value, absolute address
@encode_branch_bytes
	lda      #2
	sta      encode_buffer_size

	lda      r2H
	sta      code_buffer
	      
	inc      encode_pc
	inc      encode_pc
	      
	lda      r1H
	sec
	sbc      encode_pc+1
	bne      @encode_unknown

	lda      r1L
	sbc      encode_pc
	sta      code_buffer+1
	      
	clc
	rts
	      
;;
;; Fail the parse
;;
@encode_unknown
	sec
	rts

;;
;; Parse arguments - Given a pointer to the argument string,
;; parse out the mode and value.
;; Input  r1 - Argument string
;; Output  A - MODE enumeration
;;        r1 - Value (16 bits)
;;
encode_parse_arguments
	;; Check first character, if == 0, straight to NONE
	;; otherwise prescan to determine the string length
	;; for examining suffix characters for things like ",x", etc.
	      
	ldy         #$ff
@encode_parse_scan_loop
	iny
	lda         (r1),y                     ; check first character
	bne         @encode_parse_scan_loop

	tya
	bne         @encode_parse_check2
	      
	;; Empty string means implied address
	lda         #MODE_NONE
	clc
	rts

@encode_parse_check2
	lda         (r1)
	      
	cmp         #'#'
	bne         @encode_parse_check3

	IncW        r1
	jsr         encode_parse_expression
	bcs         encode_parse_error
	lda         #MODE_IMMED
	clc
	rts

@encode_parse_check3
	;; Look for parens, indicating indirect ($,x) or ($zp)
	cmp          #'('
	bne          @encode_parse_check4

	jmp          encode_parse_indirect

@encode_parse_check4
	;; Test for *,x or *,y
	LoadW         r2,encode_str_abs_x
	jsr           util_ends_with
	beq           @encode_parse_check6
	LoadW         r2,encode_str_abs_y
	jsr           util_ends_with
	beq           @encode_parse_check6

@encode_parse_check5
	;; test for BIT instruction (rmb, smb, bbr, bbs)
	ldx          #','
	jsr          util_str_contains
	bne          @encode_parse_check6
	jmp          encode_parse_bit
	clc
	rts

@encode_parse_check6
	;; last chance, read an expression, or expression indexed (*,x or *,y)
	jmp          encode_parse_abs_modes
	;; will not return here
	      
encode_parse_error
	sec
	rts

;;
;; Code block for parse_argument. Handles bit instruction; e.g. 3,$02 or $3,$02,$a000
;; Input r1 - argument string
;; Output A - mode enumeration
;;        r1L - bit value
;;        r1L - zp value
;;        r3  - parsed address if mode == MODE_ZP_REL
;;
encode_parse_bit
	lda      #','
	jsr      util_split_string

	;; r1 = bit number
	jsr      util_parse_hex
	MoveW    r1,TMP2
	      
	;; r2 rest of argument string
	MoveW    r2,r1
	ldx      #','
	jsr      util_str_contains
	bne      encode_parse_bit_zp

@encode_parse_bit_rel
	lda      #','
	jsr      util_split_string
	IncW     r1                      ; skip $
	jsr      util_parse_hex          ; Get ZP address
	lda      TMP2L
	sta      r1H
	PushW    r1
	MoveW    r2,r1
	IncW     r1                      ; skip $
	jsr      util_parse_hex          ; get byte offset
	MoveW    r1,TMP2
	PopW     r1
	lda      #MODE_ZP_REL
	clc
	rts

encode_parse_bit_zp
	IncW     r1                      ; skip $
	jsr      util_parse_hex          ; Get ZP address
	lda      TMP2L
	sta      r1H                     ; H = ZP addresss, L = bit number
	lda      #MODE_ZP_BIT
	clc
	rts
	      
;;
;; Code block for parse_argument. Handles indexed syntax (possible no-index)
;;
	;; These will be added to either MODE_ZP or MODE_ABS to get real mode
	ABS   = 0
	ABS_X = 1
	ABS_Y = 2
	      
encode_parse_abs_modes
	lda         #ABS
	sta         r3L
	      
	LoadW       r2,encode_str_abs_y
	jsr         util_ends_with
	bne         @encode_parse_indexed_x
	pha         
	lda         #ABS_Y
	sta         r3L
	bra         @encode_parse_pre_hex

@encode_parse_indexed_x
	LoadW       r2,encode_str_abs_x
	jsr         util_ends_with
	bne         @encode_parse_indexed_hex
	pha         
	lda         #ABS_X
	sta         r3L

@encode_parse_pre_hex
	pla
	dec                                       ; remove either ,x or ,y
	dec
	tya
	lda         #0
	sta         (r1),y
	      
@encode_parse_indexed_hex
	jsr         encode_parse_expression
	bcs         @encode_parse_indexed_fail
	lda         r1H
	bne         :+
	clc
	lda         #MODE_ZP
	adc         r3L
	rts
	      
:  
	clc
	lda         #MODE_ABS
	adc         r3L
	rts

@encode_parse_indexed_fail
	sec
	rts

;;
;; Code block for parse_argument. Handles indirect syntax
;;
encode_parse_indirect
	;; indirect sub-parse
	IncW         r1                           ; Skip the first "("
	LoadW        r2,encode_str_ind_x
	jsr          util_ends_with
	bne          @encode_parse_check_ind_y
	      
	sec
	sbc          #3                           ; Remove the "),x"
	tay
	lda          #0
	sta          (r1),y

	jsr          encode_parse_expression

	lda          r1H
	beq          :+
	lda          #MODE_ABS_X_IND
	clc
	rts
	      
:  
	lda          #MODE_ZP_X_IND
	clc
	rts

@encode_parse_check_ind_y
	LoadW        r2,encode_str_ind_y
	jsr          util_ends_with
	bne          @encode_parse_check_ind

	sec
	sbc          #3                           ; Remove the "),y"
	tay
	lda          #0
	sta          (r1),y

	jsr          encode_parse_expression
	
	lda          #MODE_ZP_IND_Y
	clc
	rts

@encode_parse_check_ind
	lda          (r1),y
	cmp          #')'
	beq          :+
	jmp          encode_parse_error
:  
	lda          #0                           ; Remove the ")"
	sta          (r1),y

	jsr          encode_parse_expression
	
	lda          r1H
	bne          :+
	lda          #MODE_ZP_IND
	bra          :++

:  
	lda          #MODE_IND

:  
	clc
	rts

;;
;; For bit based operations (rmb, smb, bbr, bbs), emit two or three bytes
;; Input A - mode
;;       r1L - ZP address
;;       r1H - Bit number
;;       r2L - Mode
;;       r2H - opcode
;;
encode_zp_bit_bytes
	lda   r1H
	asl
	asl
	asl
	asl
	ora   r2H
	sta   code_buffer
	
	lda   r1L
	sta   code_buffer+1

	lda   r2L
	cmp   #MODE_ZP_BIT
	bne   @encode_zp_bit_bytes_rel
	      
	lda   #2
	sta   encode_buffer_size

	clc
	rts

@encode_zp_bit_bytes_rel
	lda   #3
	sta   encode_buffer_size

	lda      encode_pc+1
	sta      TMP1H
	lda      encode_pc
	clc
	adc      #3
	sta      TMP1L
	bcc      :+
	inc      TMP1H
:  

	lda      TMP2H
	sec
	sbc      TMP1H
	bne      @encode_zp_bit_error

	lda      TMP2L
	sbc      TMP1L
	sta      code_buffer+2

	clc
	rts

@encode_zp_bit_error
	sec
	rts

encode_str_ind_x     .byte ",X)", 0
encode_str_ind_y     .byte "),Y", 0
encode_str_abs_x     .byte ",X", 0
encode_str_abs_y     .byte ",Y", 0

;;
;; Parse an expression, return the current value, save expression in meta_i
;; TODO: support parsing decimal
;; Input  r1, pointing to expression string
;;
;; Output r1, current value
;; Carry == 0, no error
;; Carry == 1, parse_error
;; Clobbers TMP2
;;
encode_parse_expression
	lda   #META_FN_NONE
	sta   r13L

	;; check for trivial modes
	lda   (r1)
	cmp   #'>'
	bne   @parse_expr_1
	IncW   r1
	lda   #META_FN_HI_BYTE
	sta   r13L
	bra   @parse_value
	      
@parse_expr_1
	cmp   #'<'
	bne   @parse_value
	IncW   r1
	lda   #META_FN_LO_BYTE
	sta   r13L
;;         bra   @parse_value

@parse_value
	lda   (r1)                    ; Absolutely need to reload next char, incase previous expr chars skipped
	cmp   #'$'
	beq   @parse_expr_hex

	;; else figure out a label
	jsr   meta_lookup_label
	bne   @parse_expr_error
	lda   r13L
	ora   #META_FN_ADDR_MASK
	sta   r13L
	bra   @parse_expr_save_meta
	      
@parse_expr_hex
	IncW   r1
	jsr   util_parse_hex
	bcs   @parse_expr_error

@parse_expr_save_meta
	ldx   r13L
	lda   encode_pc
	sta   r2L
	lda   encode_pc+1
	sta   r2H
	      
	lda   encode_dry_run
	bne   @parse_expr_exit
	      
	jsr   meta_save_expr

@parse_expr_exit
	lda   r13L
	and   #META_FN_MASK
	cmp   #META_FN_HI_BYTE
	bne   @parse_expr_exit_2
	lda   r1H
	sta   r1L
	stz   r1H
	bra   @parse_expr_exit_final

@parse_expr_exit_2
	lda   r13L
	cmp   #META_FN_LO_BYTE
	bne   @parse_expr_exit_3
	stz   r1H
	bra   @parse_expr_exit_final

@parse_expr_exit_3
	;; value should be in r1

@parse_expr_exit_final
	clc
	rts

@parse_expr_error
	sec
	rts
	      
;;
;; Get entry - Given a pointer to the opcode, find the entry matching.
;; Performs a binary search into the encode_table.
;; Input r1 - mnemonic string pointer
;;
;; Usage
;;        r2 - Table start
;;        r3 - Table end
;;        r4 - tmp
;;        M1 - pointer into encode_table
;;        M2 - pointer to menmonics for comparison
;;
encode_get_entry
	LoadW     r2,encode_table
	LoadW     r3,encode_table_end

@encode_string_probe_table
	lda      r3H
	sta      r4H
	      
	sec                  ; r4 = start - end
	lda      r3L
	sbc      r2L
	sta      r4L
	lda      r3H
	sbc      r2H
	sta      r4H

	lsr      r4H         ; r4 = r4 / 2, AKA mid_offset
	ror      r4L

	lda      r4L
	and      #$fc
	sta      r4L         ; r4 mod 4 (size of records)

	lda      #1
	trb      r4L          ; Make sure difference is even

	;; See if table is exhausted
	lda      r4H
	ora      r4L
	beq      @encode_terminal_search
	      
@encode_string_probe_continue
	lda      r2L         ; M1 = start + mid_offset
	clc
	adc      r4L
	sta      M1L
	lda      r2H
	adc      r4H
	sta      M1H
	      
@encode_string_scan
	jsr      encode_calc_test_ptr
	jsr      encode_compare_mnemonic
	bmi      @encode_search_lower
	bne      @encode_search_higher
	      
	      ; Made it here, the opcode has been found
@encode_search_exit
	clc
	rts

@encode_search_higher
	MoveW  M1,r2
	bra   @encode_string_probe_table

@encode_search_lower
	MoveW  M1,r3
	bra   @encode_string_probe_table

@encode_terminal_search
	MoveW    r2,M1
	jsr      encode_calc_test_ptr
	jsr      encode_compare_mnemonic
	beq      @encode_search_exit

	MoveW    r3,M1
	jsr      encode_calc_test_ptr
	jsr      encode_compare_mnemonic
	beq      @encode_search_exit

@encode_error
	sec
	rts

get_entry_size = @encode_error - encode_get_entry

;;
;; Calculate a pointer to the mnemonic string from the table
;; Input M1 - encode table pointer
;; Output M2 - pointer to actual string pointer
;;
encode_calc_test_ptr
	lda      (M1)        ; get ptr of instruction mnemonic
	sta      M2L
	ldy      #1
	lda      (M1),y
	sta      M2H
	rts

;;
;; Compare the mnemonic candidate (r1) with a cannonical test (M2/r13)
;; Clobbers Y
;; Return Z = 1 - means opcode matched (eq)
;; Return Z = 0 - means opcode did not match (not eq)
;; If not eq, A == 1 for search higher
;;            A == $ff for search lower
;;
encode_compare_mnemonic
	ldy   #0

@encode_compare_check
	lda   (r1),y
	cmp   (M2),y
	bmi   @encode_compare_exit_lower
	bne   @encode_compare_exit_higher

	iny
	tya
	cmp   #3
	bne   @encode_compare_check

	lda   #0                      ; Z = 1, found means matched
	rts

@encode_compare_exit_higher
	lda   #1
	rts
	      
@encode_compare_exit_lower
	lda   #$ff
	rts




