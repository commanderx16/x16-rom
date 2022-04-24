	;;
	;; X16 CodeX Monitor Unit Tests
	;; 
	;;    Copyright 2020-2022 Michael J. Allison
	;; 
	;;    Redistribution and use in source and binary forms, with or without
	;;    modification, are permitted provided that the following conditions are met:
	;;
	;; 1. Redistributions of source code must retain the above copyright notice,
	;; this list of conditions and the following disclaimer.
	;;
	;; 2. Redistributions in binary form must reproduce the above copyright notice,
	;; this list of conditions and the following disclaimer in the documentation
	;; and/or other materials provided with the distribution.
	;; 
	;;	
	;;    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
	;; PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	;; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	;; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
	;; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
	;; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
	;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	;; POSSIBILITY OF SUCH DAMAGE.

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.export  main_entry
;;; -------------------------------------------------------------------------------------
	
	.code

	.include "bank_assy.inc"
	.include "bank_assy_vars.inc"
	.include "bank.inc"
	.include "petsciitoscr.inc"
	.include "screen.inc"
	.include "utility.inc"
	.include "vera.inc"
	.include "kvars.inc"
	.include "x16_kernal.inc"
	
	.include "assert.s"

	MAX_ROW=58

	;; Blue background
	COLOR_CDR_PASS  = COLOR_GREEN 
	COLOR_CDR_FAIL  = COLOR_LT_RED
	COLOR_CDR_FATAL = COLOR_ORANGE

	COL_INDENT=1
	COL_TEST_INDENT=6

	;; Position these AFTER SCR_ROW & SCR_COL (from x16_kernal.a)        
	T1L=$24
	T1H=$25
	T1=$24

	T2L=$26
	T2H=$27
	T2=$26

	.macro pushBank b
	lda    BANK_CTRL_RAM
	pha
	lda    #b
	sta    BANK_CTRL_RAM
	.endmacro

	
main_entry
	lda       K_TEXT_COLOR
	sta       orig_color

	jsr       clear
	stz       passed_count
	stz       passed_count+1
	stz       failed_count
	stz       failed_count+1
	stz       total_count
	stz       total_count+1

	vgotoXY   COL_INDENT,2
	lda       orig_color
	sta       K_TEXT_COLOR
	callR1    prtstr,str_version
	jsr       bank_initialize
	jsr       meta_clear_watches
	jsr       meta_clear_meta_data

	jsr       testIs65c02
	jsr       testUtility
	jsr       testPetsciiToScr
	jsr       testBanks
	jsr       testDispatcher
	jsr       testTableDecoder
	jsr       testDebugStep
	jsr       testRegisterSave
	jsr       testMetaAddDelete
	jsr       testUtility2
	jsr       testEncoder
	jsr       testScrollback
	jsr       testCodeEdit
	jsr       testMetaInstruction
	jsr       testCodeReloc
	jsr       testEncoder2
	
	jsr       print_summary
	     
	ldy       SCR_COL
	ldx       SCR_ROW
	jsr       PLOT

	lda       #4
	sta       BANK_CTRL_ROM

	lda       orig_color
	sta       K_TEXT_COLOR

	rts

;; -------------------------------------------------------------------------------------
testIs65c02
	callR1  testHeader,str_test_65c02

	bra     is65c02
	fatal   str_is_not

is65c02
	pass    str_is_65c02
	rts

str_test_65c02  .byte  "65C02 TEST", CR, 0
str_is_65c02    .byte  "CONGRATS, YOU ARE RUNNING ON A 65C02", CR, 0 
str_is_not      .byte  "NOT A 65C02, TOO BAD", CR, 0
str_cr          .byte  CR, 0

;; -------------------------------------------------------------------------------------
	
testUtility
	callR1  testHeader,str_test_utility

	LoadW   r1,utility_buffer
	ldy     #$0f

@testUtility_load_loop
	tya
	sta     (r1),y
	dey
	bpl     @testUtility_load_loop

	;; Copy src,dst,size
	LoadW    r0,utility_buffer
	LoadW    r1,utility_dst
	LoadW    r2,$10
	kerjsr   MEMCOPY
	LoadW    r1,utility_dst
	LoadW    r2,$10
	jsr      assertCopyBlock

	;; Test copy other direction
	LoadW   r0,utility_dst
	LoadW   r1,utility_buffer
	LoadW   r2,$10
	;; invalidate destination
	stz    utility_buffer+$0f
	stz    utility_buffer+$0d
	stz    utility_buffer+$0b
	stz    utility_buffer+$09
	stz    utility_buffer+$07
	stz    utility_buffer+$05
	stz    utility_buffer+$03
	stz    utility_buffer+$01
	kerjsr  MEMCOPY
	LoadW   r1,utility_buffer
	LoadW   r2,$10
	jsr     assertCopyBlock

	;; Make a 300 byte block
	;; to test overlap and more than one page
	LoadW   r1,utility_buffer
	LoadW   r2,300

@testUtility_load_loop2
	lda     r1H
	sta     M1H
	     
	lda     r1L
	clc
	adc     r2L
	sta     M1L
	bcc     :+
	inc     M1H
:  
	clc
	lda     r2H
	adc     M1H
	sta     M1H
	     
	lda     r2L        ; low order counter
	sta     (M1)
	DecW    r2
	lda     r2L
	and     r2H
	cmp     #$ff
	bne     @testUtility_load_loop2

	LoadW   r1,utility_buffer
	LoadW   r2,300
	jsr     assertCopyBlock

	;; Copy with dst overlapping end
	LoadW   r0,utility_buffer
	LoadW   r1,utility_dst
	LoadW   r2,300
	kerjsr  MEMCOPY
	     
	LoadW   r1,utility_dst
	LoadW   r2,300
	jsr     assertCopyBlock

	;;
	;; Test built in MEMCOPY in a manner to mimic meta_data_label
	;;
	pushBank $2
	START=$A016
	LoadW    r1,START
	ldy     #0

@testUtilityMCLoop
	tya
	cmp     #20
	beq     @testUtilityLoop_exit
	sta     (r1),y
	iny
	bra     @testUtilityMCLoop

@testUtilityLoop_exit
	;; All set up, run MEMCOPY
	LoadW  r0,START+4    ; src
	LoadW  r2,$C
	kerjsr MEMCOPY

	lda     START
	assertEqA   4,str_acopy_back
	popBank

	rts

str_test_utility .byte    "UTILITY ROUTINE TEST", CR, 0
str_acopy_back   .byte    "BACKWARD MEMCOPY IN $A000", CR, 0

utility_buffer   .res 512,0
	utility_dst = utility_buffer + $20
	
;;
;; Check to make sure a series of bytes are correct
assertCopyBlock

	DecW     r2

@assertCheckLoop

	;; M1 = r1 + r2
	lda       r1L
	clc
	adc       r2L
	sta       M1L

	lda       r1H
	adc       r2H
	sta       M1H

	lda       (M1)
	cmp       r2L
	bne       @assertCheckLoop_fail

	DecW      r2
	lda       r2L
	cmp       #$ff
	bne       @assertCheckLoop
	lda       r2H
	cmp       #$ff
	bne       @assertCheckLoop

	pass      str_utility_block
	rts

@assertCheckLoop_fail
	fail      str_utility_block
	rts

str_utility_block .byte "POST COPY BLOCK VERIFY", CR, 0

;; -------------------------------------------------------------------------------------

	
testPetsciiToScr
	callR1 testHeader,str_petscii_to_scr

	;;;;;;;;;;;;;;;;;;;
	;; $00 - $1f
	;;        +fatal str_unimplemented
	;; control codes

	;;;;;;;;;;;;;;;;;;;
	;;
	;; $20 - $3f
	lda     #' '
	jsr     petscii_to_scr
	assertEqA ' ',str_char_SP

	lda     #'?'
	jsr     petscii_to_scr
	assertEqA '?',str_char_QM

	;;;;;;;;;;;;;;;;;;;
	;;
	;; $40 - $5f
	lda     #'A'
	jsr     petscii_to_scr
	assertEqA 1,str_alpha_A

	lda     #'Z'
	jsr     petscii_to_scr
	assertEqA 26,str_alpha_Z

	lda     #91
	jsr     petscii_to_scr
	assertEqA 27,str_lbracket

	lda     #95
	jsr     petscii_to_scr
	assertEqA 31,str_larrow

	;;;;;;;;;;;;;;;;;;;
	;;
	;; $60 - $7f
	lda    #$60
	jsr    petscii_to_scr
	assertEqA $40,str_hline

	lda    #$7f
	jsr    petscii_to_scr
	assertEqA $5f,str_diag_half

	;;;;;;;;;;;;;;;;;;;
	;;
	;; $80 - $9f
	;;        +fatal str_unimplemented
	;; control codes

	;;;;;;;;;;;;;;;;;;;
	;;
	;; $A0 - $bf
	lda        #$A0
	jsr        petscii_to_scr
	assertEqA $60,str_a0_blank

	lda        #$BF
	jsr        petscii_to_scr
	assertEqA $7f,str_ul_check

	;;;;;;;;;;;;;;;;;;;
	;;
	;; $C0 - $df
	lda        #$C0
	jsr        petscii_to_scr
	assertEqA $c0,str_hline2_c0

	lda        #$df
	jsr        petscii_to_scr
	assertEqA $df,str_diag2_df

	;;;;;;;;;;;;;;;;;;;
	;;
	;; $E0 - $ff
	lda        #$e0
	jsr        petscii_to_scr
	assertEqA $60,str_blank_e0

	lda        #$7e
	jsr        petscii_to_scr
	assertEqA $5e,str_ul_block

	rts

	
