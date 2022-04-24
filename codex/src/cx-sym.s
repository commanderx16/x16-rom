	;;
	;; Commander 16 CodeX Interactive Assembly Environment
	;; Symbol debugger tool.
	;; 
	;;    Copyright 2020-2021 Michael J. Allison
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
;;      R10 - decoded_str
	
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

ROW_COUNT = LAST_ROW - DATA_ROW - 4
COL_1 = 1
COL_2 = 30
	
;;
;; Main mode display dispatchers
;;
;; 
	.proc main
;;; -------------------------------------------------------------------------------------
	.code

	.export main_entry
	
main_entry: 
	setDispatchTable view_symbol_dispatch_table
	lda     orig_color
	sta     K_TEXT_COLOR

;	callR1   print_header,view_symbol_header

	jsr     clear_content

	LoadW   r1,label_data_start
	jsr     view_symbols_set_page
	
view_symbols_page_loop	
	callR1   print_header,view_symbol_header
	
	MoveW   current_page_col1,r4
	
	jsr     view_symbol_page
	jsr     get_and_dispatch
	bcs     view_symbols_exit
	
	cmp     #CUR_RIGHT
	bne     vs_loop1
	jsr     view_symbols_right
	bra     view_symbols_page_loop
	
vs_loop1:	
	cmp     #CUR_LEFT
	bne     vs_loop2
	jsr     view_symbols_left
	bra     view_symbols_page_loop
	
vs_loop2:	
	cmp     #CUR_DN
	bne     vs_loop3
	jsr     view_symbols_down
	bra     view_symbols_page_loop
	
vs_loop3:	
	cmp     #CUR_UP
	bne     vs_loop4
	jsr     view_symbols_up
	
vs_loop4:	
	bra     view_symbols_page_loop

view_symbols_exit
	jsr     clear_content

	sec
	rts
	
;;
;;
;;
view_symbols_set_page:
	MoveW   r1,current_page_col1
	
	LoadW   r0,(ROW_COUNT * 4)
	AddW    r0,r1
	MoveW   r1,current_page_col2
	
	LoadW   r3,4
	SubW    r3,r1
	MoveW   r1,current_end_of_col1
	
	AddW    r0,r1
	MoveW   r1,current_end_of_col2

	rts

;;
;;
;;
view_symbols_up:
	MoveW    selected_label,r1
	lda      r1L
	sec
	sbc      #4
	sta      r1L
	bcs      :+
	dec      r1H
:
	jsr      view_symbols_set_selected
	
	MoveW    current_page_col1,r0
	ifGE     r1,r0,vs_up_exit
	
	LoadW    r2,(ROW_COUNT *2 * 4)
	SubW     r2,r0
	MoveW    r0,r1

	jsr      view_symbols_set_page
	jsr      clear_content
	MoveW    current_end_of_col2,r1
	MoveW    current_page_col2,r3
	ifGE     r1,r3,vs_up_is_col2

	lda      #COL_1
	sta      selected_col
	rts
		
vs_up_is_col2:
	lda      #COL_2
	sta      selected_col

vs_up_exit:	
	rts
	
;;
;;
;;
view_symbols_down:
	MoveW    selected_label,r0
	ifEq16   r0,global_end,view_symbols_down_exit

	lda      r0L
	clc
	adc      #4
	sta      r0L
	bcc      :+
	inc      r0H
:
	MoveW    r0,r1
	jsr      view_symbols_set_selected

	MoveW    current_end_of_col2,r1
	ifGE     r1,r0,view_symbols_down_exit
	MoveW    current_end_of_col2,r1
	LoadW    r2,4
	AddW     r2,r1
	lda      #COL_1
	sta      selected_col
	jsr      view_symbols_set_page
	jsr      clear_content

view_symbols_down_exit:	
	rts
	
;;
;;
;;
view_symbols_right:
	lda      selected_col
	cmp      #COL_2
	beq      vs_right_exit

	lda      #COL_2
	sta      selected_col

	MoveW    selected_label,r0
	lda      r0L
	clc
	adc      #(ROW_COUNT * 4)
	sta      r0L
	bcc      :+
	inc      r0H
:
	MoveW    r0,selected_label
vs_right_exit:	
	rts
	
;;
;;
;;
view_symbols_left:
	lda      selected_col
	cmp      #COL_1
	beq      vs_left_exit

	lda      #COL_1
	sta      selected_col

	MoveW    selected_label,r0
	lda      r0L
	sec
	sbc      #(ROW_COUNT * 4)
	sta      r0L
	bcs      :+
	dec      r0H
:
	MoveW    r0,selected_label
vs_left_exit:	
	rts
	
;;
;; Set the selected entry, but limit it to min/max entries
;; Input R1 - candidate entry
;;	
view_symbols_set_selected:
	PushW  r0
	LoadW  r0,label_data_start
	ifGE   r1,r0,vs_set_value
	LoadW  r1,label_data_start
	
vs_set_value:	
	MoveW  r1,selected_label
	
	PopW   r0
	rts

;;	
;;	View a single page of data
;;	
view_symbol_page
	lda     #1
	sta     r13H
	lda     #DATA_ROW
	sta     r13L

:
	lda     r13L
	
	cmp     #(LAST_ROW-4) 
	bne     view_symbols_continue

	MoveW   current_page_col2,r1

	lda     r13H
	cmp     #COL_2
	beq     view_symbol_page_exit
	
	lda     #COL_2
	sta     r13H
	lda     #DATA_ROW
	sta     r13L
	bra     view_symbols_continue

