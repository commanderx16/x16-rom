	;;
	;; Commander 16 CodeX Interactive Assembly Environment
	;; Text decompiler. Designed to be called from ROM'ed CodeX
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

	COL_INST_BYTES=8          ;; Column to start printing the instruction bytes
	COL_INSTRUCTION=17        ;; Column to start printing instruction
	COL_ARGUMENTS=COL_INSTRUCTION + 7

	ROW_MAX = 59

	ROW_FIRST_INSTRUCTION=3   ;; First row to display instructions
	ROW_LAST_INSTRUCTION=ROW_MAX - 4

	DBG_BOX_WIDTH=18          ;; Registers, breakpoints, watch locations
	DBG2_BOX_WIDTH=12         ;; Stack, Zero page registers

	ASSY_LAST_COL=50
	SIDE_BAR_X = ASSY_LAST_COL

	STACK_COL = SIDE_BAR_X + DBG_BOX_WIDTH
	STACK_ROW = DATA_ROW
	STACK_BOX_HEIGHT = 20
	
	REGISTER_COL = SIDE_BAR_X + 6
	REGISTER_ROW = STACK_ROW
	REGISTER_BOX_HEIGHT = 20
	
	PSR_COL = SIDE_BAR_X
	PSR_ROW = REGISTER_ROW + REGISTER_BOX_HEIGHT 
	PSR_BOX_HEIGHT = 15
	PSR_BOX_WIDTH = 15
	
	WATCH_COL = SIDE_BAR_X
	WATCH_ROW = PSR_ROW + PSR_BOX_HEIGHT 
	WATCH_BOX_HEIGHT = 20
	WATCH_BOX_WIDTH = DBG_BOX_WIDTH + DBG2_BOX_WIDTH
	
	VERA_COL = PSR_COL + PSR_BOX_WIDTH
	VERA_ROW = PSR_ROW
	VERA_BOX_WIDTH = 15
	VERA_BOX_HEIGHT = PSR_BOX_HEIGHT

	MEM_NUMBER_OF_BYTES=$10

;;      R0 - Parameters, saved in routines
;;      R1 - Parameters, saved in routines
;;      R2 - Parameters, saved in routines
;;      R3 - Parameters, saved in routines
;;      R4 - Parameters, saved in routines
;;      R5 - Parameters, saved in routines
	
;;      R6
;;      R7
;;      R8
;;      R9
;;      R10 - code_buffer
	
;;      R11 - scratch, not saved
;;      R12 - scratch, not saved
;;      R13 - scratch, not saved
;;      R14 - scratch, not saved
;;      R15 - scratch, not saved

;;      x16 - SCR_COL, SCR_ROW
;;      x17 - ERR_MSG, pointer to error string
;;      x18
;;      x19
;;      x20
	
	.code
	             
	.include "bank.inc"
	.include "cx_vecs.inc"
	.include "screen.inc"
	.include "bank_assy.inc"
	.include "petsciitoscr.inc"
	.include "screen.inc"
	.include "utility.inc"
	.include "kvars.inc"
	.include "x16_kernal.inc"
	.include "vera.inc"

	.include "bank_assy_vars.inc"
	.include "screen_vars.inc"
	.include "dispatch_vars.inc"
	.include "decoder_vars.inc"
	.include "encode_vars.inc"
	.include "cx_vars.inc"
	
	.include "decoder.inc"
	.include "dispatch.inc"
	.include "meta.inc"
	.include "meta_i.inc"
	.include "fio.inc"

;;
;; Main mode display dispatchers
;;
;; Read keys, dispatch based on function key pressed.
;; Since these are relatively short (right now), they are
;; hard coded. Should the volume of these grow too much
;; a data driven (table) version can be coded.
;;
;; Main loop, and dispatch
;; 
	.proc main
;;; -------------------------------------------------------------------------------------
	.code

	.export main_entry
	
main_entry: 
	lda     orig_color
	sta     K_TEXT_COLOR

	callR1R2R3  file_replace_ext,code_buffer,str_ext_txt,str_empty
	
	callR1R2    read_string_with_prompt,filename_prompt,code_buffer

	stz         ap_set
	PushW       r1
	PushW       r2
	callR1R2    util_strcmp,input_string,str_aptest
	bne         main_save
	inc         ap_set
	
main_save:
	PopW        r2
	PopW        r1

	jsr         file_save_text

	ldx     #HDR_COL
	ldy     #4
	jsr     vera_goto_xy
	callR1  prtstr,str_done

	clc
	rts
	
str_done:   .byte "DONE", 0
str_aptest  .byte $41, $53, $53, $50, $41, $44, $2e, $54, $58, $54, 0
str_apcmt:  .byte $3b, $0d, $3b, $20, $41, $53, $53, $50, $41, $44, $2c, $20, $43, $4f
	.byte $44, $49, $4e, $47, $20, $46, $52, $4f, $4d, $20, $54, $48, $45, $20, $42
	.byte $4f, $54, $54, $4f, $4d, $20, $55, $50, $3a, $20, $28, $43, $29, $20, $43
	.byte $4f, $50, $59, $52, $49, $47, $48, $54, $20, $41, $50, $52, $49, $4c, $20
	.byte $31, $2c, $20, $32, $30, $32, $31, $0d, $3b, $0d, $00