str_blank_e0            .byte "BLANK - $E0", CR, 0
str_ul_block            .byte "UL BLOCK ", $7e, CR, 0
str_hline2_c0           .byte "HLINE - $C0", CR, 0
str_diag2_df            .byte "DIAG  - $DF", CR, 0
str_a0_blank            .byte "BLANK - $A0", CR, 0 
str_ul_check            .byte "CHECK ", $7f, CR, 0
str_hline               .byte "HALF LINE ", $40, CR, 0
str_diag_half           .byte "DIAG HALF ", $5f, CR, 0
str_char_QM             .byte "QM ? ", CR, 0
str_char_SP             .byte "SPACE", CR, 0
str_alpha_A             .byte "ALPHA A", CR, 0
str_alpha_Z             .byte "ALPHA Z", CR, 0
str_lbracket            .byte "LBRACKET [", CR, 0
str_larrow              .byte "LARROW ", 31, CR, 0
str_petscii_to_scr      .byte "PETSCII TO SCR", CR, 0

;; -------------------------------------------------------------------------------------

	base=$a000

;;
;; Test basic bank control
;;
testBanks
	callR1 testHeader,str_test_banks

	lda        BANK_CTRL_RAM
	assertEqA 1,str_bank_default

	stz        base

	pushBank   2
	lda        #1
	sta        base
	lda        base
	pha
	assertEqA  1,str_bank2_write

	pla
	popBank
	assertEqA  1,str_push_pop

	lda        BANK_CTRL_RAM
	assertEqA  1,str_get_after_pop

	;; Test to ensure that 01:a000 has not changed
	lda        base
	assertEqA  0,str_bank1_read

	;; make sure the bank_initialize works
	sec
	jsr        MEMTOP
	dec        ; A = top bank id
	cmp        bank_max
	beq        :+
	fail       str_bank_max
	bra        :++
:  
	pass       str_bank_max
:  

	rts

	
str_test_banks    .byte  "BANK CTRL TEST", CR, 0 
str_bank_default  .byte  "BANK EXPECTED TO BE AT ONE", CR, 0
str_push_pop      .byte  "PUSH POP BANK", CR, 0
str_get_after_pop .byte  "GET BANK AFTER POP", CR, 0
str_bank2_write   .byte  "BANK 2 WRITEABILITY", CR, 0
str_bank1_read    .byte  "BANK 1 RESTORE/READ", CR, 0
str_bank_max      .byte  "BANK_MAX CORRECT VALUE", CR, 0

;; -------------------------------------------------------------------------------------
;;
;; Test input dispatcher
;;


	.include "dispatch.inc"

testDispatcher
	callR1 testHeader,str_test_dispatcher

	setDispatchTable dispatch_table1

	stz     dispatch_set_value
	lda     #F1
	jsr     fn_dispatch
	lda     dispatch_set_value
	assertEqA $f1,str_f1_dispatch

	stz     dispatch_set_value
	lda     #F3
	jsr     fn_dispatch
	lda     dispatch_set_value
	assertEqA $f3,str_f3_dispatch

	;; Test empty table entry
	lda     #F4
	sta     dispatch_set_value
	jsr     fn_dispatch
	lda     dispatch_set_value
	assertEqA F4,str_f4_dispatch           ; Should still be the input character, not in table

	;; Test that empty table entry returns character back in A
	lda    #F6
	jsr    fn_dispatch
	assertEqA F6,str_null_passthrough

	;; Test new table, and check for the non monotonicity of the table

	setDispatchTable dispatch_table2

	stz     dispatch_set_value
	lda     #F7
	jsr     fn_dispatch
	lda     dispatch_set_value
	assertEqA $f7,str_f7_dispatch

	stz     dispatch_set_value
	lda     #F6
	jsr     fn_dispatch
	lda     dispatch_set_value
	assertEqA $f6,str_f6_dispatch

	;; Test for characters outside of F1-F8 range
	stz    dispatch_set_value
	lda    #F9
	jsr    fn_dispatch
	lda    dispatch_set_value
	assertEqA 0,str_f9_dispatch

	lda    #F1-1
	jsr    fn_dispatch
	lda    dispatch_set_value
	assertEqA 0,str_less_dispatch        

	;; test that a character is passed unchanged if it's not F1-F8
	stz    dispatch_set_value
	lda    #'A'
	jsr    fn_dispatch
	assertEqA 'A',str_non_disp_value
	lda    dispatch_set_value
	assertEqA 0,str_non_disp_value2
	rts

; test routines for table
dispatch_test_f1
	lda     #$f1
	sta     dispatch_set_value
	rts

dispatch_test_f3
	lda     #$f3
	sta     dispatch_set_value
	rts

dispatch_test_f5
	lda     #$f5
	sta     dispatch_set_value
	rts

dispatch_test_f7
	lda     #$f7
	sta     dispatch_set_value
	rts

dispatch_test_f6
	lda     #$f6
	sta     dispatch_set_value
	rts

dispatch_set_value .byte 0

	
dispatch_table1
	.word   dispatch_test_f1        ; F1
	.word   dispatch_test_f3        ; F3
	.word   dispatch_test_f5        ; F5
	.word   0                       ; F7
	.word   0                       ; F2
	.word   0                       ; F4
	.word   0                       ; F6

dispatch_table2
	.word   dispatch_test_f1        ; F1
	.word   dispatch_test_f3        ; F3
	.word   dispatch_test_f5        ; F5
	.word   dispatch_test_f7        ; F7
	.word   0                       ; F2
	.word   0                       ; F4
	.word   dispatch_test_f6        ; F6

str_test_dispatcher  .byte "DISPATCHER TEST", CR, 0

str_f1_dispatch      .byte "F1 DISPATCH", CR, 0
str_f3_dispatch      .byte "F3 DISPATCH", CR, 0
str_f4_dispatch      .byte "F4 DISPATCH", CR, 0
str_f7_dispatch      .byte "F7 DISPATCH", CR, 0
str_f6_dispatch      .byte "F6 DISPATCH", CR, 0
str_f9_dispatch      .byte "F9 DISPATCH", CR, 0
str_less_dispatch    .byte "(F1-1) DISPATCH", CR, 0
str_non_disp_value   .byte "NON-DISPATCH LEAVE ACCUMULAOR UNCHANGED", CR, 0
str_non_disp_value2  .byte "NON-DISPATCH SHOULD NOT TOUCH STORE VALUE", CR, 0
str_null_passthrough .byte "NULL ENTRIES SHOULD RETURN INPUT CHARACTER, UNCHANGED", CR, 0

	.include "dispatch_vars.inc"

;; -------------------------------------------------------------------------------------
;;
;; Test instruction decoder routines. This only tests the routines, and does not test
;; the decoder tables. 
;;


	.include "decoder.inc"

testTableDecoder
	callR1 testHeader,str_test_decoder
	     
	LoadW   r2,decoder_test_code
	MoveW   r2,r1
	lda     (r2)
	jsr     decode_next_instruction
	assertEqR0 str_test_LDA
	     
	MoveW   r2,r1
	jsr     decode_get_byte_count
	assertEqA  2,str_test_byte_count

	jsr     decode_next_argument
	assertEqR0 str_test_arg1

	LoadW   r2,decoder_test_code_2
	MoveW   r2,r1
	lda     (r2)
	jsr     decode_next_instruction
	assertEqR0 str_test_STA
	     
	MoveW      r2,r1
	jsr        decode_get_byte_count
	assertEqA  2,str_test_byte_count
	
	jsr        decode_next_argument
	assertEqR0 str_test_arg2
	
	;; Test remaining argument decoders
	LoadW      r2,decoder_test_code_3
	jsr        decode_next_argument
	assertEqR0 str_test_arg3

	LoadW      r2,decoder_test_code_4
	jsr        decode_next_argument
	assertEqR0 str_test_arg4

	LoadW  r2,decoder_test_code_5
	jsr   decode_next_argument
	assertEqR0 str_test_arg5

	LoadW  r2,decoder_test_code_6
	jsr   decode_next_argument
	assertEqR0 str_test_arg6

	LoadW  r2,decoder_test_code_7
	jsr   decode_next_argument
	assertEqR0 str_test_arg7
	
	LoadW  r2,decoder_test_code_8
	jsr   decode_next_argument
	assertEqR0 str_test_arg8

	LoadW  r2,decoder_test_code_9
	jsr   decode_next_argument
	assertEqR0 str_test_arg9

	LoadW  r2,decoder_test_code_10
	jsr   decode_next_argument
	assertEqR0 str_test_arg10

	LoadW  r2,decoder_test_code_11
	jsr   decode_next_argument
	assertEqR0 str_test_arg11

	LoadW  r2,decoder_test_code_12
	jsr   decode_next_argument
	assertEqR0 str_test_arg12

	LoadW  r2,decoder_test_code_13
	jsr   decode_next_argument
	assertEqR0 str_test_arg13

	;; Set up expected arg cannonical, because if code moves the cannonical 
	;; can not be a hard coded string. 
	stz   decoded_str_next
	LoadW  M1,decoder_test_code_15 ; This is the target of code_14's branch, so get it's value
	
	jsr    decode_push_label_or_hex_core
	;; Terminate the decoded_string
	LoadW  r1,code_buffer
	lda    #0
	ldy    decoded_str_next
	sta    (r1),y

	LoadW  r2,str_test_arg14
	jsr    util_strcpy
	
	LoadW  r2,decoder_test_code_14
	jsr   decode_next_argument
	assertEqR0 str_test_arg14

	LoadW  r2,decoder_test_code_15
	jsr   decode_next_argument
	assertEqR0 str_test_arg15

	;; ----- arg 16 -----
	;; This test will absolute arguments on a bbr
	;; Need to build the actual argument string because
	;; code may move during development.
	;; 1) build argument string
	stz         decoded_str_next
	lda         #>decoder_test_code
	jsr         decode_push_hex
	lda         #<decoder_test_code
	jsr         decode_push_hex
	LoadW        TMP1,code_buffer
	LoadW        TMP2,str_test_arg16+7
	ldy         #3