view_symbol_page_exit:	
   ; column may be done is done, return
	clc
	rts
	
view_symbols_continue
	sta     SCR_ROW
	lda     r13H
	sta     SCR_COL
	jsr     vera_goto
	
	jsr     view_symbol_prt_line
	bcs     view_symbols_page_exit
	
	inc     r13L

	bra     :-

view_symbols_page_exit
	LoadW   r0,4
	SubW    r0,r4
	MoveW   r4,global_end
	sec
	rts
	
;;
;; Print the next symbol to the screen
;; Input R4 - ptr to next entry	
;;
view_symbol_prt_line
	ifNe16  r4,selected_label,view_symbol_no_highlight
	lda     #((COLOR_CDR_BACK_HIGHLIGHT << 4) | COLOR_YELLOW)
	sta     K_TEXT_COLOR
	bra     view_symbol_set_color

view_symbol_no_highlight
	lda     orig_color
view_symbol_set_color	
	sta     K_TEXT_COLOR

	jsr     vec_meta_get_label
	
	lda     r0L
	ora     r0H
	ora     r1L
	ora     r1H
	beq     view_symbol_prt_line_done

	PushW   r1             ; save string for later
	
	;; value
	ldx     r0H
	jsr     prthex
	ldx     r0L
	jsr     prthex

	;; spacer
	lda     #' '
	jsr     vera_out_a
	lda     #' '
	jsr     vera_out_a
	
	PopW    r1              ; restore string ptr to r1 (instead of original r0)
	jsr     prtstr
	
	;; point to next
	lda     #4
	clc
	adc     r4L
	sta     r4L
	bcc     :+
	inc     r4H
	
:
	clc
	rts

view_symbol_prt_line_done
	sec
	rts

;;
;; Create a new symbol value
;;
view_symbol_new
	stz        input_string
	callR1R2   read_string_with_prompt,str_define_prompt,0
view_symbol_add_parse
	lda        #' '
	jsr        util_split_string     ; R1 still set to point to input_string
	PushW      r1
	MoveW      r2,r1
	jsr        util_trim_string
	lda		  (r1)
	cmp		  #'$'
	bne		  @asm_define_parse_error
	IncW		  r1
	jsr        util_parse_hex
   bcs        @asm_define_parse_error
	MoveW      r1,r2
	PopW       r1
	jsr        vec_meta_add_label
	bcc        @asm_define_normal_exit
@asm_define_can_not_add
	LoadW      ERR_MSG,str_can_not_add
	rts

@asm_define_parse_error
	PopW       r1
	LoadW      ERR_MSG,str_bad_address
	rts

@asm_define_normal_exit
	clc
	rts
	
;;
;; Delete the selected symbol
;;
view_symbol_delete
	MoveW    selected_label,r4
	jsr      vec_meta_get_label
	MoveW    r0,r1
	jsr      vec_meta_delete_label
	clc
	rts
	
;;
;; Edit the selected symbol
;;
view_symbol_edit
	MoveW    selected_label,r4
	jsr      vec_meta_get_label
	PushW    r0                        ; save value for lookup during replace edit

	; r1 already set up from "get_label"
	LoadW    r2,code_buffer
	jsr      util_strcpy
	
	callR1R2 read_string_with_prompt,str_define_prompt,code_buffer
	bcs      view_symbol_edit_abort
	MoveW    r0,r1
	jsr      vec_meta_delete_label      ; Get rid of old definitions
	PopW     r1                         ; Restore value for the new definition
	MoveW    r1,r2
	LoadW    r1,input_string
	jsr      vec_meta_add_label
:
	clc
	rts

view_symbol_edit_abort
	PopW     r0
	clc
	rts
	
;;
;; Wait for a key press
;;
wait_for_keypress
	ldx      #HDR_COL
	ldy      #58
	lda      r1L
	ora      r1H
	beq      :+
	jsr      prtstr_at_xy
:  
	kerjsr   GETIN
	beq      wait_for_keypress
	rts
;;	
;;	Clear the area under the header
;;	
clear_content
	lda     orig_color
	sta     K_TEXT_COLOR

	vgotoXY 0,HDR_ROW+3
	ldx     #80
	ldy     #57
	jsr     erase_box
	rts
	
	;; Constants
	
str_done:			 .byte "PRESS ANY KEY TO CONTINUE: ", 0
str_done_exit:		 .byte "PRESS ANY KEY TO EXIT: ", 0
str_can_not_add    .byte "CAN'T ADD", 0
str_define_prompt  .byte "DEFINE: ", 0	
str_bad_address    .byte "BAD VALUE", 0
	
view_symbol_header .byte " NEW  DEL  EDIT                       BACK", 0

view_symbol_dispatch_table                
	.word   view_symbol_new    ; F1
	.word   view_symbol_edit   ; F3
	.word   0                  ; F5
	.word   0                  ; F7
	.word   view_symbol_delete ; F2
	.word   0                  ; F4
	.word   0                  ; F6

	;; Variables

selected_label:	   .word label_data_start
selected_col:	      .byte COL_1
current_page_col1:   .word 0
current_end_of_col1:	.word 0
current_page_col2:	.word 0
current_end_of_col2:	.word 0
global_end:				.word $ffff

	.endproc