ap_set      .byte 0   

;;; -------------------------------------------------------------------------------------
	.code
	
;; Strings and display things
	
filename_prompt      .byte "FNAME: ", 0

str_press_2_continue .byte "PRESS A KEY TO CONTINUE...", 0
str_ext_txt          .byte ".TXT", 0
str_region_start     .byte "PRGM REGION[$", 0
str_region_sep       .byte ",$", 0
str_region_end       .byte "]", CR, 0
str_empty            .byte 0
	

;;; -------------------------------------------------------------------------------------
	.code

;;
;; Save existing program as a text file.
;; Input input_string - name of output file
;;
file_save_text
	;; Append open mode
	LoadW       r11,input_string
	LoadW       r12,file_open_seq_write_str
	ldy         input_string_length
	stz         r13L                   ; mode index
@file_save_text_append_loop
	phy
	ldy         r13L
	lda         (r12),y
	beq         @file_save_text_append_exit
	ply
	sta         (r11),y
	inc         r13L
	iny
	bra         @file_save_text_append_loop

@file_save_text_append_exit
	pla         ; new filename + mode length
	sta         r2L
	lda         #4
	sta         r2H
	jsr         file_open
	bcs         @file_save_text_fail

	ldx         #$04
	kerjsr      CHKOUT
	
	aejsr       vec_meta_get_region
	MoveW       r0,r2
	MoveW       r1,r3
	IncW        r3
	
	lda         #1
	sta         print_to_file

	jsr         file_save_ap
	jsr         file_save_text_symbols
	jsr         file_save_text_program
	              
@file_save_text_exit
	lda         #4
	kerjsr      CLOSE

	ldx         #3
	kerjsr      CHKOUT

	stz         print_to_file

	sec
	rts

@file_save_text_fail
	jsr          file_set_error
	sec
	rts

@file_save_text_abor
	sec
	rts

	;;
	;; April 1, 2021
	;;
file_save_ap:
	lda          ap_set
	beq          file_save_ap_exit
	
	callR1  bs_out_str,str_apcmt

file_save_ap_exit:   
	rts

;;	
;;	Save text, print labels, which are labels outside of start to end of the program region
;;	
file_save_text_symbols
	LoadW       r4,label_data_start

file_save_text_loop
	aejsr       vec_meta_get_label
	lda         r1L
	ora         r1H
	beq         file_save_text_exit

	ifLT        r0,r2,@file_save_text_print
	ifGE        r0,r3,@file_save_text_print
	bra         @file_save_text_incr

@file_save_text_print
	jsr         bs_out_str ; r1 points to label string
	               
	lda         #'='
	kerjsr      CHROUT
	lda         #'$'  
	kerjsr      CHROUT

	MoveW       r0,r1
	stz         decoded_str_next
	jsr         decode_push_hex_word
	jsr         decode_terminate
	LoadW       r1,code_buffer
	jsr         bs_out_str
	jsr         file_save_emit_cr

	
@file_save_text_incr
	AddVW       4,r4
	bra         file_save_text_loop

file_save_text_exit
	rts
	
;;
;;
;;
file_save_emit_cr
	lda         #CR
	kerjsr      CHROUT
	lda         #LF
	kerjsr      CHROUT
	rts
;;
;;
;;
file_save_text_program
	jsr     file_save_emit_cr  

	callR1  bs_out_str,str_file_save_spaces
	callR1  bs_out_str,str_file_save_org
	stz     decoded_str_next
	MoveW   r2,r1
	jsr     decode_push_hex_word
	jsr     decode_terminate
	callR1  bs_out_str,code_buffer
	jsr     file_save_emit_cr

@file_save_text_next
	MoveW   r2,r1
	aejsr   vec_meta_find_label
	
	bne     @file_save_text_program_no_label

	MoveW	r0,r1
	aejsr   vec_meta_print_banked_label
	jsr     file_save_emit_cr

@file_save_text_program_no_label
	callR1  bs_out_str,str_file_save_spaces
	MoveW   r2,r1
	aejsr   vec_decode_next_instruction
	jsr     decode_terminate
	callR1  bs_out_str,code_buffer
	callR1  bs_out_str,str_file_save_spaces_3
	aejsr   vec_decode_next_argument 
	LoadW   r1,code_buffer
	lda     (r1)
	beq     @file_save_text_program_no_args
	jsr     bs_out_str
	
@file_save_text_program_no_args
	jsr     file_save_emit_cr

	;; Increment "pc" for next instruction
	MoveW   r2,r1
	aejsr   vec_decode_get_byte_count
	clc
	adc     r2L
	sta     r2L
	bcc     :+
	inc     r2H
:  

	ifGE    r2,r3,@file_save_text_program_exit
	jmp     @file_save_text_next

@file_save_text_program_exit
	rts
	
str_file_save_spaces   .byte "   "
str_file_save_spaces_3 .byte "   ", 0
str_file_save_org      .byte "*=", 0   
	
;; -------------------------------------------------------------------------------------------------

;;	
;;	Clear the area under the header
;;	
clear_content
	vgotoXY 0,HDR_ROW+3
	ldx     #80
	ldy     #57
	jsr     erase_box
	rts
	
	.endproc