@decode_arg_16_loop
	lda         (TMP1),y
	sta         (TMP2),y
	dey
	bpl         @decode_arg_16_loop
	     
	;; 2) decode instruction and compare to prebuild cannonical string
	LoadW  r2,decoder_test_code_16
	jsr   decode_next_argument
	assertEqR0 str_test_arg16
	;; ----- arg 16 -----

	LoadW  r2,decoder_test_code_17
	jsr   decode_next_argument
	assertEqR0 str_test_arg17

	LoadW  r2,decoder_test_code_18
	jsr   decode_next_argument
	assertEqR0 str_test_arg18

	rts

;;
;; TEST CODE FOR DECODER - DO NOT RUN!
;;
decoder_test_code
	lda     #42
decoder_test_code_2
	sta     r1
decoder_test_code_3             ; MODE_ZP_X=3
	sta     r1,x
decoder_test_code_4             ; MODE_ZP_Y=4
	stx     r1,y
decoder_test_code_5             ; MODE_ZP_X_IND=5
	sta     (r1,x)
decoder_test_code_7             ; MODE_ZP_IND_Y=7
	sta     (r1),y
decoder_test_code_6             ; MODE_ZP_IND=6
	sta     (r1)
decoder_test_code_8             ; MODE_ABS=8
	sta     $a000
decoder_test_code_9             ; MODE_ABS_X=9
	sta     $a000,x
decoder_test_code_10            ; MODE_ABS_X_IND=10
	jmp     ($a000,x)
decoder_test_code_11            ; MODE_ABS_Y=11
	sta     $a000,y
decoder_test_code_12            ; MODE_IND=12
	jmp     ($a000)
decoder_test_code_13            ; MODE_ACC=13
	inc
decoder_test_code_14            ; MODE_BRANCH=14
	bra     decoder_test_code_15
decoder_test_code_15            ; MODE_ZP_BIT=15
;       rmb     $02, $zp
	.byte   $37, $02, $db   ; $db should be to label decoder_test_code
decoder_test_code_16            ; MODE_ZP_REL=16
;        bbr     $03, $zp, $da
	.byte    $3f, $02, $da
decoder_test_code_17            ; MODE_UNK=17
	.byte   $02             ; unknown instruction
	     
decoder_test_code_18            ; Bug from 2019-12-10, no argument for "sta $00"
	sta     $00


;; END TEST CODE

	
str_test_decoder    .byte  "TABLE DECODER TEST", CR, 0 
str_test_byte_count .byte  "BYTE COUNT", CR, 0
str_test_LDA        .byte  "LDA", 0
str_test_STA        .byte  "STA", 0
str_test_arg1       .byte  "#$2A",0
str_test_arg2       .byte  "$04",0
str_test_arg3       .byte  "$04,X",0
str_test_arg4       .byte  "$04,Y",0
str_test_arg5       .byte  "($04,X)",0
str_test_arg6       .byte  "($04)",0
str_test_arg7       .byte  "($04),Y",0
str_test_arg8       .byte  "$A000",0
str_test_arg9       .byte  "$A000,X",0
str_test_arg10      .byte  "($A000,X)",0
str_test_arg11      .byte  "$A000,Y",0
str_test_arg12      .byte  "($A000)",0
str_test_arg13      .byte  "A",0
str_test_arg15      .byte  "3,$02", 0
str_test_arg16      .byte  "3,$02,$XXXX", 0   ; need to put hex into locations for XXXX
str_test_arg17      .byte  "???",0
str_test_arg18      .byte  "$00",0

str_test_arg14      .res   6,0
	
	.include "decoder_vars.inc"

;; -------------------------------------------------------------------------------------
	.include "dbgctrl.inc"

	LDA_INSTRUCTION=$A9
	STA_INSTRUCTION=$85
	RTS_INSTRUCTION=$60
	NOP_INSTRUCTION=$EA
	BRA_INSTRUCTION=$80
	
testDebugStep
	callR1     testHeader,str_debug_step

	;; assume that control will return to sdc_1, a step-break should be
	;; at sdc_2
	callR1   step_apply,sdc_1
	lda      sdc_2
	assertEqA   BRK_INSTRUCTION,str_dbgstep_brk

	;;
	;; Verify step state variables
	;;
	pushBankVar  bank_assy
	lda          step_1_bank
	assertEqA    0,str_dbgstep_wrong_bank

	lda          step_1_addr
	assertEqA    <(sdc_2),str_dbgstep_addr

	lda          step_1_addr+1
	assertEqA    >(sdc_2),str_dbgstep_addr

	lda          step_1_byte
	assertEqA    STA_INSTRUCTION,str_dbgstep_sta
	popBank

	;; Make sure things are restored to normal
	jsr   step_suspend
	lda   sdc_2
	assertEqA  STA_INSTRUCTION,str_dbgstep_sta

	;; Verify step state variables are cleared
	pushBankVar  bank_assy
	lda          step_1_bank
	ora          step_1_addr
	ora          step_1_addr+1
	ora          step_1_byte
	ora          step_2_bank
	ora          step_2_addr
	ora          step_2_addr+1
	ora          step_2_byte
	assertEqA    0,str_dbgstep_zero
	popBank

	;; Make sure a branch step works properly
	callR1       step_apply,sdc_4

	lda          sdc_5
	assertEqA    BRK_INSTRUCTION,str_dbgstep_brk

	lda          sdc_6
	assertEqA    BRK_INSTRUCTION,str_dbgstep_brk

	;; Suspend to clear the two step-break conditions
	jsr          step_suspend
	lda          sdc_5
	assertEqA    NOP_INSTRUCTION,str_dbgstep_nop

	lda          sdc_6
	assertEqA    RTS_INSTRUCTION,str_dbgstep_rts

	;; Test those pesky JMP instructions
	;; JMP absolute
	jsr          step_suspend
	callR1       step_apply,sdc_7
 
	lda          sdc_8
	assertEqA    JMP_IND,str_dbgstep_jmp_opcode

	lda          sdc_1
	assertEqA    BRK_INSTRUCTION,str_dbgstep_brk

	;; JMP indirect + X
	jsr          step_suspend
	;; simulate having X set, inside of the ISR
	pushBankVar  bank_assy
	lda          #2
	sta          brk_data_x
	popBank

	callR1       step_apply,sdc_10

	lda          sdc_11
	assertEqA    NOP_INSTRUCTION,str_dbgstep_jmp_opcode

	lda          sdc_5
	assertEqA    BRK_INSTRUCTION,str_dbgstep_brk

	jsr          step_suspend

	rts

	JMP_ABS=$4c
	JMP_IND=$6c
	JMP_IND_X=$7c

;;
;; Test code for a step target, DO NOT CALL!
;;
sdc_1    lda   #42
sdc_2    sta   $00
sdc_3    lda   #0
sdc_4    beq   sdc_6
sdc_5    nop
	      nop
	      nop
	      nop
	      nop
sdc_6    rts
sdc_7    jmp   sdc_1
sdc_8    jmp   (sdc_ind)
sdc_9    nop
sdc_10   jmp   (sdc_ind,x)
sdc_11   nop

	
sdc_ind  .word sdc_2
	      .word sdc_5

str_debug_step         .byte "DEBUG STEP CONTROL", CR, 0
str_dbgstep_brk        .byte "LOOKING FOR A BRK INSTRUCTION", CR, 0
str_dbgstep_wrong_bank .byte "VERIFY BANK VALUE", CR, 0
str_dbgstep_addr       .byte "VERIFY STEP-BREAK ADDR", CR, 0
str_dbgstep_lda        .byte "LDA SAVED BY STEP", CR, 0
str_dbgstep_sta        .byte "STA SAVED BY STEP", CR, 0
str_dbgstep_zero       .byte "STEP VARS ZEROED", CR, 0
str_dbgstep_nop        .byte "NOP INSTRUCTION", CR, 0
str_dbgstep_rts        .byte "RTS INSTRUCTION", CR, 0
str_dbgstep_jmp_opcode .byte "JMP INSTRUCTION", CR, 0

;; -------------------------------------------------------------------------------------

testRegisterSave
	callR1     testHeader,str_register_save

	;; Brute force register contents with idx
	LoadW      T1,2                     ; start with r0
	ldy        #0
	      
@testRegisterLoop1
	tya
	cmp        #(LAST_ZP_REGISTER - r0L + 1)
	beq        @testRegisterSetupDone
	sta        (T1),y
	iny
	bra        @testRegisterLoop1
	      
@testRegisterSetupDone

	jsr        registers_save

	;; scan saved area to make sure proper data is there.
	;; r0 expected value
	;; r1 points to destination
	stz          test_reg_fail          ; Boolean indicating failure
	      
	pushBankVar  bank_assy
	LoadW        r1,reg_save
	LoadW        r0,0                   ; expected value
	ldy          #0
:  
	lda          r0L
	tay
	cmp          (r1),y
	beq          @testRegisterIncr
	inc          test_reg_fail         ; failures occured
@testRegisterIncr
	inc          r0L
	lda          r0L
	cmp          #(LAST_ZP_REGISTER - r0L + 1)
	bne          :-

	lda          test_reg_fail
	bne          :+
	pass         str_register_saved_bank
	bra          :++
:  
	fail         str_register_saved_bank
:  
	popBank

	;; Test the restore
	LoadW        T1,$2
	ldy          #0

@testRegisterScrambleLoop
	lda          #$ff
	sta          (T1),y
	iny
	tya
	cmp          #(LAST_ZP_REGISTER - r0L + 1)
	bne          @testRegisterScrambleLoop

	stz          test_reg_fail
	      
	jsr          registers_restore

	LoadW        T1,$02
	ldy          #0

@testRegisterRestoreCheck
	tya
	cmp         #(LAST_ZP_REGISTER - r0L + 1)
	beq         @testRegisterRestoreDone
	cmp         (T1),y
	beq         @testRegisterRestoreIncr
	inc         test_reg_fail
	      
