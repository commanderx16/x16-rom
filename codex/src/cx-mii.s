	;;
	;; Commander 16 CodeX Interactive Assembly Environment
	;; Meta instruction debugger tool.
	;; 
	;;    Copyright 2020 Michael J. Allison
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

	jsr     clear_content
	
	LoadW   r4,meta_i_entry_0

	ldy     #4
@expr_row
	ldx     #HDR_COL
	jsr     vera_goto_xy
	phy
	
	aejsr   vec_meta_expr_iter_next
	lda     r11H
	and     r11L
	cmp     #$FF
	beq     @expr_loop_exit

	ldx     r11H
	jsr     prthex
	ldx     r11L
	jsr     prthex

	charOut ' '

	jsr     prt_expr_enum

	ply

	;; Point to next expression entry
	clc
	lda     r4L
	adc     #META_I_RECORD_SIZE
	sta     r4L
	bcc     :+
	inc     r4H
	
:
	iny
	cpy     #ROW_MAX
	bmi     @expr_row

@expr_loop_exit	
	ply
	LoadW   r1,str_done
	jsr     wait_for_keypress

	clc
	rts
	
str_done:   .byte "PRESS ANY KEY TO CONTINUE: ", 0

;;; -------------------------------------------------------------------------------------
	.code
	
;; Strings and display things
	
	
;;
;; Print a decomposed expression enum
;;
prt_expr_enum
	charOut $28
	ldx     r12L
	jsr     prthex
	charOut $29

	charOut ' '

	lda     r12L
	and     #META_FN_MASK
	asl
	tax
	jmp     (mii_pseudo_arg_dispatch,x)
	
mii_pseudo_arg_dispatch
	.word mii_pseudo_none      ; 0
	.word mii_pseudo_hi_byte   ; 1
	.word mii_pseudo_lo_byte   ; 2
	.word mii_pseudo_byte      ; 3
	.word mii_pseudo_word      ; 4
	.word mii_pseudo_pstr      ; 5
	.word mii_pseudo_cstr      ; 6

str_unknown     .byte    "??? ", 0
str_low_byte    .byte    "#<", 0
str_high_byte   .byte    "#>", 0
str_byte        .byte    ".BYTE  ", 0
str_word        .byte    ".WORD  ", 0
str_pstr        .byte    ".PSTR  ", 0
str_cstr        .byte    ".CSTR  ", 0
	
;;	
mii_pseudo_hi_byte
	callR1   prtstr,str_high_byte
	
	ldx     r13H
	jsr     prthex
	ldx     r13L
	jsr     prthex

	rts
	
;;	
mii_pseudo_lo_byte
	callR1   prtstr,str_low_byte

	ldx     r13H
	jsr     prthex
	ldx     r13L
	jsr     prthex

	rts
	
;;	
mii_pseudo_byte
	callR1   prtstr,str_byte
	
	ldx     r13L
	jsr     prthex

	rts
	
;;	
mii_pseudo_word
	callR1   prtstr,str_word
	
	ldx     r13H
	jsr     prthex
	ldx     r13L
	jsr     prthex

	rts
	
;;	
mii_pseudo_pstr
	callR1   prtstr,str_pstr
	
	charOut $1B
	charOut '$'
	lda     (r4)
	jsr     prthex
	charOut $1D
	charOut ' '

	charOut $22
	ldy     #1
@mii_pseudo_cstr_loop
	lda     (r11),y
	beq     @mii_pseudo_cstr_exit
	jsr     petscii_to_scr
	charOutA
	iny    
	cpy     r13L
	bne     @mii_pseudo_cstr_loop                
@mii_pseudo_cstr_exit
	charOut $22

	rts
	
;;	
mii_pseudo_cstr
	callR1   prtstr,str_cstr
	
	charOut $1B
	charOut '$'
	ldx     r13H
	jsr     prthex
	ldx     r13L
	jsr     prthex
	charOut $1D
	charOut ' '

	charOut $22
	ldy     #0
@mii_pseudo_cstr_loop
	lda     (r11),y
	beq     @mii_pseudo_cstr_exit
	jsr     petscii_to_scr
	charOutA
	iny    
	bra     @mii_pseudo_cstr_loop                
@mii_pseudo_cstr_exit
	charOut $22

	rts
	
;;	
mii_pseudo_none
	callR1   prtstr,str_unknown
	
	ldx     r13H
	jsr     prthex
	ldx     r13L
	jsr     prthex

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
	vgotoXY 0,HDR_ROW+3
	ldx     #80
	ldy     #57
	jsr     erase_box
	rts
	
	.endproc