@testRegisterRestoreIncr
	iny
	bra         @testRegisterRestoreCheck

@testRegisterRestoreDone

	lda         test_reg_fail
	bne         @testRestoreFail01

	pass        str_register_restored_bank
	bra         @testRestoreExit
	      
@testRestoreFail01
	fail        str_register_restored_bank

@testRestoreExit
	   
	rts

test_reg_fail               .byte 0
str_register_save           .byte "REGISTER SAVE", CR, 0
str_register_saved_bank     .byte "REGISTERS ALL SAVED", CR, 0
str_register_restored_bank  .byte "REGISTERS ALL RESTORED", CR, 0

;; -------------------------------------------------------------------------------------
;;

testMetaAddDelete
	callR1     testHeader,str_meta_test
	      
;;;         ; FOR DEBUGGING
;;;         +pushBankVar bank_meta_l
;;;         +LoadW     r0,$A000
;;;         +LoadW     r1,$2000
;;;         lda        #0
;;;         +kerjsr    MEMFILL
;;;         +popBank
;;;         ; END FOR DEBUGGING
	      
	jsr        meta_clear_meta_data

	LoadW      r1,str_meta1 
	LoadW      r2,$1234
	jsr        meta_add_label
	assertEqZ  str_meta_added1
	      
	LoadW      r1,$1234
	jsr        meta_find_label
	beq        :+
	fail       str_meta_found1
:  
	pushBankVar  bank_meta_l
	assertEqR0  str_meta1
	popBank
	       
	LoadW      r1,str_meta2
	LoadW      r2,$1240
	jsr        meta_add_label
	assertEqZ  str_meta_added2

	LoadW      r1,$1240
	jsr        meta_find_label
	beq        :+
	fail       str_meta_found2
:  
	pushBankVar  bank_meta_l
	assertEqR0  str_meta2
	popBank

	;; Double check for a stomp
	LoadW      r1,$1234
	jsr        meta_find_label
	assertEqZ  str_meta_found1

	;; Insert between first two
	LoadW      r1,str_meta15
	LoadW      r2,$123A
	jsr        meta_add_label
	assertEqZ  str_meta_added15

	LoadW      r1,$1234
	jsr        meta_find_label
	assertEqZ  str_meta_found15
	      
	;; Double check for a stomp
	LoadW      r1,$1234
	jsr        meta_find_label
	assertEqZ  str_meta_found1

	LoadW      r1,$1240
	jsr        meta_find_label
	assertEqZ  str_meta_found2

	;; One last addition, push down. 
	LoadW      r1,str_meta0
	LoadW      r2,$1000
	jsr        meta_add_label
	assertEqZ  str_meta_added0
	LoadW      r1,$1000
	jsr        meta_find_label
	assertEqZ  str_meta_found0

	;;
	;; Delete testing
	;;

	;; Delete some symbols that don't exist
	LoadW      r1,$abcd
	jsr        meta_delete_label
	assertNeZ  str_not_found_del
	      
	LoadW      r1,$1234
	jsr        meta_delete_label
	assertEqZ  str_meta_deleted1

	LoadW      r1,$1234
	jsr        meta_find_label
	assertNeZ  str_meta_not_found1       ; Should not find the label
	
	;; Test to make sure the remaining labels are properly relocated
	pushBankVar    bank_meta_l
	LoadW          r1,$1000
	jsr            meta_find_label
	assertEqR0     str_meta0
	      
	LoadW          r1,$123A
	jsr            meta_find_label
	assertEqR0     str_meta15
	      
	LoadW          r1,$1240
	jsr            meta_find_label
	assertEqR0     str_meta2
	      
	popBank
	       
	rts

	
str_meta_test                .byte "META ADD DELETE", CR, 0
str_meta_added1              .byte "META1 ADDED", CR, 0
str_meta_added2              .byte "META2 ADDED", CR, 0
str_meta_added15             .byte "META15 ADDED", CR, 0
str_meta_added0              .byte "META0 ADDED", CR, 0
str_meta_deleted1            .byte "META1 DELETED", CR, 0
str_meta_found1              .byte "META1 FOUND", CR, 0
str_meta_not_found1          .byte "META1 NOT FOUND", CR, 0
str_meta_found2              .byte "META2 FOUND", CR, 0
str_meta_found15             .byte "META15 FOUND", CR, 0
str_meta_found0              .byte "META0 FOUND", CR, 0
str_not_found_del            .byte "NON LABEL, NOT DELETED $ABCD", CR, 0
str_meta1                    .byte "META1", 0
str_meta2                    .byte "META2", 0
str_meta15                   .byte "META1.5", 0
str_meta0                    .byte "META0", 0
	      
;; -------------------------------------------------------------------------------------
;;
;; This test only tests the encoder lookup. Also to reduce unit test size, the opcodes
;; from the mnemonic table are borrowed (rather than duplicating).
;;
	
	.include "encode.inc"
	
;; -------------------------------------------------------------------------------------
	.macro assertBuffer1 op,b1 
	     bcc    :+
	     fail   str_complete_fail
	     bra    :++
:  
	     LoadW  r1,op
	     ldx    #1
	     lda    #b1
	     sta    r2L
	     jsr    testEncoderBufferAssert
:  
	.endmacro

;; -------------------------------------------------------------------------------------
	.macro assertBuffer2 op, b1,b2
	     bcc    :+
	     fail   str_complete_fail
	     bra    :++
:  
	     LoadW  r1,op
	     ldx    #2
	     lda    #b1
	     sta    r2L
	     lda           #b2
	     sta           r2H
	     jsr    testEncoderBufferAssert
:  
	.endmacro

;; -------------------------------------------------------------------------------------
	.macro assertBuffer3 op,b1,b2,b3
	     bcc    :+
	     fail   str_complete_fail
	     bra    :++
:  
	     LoadW  r1,op
	     ldx    #3
	     lda    #b1
	     sta    r2L
	     lda           #b2
	     sta           r2H
	     lda           #b3
	     sta           r3L
	     jsr    testEncoderBufferAssert
:  
	.endmacro

;; -------------------------------------------------------------------------------------
	.macro assertEq16  ra,rb,msg
	     lda     ra
	     cmp     rb
	     bne     :+
	     lda     ra+1
	     cmp     rb+1
	     bne     :+
	     pass   msg
	     bra     :++
:  
	     fail    msg
:  
	.endmacro
;; -------------------------------------------------------------------------------------
	     

testEncoder
	callR1     testHeader,str_encoder_test

	callR1            encode_get_entry,str_encoder_unk
	assertCarrySet    str_encoder_unk

	;; Test byte outputs
@testEncoderMnemonicNextTest
	callR1            encode_string,str_brk1
	assertBuffer1     str_brk1, $00

	callR1            encode_string,str_clc1
	assertBuffer1     str_clc1, $18

	callR1            encode_string,str_cld1
	assertBuffer1     str_cld1, $d8

	callR1            encode_string,str_cli1
	assertBuffer1     str_cli1, $58
	
	callR1            encode_string,str_clv1
	assertBuffer1     str_clv1, $b8
	
	callR1            encode_string,str_dex1
	assertBuffer1     str_dex1, $ca

	callR1            encode_string,str_dey1
	assertBuffer1     str_dey1, $88

	callR1            encode_string,str_inx1
	assertBuffer1     str_inx1, $e8

	callR1            encode_string,str_iny1
	assertBuffer1     str_iny1, $c8

	callR1            encode_string,str_nop1
	assertBuffer1     str_nop1, $ea

	callR1            encode_string,str_pha1
	assertBuffer1     str_pha1, $48

	callR1            encode_string,str_php1
	assertBuffer1     str_php1, $08

	callR1            encode_string,str_phx1
	assertBuffer1     str_phx1, $da

	callR1            encode_string,str_phy1
	assertBuffer1     str_phy1, $5a

	callR1            encode_string,str_pla1
	assertBuffer1     str_pla1, $68

	callR1            encode_string,str_plp1
	assertBuffer1     str_plp1, $28

	callR1            encode_string,str_plx1
	assertBuffer1     str_plx1, $fa

	callR1            encode_string,str_ply1
	assertBuffer1     str_ply1, $7a
	
	callR1            encode_string,str_rti1
	assertBuffer1     str_rti1, $40

	callR1            encode_string,str_rts1
	assertBuffer1     str_rts1, $60

	callR1            encode_string,str_sec1
	assertBuffer1     str_sec1, $38

	callR1            encode_string,str_sed1
	assertBuffer1     str_sed1, $f8

	callR1            encode_string,str_sei1
	assertBuffer1     str_sei1, $78
	
	callR1            encode_string,str_stp1
	assertBuffer1     str_stp1, $db

	callR1            encode_string,str_tax1
	assertBuffer1     str_tax1, $aa

	callR1            encode_string,str_tay1
	assertBuffer1     str_tay1, $a8

	callR1            encode_string,str_tsx1
	assertBuffer1     str_tsx1, $ba
	
	callR1            encode_string,str_txa1
	assertBuffer1     str_txa1, $8a

	callR1            encode_string,str_txs1
	assertBuffer1     str_txs1, $9a

	callR1            encode_string,str_tya1
	assertBuffer1     str_tya1, $98

	callR1            encode_string,str_wai1
	assertBuffer1     str_wai1, $cb

	;; Look for a parse fail on bad argument
	callR1            copyString,str_brk_bad_arg
	callR1            encode_string,str_tmp
	assertCarrySet    str_bad_arg_msg

	;; Tests from here on out don't test each opcode, just different opcode / argument combinations
	;; Test immediate 
	callR1            copyString,str_immed_arg
	callR1            encode_string,str_tmp 
	assertCarryClear  str_no_fail_arg
	assertBuffer2     str_immed_arg, $09, $43

	;; Test Zero Page
	callR1            copyString,str_zp_arg
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer2     str_zp_arg, $05, $45

	;; Test Absolute
	callR1            copyString,str_abs_arg
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer3     str_abs_arg, $0d, $47, $46
	
	;; Test zp,x
	callR1            copyString,str_zp_x
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer2     str_zp_x, $15, $4b
	      
	;; Test zp,y
	callR1            copyString,str_zp_y
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer2     str_zp_y, $b6, $4c
	      
	;; Test abs,x
	callR1            copyString,str_abs_x
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer3     str_abs_x, $1d, $4e, $4d

	;; Test abs,y
	callR1            copyString,str_abs_y
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer3     str_abs_y, $19, $50, $4f
	      
	;; Test X indirect
	callR1            copyString,str_ind_x
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer2     str_ind_x, $01, $48

	;; Test indirect_Y
	callR1            copyString,str_ind_y
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer2     str_ind_y, $11, $49

	;; Test zp indirect
	callR1            copyString,str_ind
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer2     str_ind, $12, $4a
	
	;; 16 bit indirect
	callR1            copyString,str_ind16
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer3     str_ind16, $6c, $52, $51
	
	;; Absolute indexed, indirect (just the JMP)
	callR1            copyString,str_abs_x_ind
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer3     str_abs_x_ind, $7c, $54, $53
	
	;; Branch addressing
	LoadW             encode_pc,$a000
	callR1            copyString,str_branch
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer2     str_branch, $80, $0e
	
	LoadW             encode_pc,$a020
	callR1            copyString,str_branch
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer2     str_branch, $80, $ee
	
	;; Test the goofy bit instructions
	callR1            copyString,str_bit_zp
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer2     str_bit_zp, $b7, $02
	
	LoadW             encode_pc,$a000
	callR1            copyString,str_bit_rel
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer3     str_bit_rel, $bf, $02, $0d

	LoadW             encode_pc,$a000
	callR1            copyString,str_jsr
	callR1            encode_string,str_tmp
	assertCarryClear  str_no_fail_arg
	assertBuffer3     str_jsr, $20, $00, $10

	LoadW             encode_pc,$a000
	callR1            copyString,str_jmp_ind
   callR1            encode_string,str_tmp
   assertCarryClear  str_no_fail_jmp_ind
   assertBuffer3     str_jmp_ind, $6c, $2, $0

@testEncoderMnemonicExit
	rts

	
;; Single byte opcodes
str_encode_cr     .byte     CR,0
str_encode_count  .byte     "ENCODE BYTE COUNT ", 0
str_encode_buffer .byte     "ENCODE BUFFER VALUE ", 0
str_complete_fail .byte     "COMPLETE DECODE FAIL", CR, 0
	
str_brk1          .byte     "BRK", 0
str_clc1          .byte     "CLC", 0
str_cld1          .byte     "CLD", 0
str_cli1          .byte     "CLI", 0
str_clv1          .byte     "CLV", 0
str_dex1          .byte     "DEX", 0
str_dey1          .byte     "DEY", 0
str_inx1          .byte     "INX", 0
str_iny1          .byte     "INY", 0
str_nop1          .byte     "NOP", 0
str_pha1          .byte     "PHA", 0
str_php1          .byte     "PHP", 0
str_phx1          .byte     "PHX", 0
str_phy1          .byte     "PHY", 0
str_pla1          .byte     "PLA", 0
str_plp1          .byte     "PLP", 0
str_plx1          .byte     "PLX", 0
str_ply1          .byte     "PLY", 0
str_rti1          .byte     "RTI", 0
str_rts1          .byte     "RTS", 0
str_sec1          .byte     "SEC", 0
str_sed1          .byte     "SED", 0
str_sei1          .byte     "SEI", 0
str_stp1          .byte     "STP", 0
str_tax1          .byte     "TAX", 0
str_tay1          .byte     "TAY", 0
str_tsx1          .byte     "TSX", 0
str_txa1          .byte     "TXA", 0
str_txs1          .byte     "TXS", 0
str_tya1          .byte     "TYA", 0
str_wai1          .byte     "WAI", 0

; Make sure each argument has a different hex value to test the parsing and buffer stuffing
str_brk_bad_arg   .byte     "BRK #42", 0      ; Yep, this is bad syntax!
str_bad_arg_msg   .byte     "DETECT INVALID ARGUMENT", CR, 0
str_no_fail_arg   .byte     "ARGUMENT PARSED", CR, 0
str_no_fail_jmp_ind .byte     "JMP ($2) PARSE", CR, 0	
str_immed_arg     .byte     "ORA #$43", 0
str_zp_arg        .byte     "ORA $45", 0
str_abs_arg       .byte     "ORA $4647", 0
str_ind_x         .byte     "ORA ($48,X)", 0
str_ind_y         .byte     "ORA ($49),Y", 0
str_ind           .byte     "ORA ($4A)", 0
str_zp_x          .byte     "ORA $4B,X", 0
str_zp_y          .byte     "LDX $4C,Y", 0
str_abs_x         .byte     "ORA $4D4E,X", 0
str_abs_y         .byte     "ORA $4F50,Y", 0
str_ind16         .byte     "JMP ($5152)", 0
str_abs_x_ind     .byte     "JMP ($5354,X)", 0
str_branch        .byte     "BRA $A010", 0
str_bit_zp        .byte     "SMB 3,$02", 0
str_bit_rel       .byte     "BBS 3,$02,$A010", 0
str_jsr           .byte     "JSR $1000", 0
str_jmp_ind       .byte     "JMP ($2)", 0
;;
;; Special assert for this test
;; Input X   - byte Count
;;       r1  - msg
;;       r2  - 1st two bytes of buffer
;;       r3L - last byte of byffer
;;
testEncoderBufferAssert
	phx
	MoveW   r1,T1
	
	cpx   encode_buffer_size
	beq   :+
	jsr   testFail
	bra   @testEncoderBufferBufferTest
:  
	jsr   testPass
	      
@testEncoderBufferBufferTest
	MoveW    T1,r1
	jsr      prtstr
	callR1   prtstr,str_buffer_count
	
	plx
	;;
	;; Buffer test [0]
	;;
	lda      r2L
	cmp      code_buffer
	bne      :+
	dex
	bne      @testEncoderBufferTest2
	jmp      @testEncoderBufferPass
:  
	fail     str_buffer_0
	jmp      @testEncoderBufferName
	      
@testEncoderBufferTest2
	;;
	;; Buffer test [1]
	;;
	lda      r2H
	cmp      code_buffer+1
	bne      :+
	dex
	bne      @testEncoderBufferTest3
	jmp      @testEncoderBufferPass
:  
	fail     str_buffer_1
	bra      @testEncoderBufferName
	      
@testEncoderBufferTest3
	;;
	;; Buffer test [3]
	;;
	lda      r3L
	cmp      code_buffer+2
	beq      @testEncoderBufferPass
	fail     str_buffer_2
	bra      @testEncoderBufferName

@testEncoderBufferPass
	pass     str_buffer_pass
	bra      @testEncoderBufferExit
	      
@testEncoderBufferName
	MoveW    T1,r1
	jsr      prtstr
	
@testEncoderBufferExit
	callR1   prtstr,str_encode_cr
	rts

	
str_buffer_count  .byte " BUFFER_COUNT", CR, 0
str_buffer_0      .byte "BUFFER[0] ", 0
str_buffer_1      .byte "BUFFER[1] ", 0
str_buffer_2      .byte "BUFFER[2] ", 0
str_buffer_pass   .byte "BUFFER[] ", CR, 0
;;
;;
;;
	
testEncoderPrintInstruction
	ldy               #0
@testEncoderMenmonicPrtinstLoop
	lda               (r1),y
	jsr               petscii_to_scr
	charOutA
	iny
	tya
	cmp               #3
	bne               @testEncoderMenmonicPrtinstLoop
	rts

	
str_encoder_test   .byte  "ENCODER OPCODE LOOKUP",CR,0
str_encoder_unk    .byte  "FOO",CR,0
str_encoder_found  .byte  "INSTRUCTION FOUND: ", 0
str_encoder_cr     .byte  CR,0

;; -------------------------------------------------------------------------------------
;;

testEncoder2
	callR1      testHeader,str_encoder_2
	
	;; ----- Test 1
	jsr            clear_encode_buffer
	LoadW          encode_pc,$1000
	callR1         copyString,str_encode2_byte
	callR1         encode_string,str_tmp
	assertCarryClear  str_encode2_encoded
	
	lda            encode_buffer_size
	assertEqA      1,str_encode2_byte_count
	assertBuffer1  str_encode2_buffer_val,$42
	
	LoadW          r1,$1000
	jsr            meta_find_expr
	assertEqZ      str_encode2_found_expr
	
	LoadW          r1,$1000
	jsr            meta_delete_expr
	jsr            meta_find_expr
	assertNeZ      str_encode2_delete_expr
	
	;; ----- Test 2
	jsr            clear_encode_buffer
	callR1         copyString,str_encode2_byte2
	callR1         encode_string,str_tmp
	assertCarryClear  str_encode2_encoded
	
	lda            encode_buffer_size
	assertEqA      3,str_encode2_byte_count
	assertBuffer3  str_encode2_buffer_val,$1,$2,$3
	
	;; ----- Test 3
	jsr            clear_encode_buffer
	callR1         copyString,str_encode2_word
	callR1         encode_string,str_tmp
	assertCarryClear  str_encode2_encoded
	
	lda            encode_buffer_size
	assertEqA      6,str_encode2_byte_count
	LoadW          T1,code_buffer
	lda            (T1)
	assertEqA      $34,str_encode2_buffer_wal
	
	ldy            #1
	lda            (T1),y
	assertEqA      $12,str_encode2_buffer_wal
	
	ldy            #2
	lda            (T1),y
	assertEqA      $cd,str_encode2_buffer_wal
	
	ldy            #3
	lda            (T1),y
	assertEqA      $ab,str_encode2_buffer_wal
	
	ldy            #4
	lda            (T1),y
	assertEqA      $04,str_encode2_buffer_wal
	
	ldy            #5
	lda            (T1),y
	assertEqA      $02,str_encode2_buffer_wal
	
	;; ----- Test 4
	jsr            clear_encode_buffer
	callR1         copyString,str_encode2_cstr
	callR1         encode_string,str_tmp
	assertCarryClear str_encode2_encoded
	lda             encode_buffer_size
	assertEqA       4,str_encode2_byte_count
	LoadW           T1,code_buffer
	
	lda               (T1)
	assertEqA         'F',str_encode2_buffer_cstr
	
	ldy               #1
	lda               (T1),y
	assertEqA         'O',str_encode2_buffer_cstr
	
	ldy               #2
	lda               (T1),y
	assertEqA         'O',str_encode2_buffer_cstr
	
	ldy               #3
	lda               (T1),y
	assertEqA         0,str_encode2_buffer_cstr
	
	;; ----- Test 5
	jsr            clear_encode_buffer
	callR1         copyString,str_encode2_pstr
	callR1         encode_string,str_tmp
	assertCarryClear  str_encode2_encoded
	lda             encode_buffer_size
	assertEqA       4,str_encode2_byte_count
	LoadW           T1,code_buffer
	
	lda               (T1)
	assertEqA         3,str_encode2_buflen_pstr
	
	ldy               #1
	lda               (T1),y
	assertEqA         'B',str_encode2_buffer_pstr
	
	ldy               #2
	lda               (T1),y
	assertEqA         'A',str_encode2_buffer_pstr
	
	ldy               #3
	lda               (T1),y
	assertEqA         'R',str_encode2_buffer_pstr
	rts
	
	
str_encoder_2           .byte "PSEUDO ENCODE", CR, 0
str_encode2_byte        .byte ".BYTE $42", 0
str_encode2_encoded     .byte "ENCODED PSEUDO OP", CR, 0
str_encode2_byte_count  .byte "BYTE COUNT", CR, 0
str_encode2_buffer_val  .byte "PSEUDO BYTE BUFFER", CR, 0
str_encode2_byte2       .byte ".BYTE $1,$2,$3",0
str_encode2_word        .byte ".WORD $1234,$ABCD,$0204",0
str_encode2_buffer_wal  .byte "PSEUDO WORD BUFFER", CR, 0
	       DQ = $22
str_encode2_cstr        .byte ".CSTR ", DQ, "FOO", DQ, 0
str_encode2_buffer_cstr .byte "CSTR MATCHED", CR, 0
str_encode2_pstr        .byte ".PSTR ", DQ, "BAR", DQ, 0
str_encode2_buflen_pstr .byte "PSTR LENGTH", CR, 0
str_encode2_buffer_pstr .byte "PSTR MATCHED", CR, 0

str_encode2_found_expr  .byte "PSEUDO EXPR FOUND", CR, 0
str_encode2_delete_expr .byte "DELETE PSEUDO EXPR", CR, 0

;;
;; Clear encode buffer
;;
clear_encode_buffer
	LoadW          r1,code_buffer
	ldy            #(ENCODE_BUFFER_MAX-1)
	lda            #0
@clear_encode_buffer_loop
	sta            (r1),y
	dey
	bpl            @clear_encode_buffer_loop
	
	rts

;; -------------------------------------------------------------------------------------
;;

testUtility2
	LoadW       T2,3
	callR1      testHeader,str_util_test
	
	;;
	;; Test 16 bit compare macro
	;;
	;; ------------------         
	LoadW      r1,$0100
	LoadW      r2,$FFFF
	ifLT       r1,r2,@lt_pass
	
	fail       str_lt_macro
	bra        :+
@lt_pass
	pass       str_lt_macro
:  

	;; ------------------         
	LoadW      r1,$FFFF
	LoadW      r2,$0100
	ifLT       r1,r2,@lt_fail
	
	pass       str_lt_macro
	bra        :+
@lt_fail
	fail       str_lt_macro
:  

	;; ------------------         
	LoadW      r1,$0100
	LoadW      r2,$FFFF
	ifGE       r1,r2,@ge_fail
	
	pass       str_ge_macro
	bra        :+
@ge_fail
	fail       str_ge_macro
	:  
	;; ------------------         
	LoadW      r1,$FFFF
	LoadW      r2,$0100
	ifGE       r1,r2,@ge_pass
	
	fail       str_ge_macro
	bra        :+
@ge_pass
	pass       str_ge_macro
:  
	;; ------------------         
	;;
	;; String utility methods
	;;
	callR1      util_trim_string,str_util_trimee
	assertEqR1  str_util_trimmed
	
	callR1      copyString,str_util_trimmed
	LoadW       r1,str_tmp
	lda         #' '
	jsr         util_split_string
	assertEqR1  str_util_trimmed1
	MoveW       r2,r1
	assertEqR1  str_util_trimmed2
	
	callR1      copyString,str_util_trimmed_comma
	LoadW       r1,str_tmp
	lda         #','
	jsr         util_split_string
	assertEqR1  str_util_trimmed_comma1
	MoveW       r2,r1
	assertEqR1  str_util_trimmed_comma2
	
	LoadW       r1,str_util_contains_comma
	ldx         #','
	jsr         util_str_contains
	assertEqZ   str_util_contains_comma
	callR1      prtstr,str_cr
	
	LoadW       r1,str_util_not_contains
	ldx         #' '
	jsr         util_str_contains
	assertNeZ   str_util_not_contains
	callR1      prtstr,str_cr
	
	callR1R2    util_ends_with,str_end_test,str_suffix1
	pha
	assertEqZ   str_suffix1
	callR1      prtstr,str_cr
	pla
	assertEqA   11,str_end_length_msg             ; Length of str_end_test
	
	callR1R2    util_ends_with,str_end_test,str_suffix2
	assertNeZ   str_suffix2
	callR1      prtstr,str_cr
	
	;;
	;; Strcmp
	;;
	LoadW       r1,str_hex2
	LoadW       r2,str_hex2
	jsr         util_strcmp
	assertEqZ   str_strcmp_eq
	
	LoadW       r2,str_hex3
	jsr         util_strcmp
	assertNeZ   str_strcmp_eq
	
	jsr         util_strcmp
	assertEqA   $1,str_strcmp_lt
	
	LoadW       r1,str_hex3
	LoadW       r2,str_hex2
	jsr         util_strcmp
	assertEqA   $ff,str_strcmp_gt
	
	;;
	;; Hex parsing
	;;
	;; Hex1 
	callR1      util_parse_hex,str_hex1
	PushW       r1
	lda         r1L
	assertEqA   $34,str_hex1_msg
	PopW        r1
	lda         r1H
	assertEqA   $12,str_hex1_msg
	
	;; Hex2
	callR1      util_parse_hex,str_hex2
	PushW       r1
	lda         r1L
	assertEqA   $cd,str_hex2_msg
	PopW        r1
	lda         r1H
	assertEqA   $ab,str_hex2_msg
	
	;; Hex3
	callR1      util_parse_hex,str_hex3
	assertCarrySet  str_hex3_msg
	
	;; Hex4
	callR1      util_parse_hex,str_hex4
	assertCarrySet  str_hex4_msg
	
	rts
	
	
str_util_test     .byte "UTILITY ROUTINES 2", CR, 0
str_util_trimee   .byte "    ABC TRIM TEST 123     ", 0
str_util_trimmed  .byte "ABC TRIM TEST 123", 0
str_util_trimmed1 .byte "ABC", 0
str_util_trimmed2 .byte "TRIM TEST 123", 0

str_util_trimmed_comma  .byte "ABC,DEF", 0
str_util_trimmed_comma1 .byte "ABC", 0
str_util_trimmed_comma2 .byte "DEF", 0

str_util_contains_comma .byte "CONTAINS,COMMA", 0
str_util_not_contains   .byte "CONTAINS-NO-SPACE", 0

str_end_test      .byte "ABC EDF XYZ", 0
str_suffix1       .byte "XYZ", 0
str_suffix2       .byte "WXYZ", 0

str_hex1          .byte "1234", 0
str_hex1_msg      .byte "HEX1 PARSE", CR, 0
str_hex2          .byte "ABCD", 0
str_hex2_msg      .byte "HEX2 PARSE", CR, 0
str_hex3          .byte "XYZ", 0
str_hex3_msg      .byte "HEX3 FAIL PARSE", CR, 0
str_hex4          .byte "1234567", 0
str_hex4_msg      .byte "HEX4 FAIL PARSE", CR, 0
str_end_length_msg .byte "ENDS WITH LENGTH RETURN", CR, 0

str_lt_macro      .byte "LT MACRO", CR, 0
str_ge_macro      .byte "GE MACRO", CR, 0

str_strcmp_eq     .byte "STRCMP =", CR, 0
str_strcmp_lt     .byte "STRCMP <", CR, 0
str_strcmp_gt     .byte "STRCMP >", CR, 0

str_tmp           .res 64,0
	
;;
;; Copy source in r1 to str_tmp
copyString
	LoadW  T1,str_tmp
	ldy   #0
@copyLoop
	lda   (r1),y
	sta   (T1),y
	beq   @copyDone
	iny
	bra   @copyLoop
@copyDone
	rts
	      
;; -------------------------------------------------------------------------------------
	
	.include "edit.inc"
	.include "meta_i.inc"
	
	EDIT_RGN_SIZE=64
	     
testCodeEdit
	callR1     testHeader,str_edit_header
	
	jsr        testClearEditRgn
	
	callR1     meta_clear_meta_data,edit_region_start
	
	LoadW      r1,edit_region_start
	ldx        #3
	jsr        edit_insert
	
	;; Edit test 1
	pushBankVar    bank_meta_l
	LoadW      TMP1,edit_region_start+2
	
	lda        meta_rgn_end
	sta        TMP2L
	lda        meta_rgn_end+1
	sta        TMP2H
	assertEq16  TMP1,TMP2,str_rgn_end_adjust
	popBank
	
	LoadW      r1,edit_region_start
	ldy        #2
@push1
	tya
	inc
	sta        (r1),y
	dey
	cpy        #$ff
	bne        @push1
	
	;; Add 3 new bytes
	LoadW      r1,edit_region_start
	ldx        #3
	jsr        edit_insert
	
	;; Edit test 2, make sure the push moved existing bytes
	LoadW      T1,edit_region_start
	ldy        #3
	lda        (T1),y
	assertEqA  1,str_push_value
	ldy        #4
	lda        (T1),y
	assertEqA  2,str_push_value
	ldy        #5
	lda        (T1),y
	assertEqA  3,str_push_value
	
	;; Edit test 3, do delete and make sure region ends are modified AND bytes are copied
	LoadW      r1,edit_region_start
	ldx        #2
	jsr        edit_delete
	
	pushBankVar    bank_meta_l
	lda        meta_rgn_end
	sta        TMP2L
	lda        meta_rgn_end+1
	sta        TMP2H
	
	lda        #<(edit_region_start+3)
	sta        TMP1L
	lda        #>(edit_region_start+3)
	sta        TMP1H
	assertEq16  TMP1,TMP2,str_rgn_end_adjust
	popBank
	
	;; Edit test 4, make sure the bottom of the block is pulled up.
	LoadW      TMP1,edit_region_start
	ldy        #0
	lda        (TMP1),y
	assertEqA  3,str_pull_value
	
	ldy        #1
	lda        (TMP1),y
	assertEqA  1,str_pull_value
	
	ldy        #2
	lda        (TMP1),y
	assertEqA  2,str_pull_value
	
	ldy        #3
	lda        (TMP1),y
	assertEqA  3,str_pull_value
	
	rts
	
	
str_edit_header    .byte "CODE EDIT", CR, 0
str_rgn_end_adjust .byte "REGION END ADJUSTMENT", CR, 0
str_push_value     .byte "INSERT COPY VALUES", CR, 0
str_pull_value     .byte "DELETE COPY VALUES", CR, 0

;; editor buffer space
edit_region_start .res EDIT_RGN_SIZE,0
edit_region_edit

testClearEditRgn
	;; clear the test buffer
	LoadW      r1,edit_region_start
	ldy        #EDIT_RGN_SIZE-1
	lda        #0
@clear
	sta        (r1),y
	dey
	cpy        #$ff
	bne        @clear
	
	rts

;; -------------------------------------------------------------------------------------
	     
testCodeReloc
	callR1     testHeader,str_reloc_header
	
	jsr        testClearEditRgn
	
	callR1     meta_clear_meta_data,edit_region_start
	
	LoadW      r1,edit_region_start
	ldx        #1
	jsr        edit_insert
	
	lda        #RTS_INSTRUCTION
	sta        (r1)
	
	LoadW      r1,edit_region_start
	LoadW      r2,str_reloc_main
	jsr        meta_add_label
	
	;; Add a JMP MAIN
	LoadW      r1,edit_region_start
	LoadW      r2,(edit_region_start+3)
	jsr        test_add_jmp
	
	LoadW      r1,str_reloc_insert
	LoadW      r2,edit_region_start
	lda        #JMP_INSTRUCTION
	sta        r3L
	lda        #<(edit_region_start+3)
	sta        r3H
	lda        #>(edit_region_start+3)
	sta        r4L
	jsr        test_reloc_assert
	
	;; Add another jump, make sure relocation for ABS processes
	LoadW      r1,edit_region_start
	LoadW      r2,(edit_region_start+6)
	jsr        test_add_jmp
	
	LoadW      r1,str_reloc_insert
	LoadW      r2,edit_region_start
	lda        #JMP_INSTRUCTION
	sta        r3L
	lda        #<(edit_region_start+6)
	sta        r3H
	lda        #>(edit_region_start+6)
	sta        r4L
	jsr        test_reloc_assert
	
	LoadW      r2,(edit_region_start+3)
	jsr        test_reloc_assert
	
	;; -----------------------------------------------------
	;; Relative addressing
	;; -----------------------------------------------------
	jsr        testClearEditRgn
	
	;; back branch
	callR1     meta_clear_meta_data,edit_region_start
	LoadW      r1,edit_region_start
	ldx        #3
	jsr        edit_insert              ; So region begin and end are properly set
	
	LoadW      r1,edit_region_start
	ldy        #0
	lda        #NOP_INSTRUCTION
	sta        (r1),y
	iny
	lda        #BRA_INSTRUCTION
	sta        (r1),y
	iny
	lda        #$FD
	sta        (r1),y
	
	;; Insert NOP in between branch and target
	LoadW      r1,edit_region_start+1
	ldx        #1
	jsr        edit_insert
	ldy        #2                                ; Because r1 = insert point
	lda        (r1),y
	assertEqA  $fc,str_reloc_rel_1
	
	;; fwd branch
	callR1     meta_clear_meta_data,edit_region_start
	LoadW      r1,edit_region_start
	ldx        #3
	jsr        edit_insert              ; So region begin and end are properly set
	
	LoadW      r1,edit_region_start
	ldy        #0
	lda        #BRA_INSTRUCTION
	sta        (r1),y
	iny
	
	lda        #0
	sta        (r1),y
	iny
	
	lda        #NOP_INSTRUCTION
	sta        (r1),y
	
	;; insert NOP between branch and target
	LoadW      r1,edit_region_start+2
	ldx        #1
	jsr        edit_insert
	LoadW      r1,edit_region_start+1
	lda        (r1)
	assertEqA  1,str_reloc_rel_1
	
	rts

	
str_reloc_header  .byte "CODE RELOCATION", CR, 0
str_reloc_main    .byte "MAIN", 0                      ; This is a label, no CR!
str_reloc_insert  .byte "JMP INSERTED", CR, 0
str_reloc_rel_1   .byte "BRA RELOCATED", CR, 0

;;
;; Add a jump to the test code
;; Input r1 - insert location
;;       r2 - JMP destination
;;
test_add_jmp
	PushW      r2
	ldx        #3
	jsr        edit_insert
	PopW       r2
	
	ldy        #0
	lda        #JMP_INSTRUCTION
	sta        (r1),y
	iny
	lda        r2L
	sta        (r1),y
	iny
	lda        r2H
	sta        (r1),y
	rts
	
;;
;; composite assert to make sure inserted memory is correct
;; Input r1 - msg
;;       r2 - relocate address
;;       r3L, r2H, r4L - bytes
;;
test_reloc_assert
	ldy         #0
	lda         (r2),y
	cmp         r3L
	bne         @test_reloc_fail
	
	iny
	lda         (r2),y
	cmp         r3H
	bne         @test_reloc_fail
	
	iny
	lda         (r2),y
	cmp         r4L
	bne         @test_reloc_fail
	
	jsr         testPass
	jsr         prtstr
	rts

@test_reloc_fail
	jsr         testFail
	jsr         prtstr
	rts

;; -------------------------------------------------------------------------------------
	     
testMetaInstruction
	callR1       testHeader,str_meta_instruction
	
	jsr          meta_clear_meta_data
	
	LoadW        r2,$1000
	callR1       encode_parse_expression,str_expr_constant
	LoadW        T1,$1234
	assertEq16   r1,T1,str_meta_constant
	callR1       meta_find_expr,$1000
	assertNeZ    str_expr_found
	
	;; >$1234
	LoadW        encode_pc,$1010
	callR1       encode_parse_expression,str_expr_hi_constant
	LoadW        T1,$12
	assertEq16   r1,T1,str_meta_hi_constant
	callR1       meta_find_expr,$1010
	beq          :+
	fail         str_expr_found
	bra          :++
	
:
	LoadW        r2,$1010
	LoadW        r3,$1234
	lda          #META_FN_HI_BYTE
	sta          r4L
	jsr          assertExpr
	
:  
	;; <$1234
	LoadW        encode_pc,$1020
	callR1       encode_parse_expression,str_expr_lo_constant
	LoadW        TMP1,$34
	assertEq16   r1,TMP1,str_meta_lo_constant
	callR1       meta_find_expr,$1020
	beq          :+
	fail         str_expr_found
	bra          :++
	
:  
	LoadW        r2,$1020
	LoadW        r3,$1234
	lda          #META_FN_LO_BYTE
	sta          r4L
	jsr          assertExpr         
	
:  

	callR1       meta_find_expr,$1010
	assertEqZ    str_expr_found
	
	callR1       meta_find_expr,$1000
	assertNeZ    str_expr_found
	
	;; Check label parsing on instructions
	LoadW        r2,$1234
	callR1       meta_add_label,str_expr_label_value
	callR1       encode_parse_expression,str_expr_label_value
	;; need to stash carry so it can test after testing r1 return value
	php
	LoadW        TMP2,$1234
	assertEq16   r1,TMP2,str_expr_label_valok
	plp
	assertCarryClear  str_expr_label_valid
	rts

	
str_meta_instruction .byte "META INSTRUCTION", CR, 0
str_meta_constant    .byte "MATCH $1234", CR, 0
str_expr_constant    .byte "$1234", 0
str_meta_hi_constant .byte ">$1234", CR, 0
str_expr_hi_constant .byte ">$1234", 0
str_meta_lo_constant .byte "<$1234", CR, 0
str_expr_lo_constant .byte "<$1234", 0
str_expr_found       .byte "FIND EXPR", CR, 0
str_expr_addr_match  .byte "MATCH ADDRESS", CR, 0
str_expr_func_match  .byte "MATCH FUNCTION", CR, 0
str_expr_value_match .byte "MATCH VALUE", CR, 0
str_expr_label_value .byte "EXPLABEL", 0
str_expr_label_valid .byte "LABEL PARSED", CR, 0
str_expr_label_valok .byte "LABEL VALUE OK", CR, 0

;;
;; assert for expressions
;; Input r1 - ptr to expression
;;       r2 - expected address
;;       r3 - expected value
;;       r4L - expression function
assertExpr
	pushBankVar    bank_meta_i
	
	                             ;; Test address
	ldy          #0
	lda          (r1),y
	sta          TMP1L
	iny
	lda          (r1),y
	sta          TMP1H
	PushW        r1
	assertEq16   TMP1,r2,str_expr_addr_match
	
	;; Test function
	PopW         r1
	PushW        r1
	ldy          #2
	lda          (r1),y
	cmp          r4L
	bne          :+
	pass         str_expr_func_match
	bra          :++
:  
	fail         str_expr_func_match
:  
	      
	;; Test value
	PopW         r1
	ldy          #3
	lda          (r1),y
	sta          TMP1L
	iny
	lda          (r1),y
	sta          TMP1H
	assertEq16   r3,TMP1,str_expr_value_match
	
	popBank
	rts

;;
;; -------------------------------------------------------------------------------------
;;

testScrollback
	callR1       testHeader,str_scrollback
	
	jsr          screen_clear_scrollback
	
	;; -----
	;; test 1
	LoadW        r1,$6000
	jsr          screen_get_prev_scrollback_address
	assertCarrySet  str_sb_not_found
	
	;; -----
	;; test 2
	LoadW        r1,$6000
	jsr          screen_add_scrollback_address
	assertCarryClear  str_sb_added
	
	jsr          screen_get_prev_scrollback_address
	assertCarryClear   str_sb_found
	LoadW            T1,$6000
	assertEq16       r0,T1,str_sb_address
	
	;; -----
	;; test 2.5
	jsr          screen_clear_scrollback
	
	LoadW        r1,$6000   
	jsr          screen_add_scrollback_address
	assertCarryClear  str_sb_added
	
	LoadW        r1,$6003
	jsr          screen_add_scrollback_address
	assertCarryClear  str_sb_added
	
	jsr          screen_get_prev_scrollback_address
	assertCarryClear  str_sb_found
	LoadW        T1,$6003
	assertEq16   r0,T1,str_sb_address
	
	jsr          screen_get_prev_scrollback_address
	assertCarryClear  str_sb_found
	
	LoadW        T1,$6000
	assertEq16   r0,T1,str_sb_address
	
	jsr          screen_get_prev_scrollback_address
	assertCarrySet  str_sb_not_found
	
	;; ----
	;; test 3, ensure the scrollback buffer doesn't overflow and it will internally scroll.
	jsr          screen_clear_scrollback
	LoadW        T1,SCROLLBACK_COUNT+1
	
	;; prep
	;; Fill sb stack with capacity+1
@sb_test_3_loop
	MoveW        T1,r1
	jsr          screen_add_scrollback_address
	DecW         T1
	lda          T1L
	ora          T1H
	bne          @sb_test_3_loop
	
	;; test
	;; drain the stack, last item should be SCROLLBACK_COUNT
@sb_test_3_loop2
	jsr          screen_get_prev_scrollback_address
	bcc          @sb_test_3_loop2
	LoadW        T1,SCROLLBACK_COUNT
	assertEq16   r0,T1,str_sb_overflow
	
	;; ----
	;; test 7, ensure that the scrollback buffer rolls
	rts

	
str_scrollback        .byte "SCROLLBACK", CR, 0
str_sb_not_found      .byte "SCROLLBACK NOT FOUND", CR, 0
str_sb_found          .byte "SCROLLBACK FOUND", CR, 0
str_sb_address        .byte "ADDRESS MATCH", CR, 0
str_sb_added          .byte "SCROLLBACK ADDED", CR, 0
str_sb_overflow       .byte "SCROLLBACK OVERFLOW", CR, 0

;; -------------------------------------------------------------------------------------
;;

	.include "meta.inc"

;; -------------------------------------------------------------------------------------
;;
;; Display color bars
;;
color_bars
	jsr     clear
	
	lda     #0
	sta     r3L
	
	vgotoXY   1,5
	
color_bars_loop
	ldx     r3L
	jsr     prthex
	
	lda     #CHR_SPACE
	sta     VERA_DATA1
	lda     #0
	sta     VERA_DATA1
	
	lda     r3L
	asl
	asl
	asl     
	asl
	ora     r3L
	tax
	
	lda     #CHR_SPACE
	sta     VERA_DATA1
	stx     VERA_DATA1
	
	sta     VERA_DATA1
	stx     VERA_DATA1
	
	sta     VERA_DATA1
	stx     VERA_DATA1
	
	
	lda     #1
	sta     SCR_COL
	inc     SCR_ROW
	inc     SCR_ROW
	vgoto
	
	inc     r3L
	lda     r3L
	cmp     #$10
	bmi     color_bars_loop
	
	rts

;;
;; Pager - put up "press key to continue", then erase screen
;;
pager
	phy
	
	lda     SCR_ROW
	cmp     #MAX_ROW
	bmi     pager_exit
	
	lda     r1H
	pha
	lda     r1L
	pha
	
	vgotoXY  0,MAX_ROW+1
	
	LoadW    r1,str_press_any
	ldy      #0

pager_prt_loop
	lda     (r1),y
	beq     pager_wait
	jsr     petscii_to_scr
	charOutA
	iny
	bra     pager_prt_loop

pager_wait
	jsr     GETIN
	beq     pager_wait
	
	lda     #CLS
	jsr     CHROUT
	
	vgotoXY  0,0
	
	callR1  prtstr,str_continuing
	
	pla
	sta     r1L
	pla
	sta     r1H

pager_exit
	ply
	rts

;
; slurped from: http://6502.org/source/integers/hex2dec-more.htm
;
; Convert an 16 bit binary value to BCD
;
; This function converts a 16 bit binary value into a 24 bit BCD. It
; works by transferring one bit a time from the source and adding it
; into a BCD value that is being doubled on each iteration. As all the
; arithmetic is being done in BCD the result is a binary to decimal
; conversion. All conversions take 915 clock cycles.
;
; See BINBCD8 for more details of its operation.
;
; Andrew Jacobs, 28-Feb-2004

binbcd16:
	sed		   ; Switch to decimal mode
;            LDA #0		; Ensure the result is clear
	stz BCD+0
	stz BCD+1
	stz BCD+2
	ldx #16		; The number of source bits

cnvbit
	asl BIN+0	; Shift out one bit
	rol BIN+1
	lda BCD+0	; And add into result
	adc BCD+0
	sta BCD+0
	lda BCD+1	; propagating any carry
	adc BCD+1
	sta BCD+1
	lda BCD+2	; ... thru whole result
	adc BCD+2
	sta BCD+2
	dex		   ; And repeat for next bit
	bne cnvbit
	cld		   ; Back to binary
	rts

;;
;; Print test count summary
;;
print_summary
	stz   SCR_COL
	inc   SCR_ROW
	vgoto
	
	;; Print passed count
	lda     orig_color
	sta     K_TEXT_COLOR

	callR1  prtstr,str_test_passed
	callR1  prtdec,passed_count
	lda   #'/'
	charOutA
	callR1  prtdec,total_count
	
	stz   SCR_COL
	inc   SCR_ROW
	vgoto
	
	;; print failed count
	lda     #COLOR_CDR_FAIL
	jsr     screen_set_fg_color
	
	callR1  prtstr,str_test_failed
	callR1  prtdec,failed_count
	lda   #'/'
	charOutA
	callR1 prtdec,total_count
	
	stz   SCR_COL
	inc   SCR_ROW
	vgoto
	
	rts

;;
;; print decimal
;; Input R1 - Address of input number
;;
prtdec
	ldy   #0
	lda   (r1),y
	sta   BIN
	iny
	lda   (r1),y
	sta   BIN+1
	jsr   binbcd16
	
	lda   #0
	sta   prtdec_prt_zeros
	
	lda   BCD+2
	jsr   prtdec_digit
	
	lda   BCD+1
	jsr   prtdec_digit
	
	lda   BCD
	jsr   prtdec_digit
	
	lda   prtdec_prt_zeros
	bne   prtdec_skip
	
	lda   #'0'
	charOutA
	
prtdec_skip
	rts

;;
;; Print decimal values in A
;;
prtdec_digit
	pha
	lsr
	lsr
	lsr
	lsr
	pha
	ora   prtdec_prt_zeros
	beq   :+                    ; skip this digit
	pla
	clc
	adc   #$30
	charOutA
	lda   #1
	sta   prtdec_prt_zeros
	bra   prtdec_digit_2
:  
	pla                        ; discard leading zero
prtdec_digit_2
	pla
	and   #$0f
	pha
	ora   prtdec_prt_zeros
	beq   prtdec_digit_2_skip
	pla
	adc   #$30
	charOutA
	lda   #1
	sta   prtdec_prt_zeros
	rts

prtdec_digit_2_skip
	pla                        ; discard leading zero
	rts
;;
;;
;;

	
str_version          .byte      "CODEX16 TEST DRIVER 2021-03-31", CR, CR
str_test             .byte      CR, "TEST: ", 0 
str_test_passed      .byte      "PASSED: ", 0
str_test_failed      .byte      "FAILED: ", 0
str_test_fatal       .byte      "FATAL : ", 0
str_test_expected    .byte      "EXPECTED '", 0
str_test_matched     .byte      "MATCHED  '", 0
str_test_saw         .byte      "' SAW '", 0
str_unimplemented    .byte      "UNIMPLEMENTED", 0
str_unexpected_value .byte      " UNEXPECTED VALUE: $", 0
str_press_any        .byte      "PRESS ANY KEY...", 0
str_continuing       .byte      "CONTINUING", CR, CR, 0

	
	.include "screen_vars.inc"
	.include "encode_vars.inc"
 
prtdec_prt_zeros   .byte 0          ; If true, print zeros, used to trim leading zeros
BIN                .word 0
BCD                .byte 0,0,0
	                
