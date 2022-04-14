;;;
;;; Screen control for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020-2022 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 
 
	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.include "bank.inc"
	.include "bank_assy.inc"
	.include "bank_assy_vars.inc"
	.include "cx_vecs.inc"
	.include "decoder.inc"
	.include "decoder_vars.inc"
	.include "kvars.inc"
	.include "petsciitoscr.inc"
	.include "screen_vars.inc"
	.include "utility.inc"
	.include "vera.inc"
	.include "x16_kernal.inc"
	.include "cx_vars.inc"

	.export clear, init_screen_variables, screen_set_fg_color, read_key_with_prompt, read_string_with_prompt
	.export read_string, read_string_preloaded, draw_box, draw_box_center_lines, erase_box
	.export draw_horizontal_line, draw_vertical_line, save_vera_state, restore_vera_state, save_user_screen, restore_user_screen
	.export screen_clear_scrollback, screen_get_prev_scrollback_address, screen_add_scrollback_address
	.export prtstr, print_horizontal_line, gotoPrompt, prtxlatedcodes, prthexbytes, prthex, prtspaceto
	.export rdhex2, bs_out_str, prtstr_shim, prtstr_at_xy, print_header

	.export SCROLLBACK_COUNT
	.exportzp SCR_QUOTE, DATA_ROW, DBL_QUOTE

	.exportzp CURSOR_DN, CURSOR_UP, HDR_ROW, HDR_COL, DELETE, LAST_ROW
	.exportzp COLOR_BLACK, COLOR_WHITE, COLOR_RED, COLOR_CYAN, COLOR_VIOLET
	.exportzp COLOR_GREEN, COLOR_BLUE, COLOR_YELLOW, COLOR_ORANGE, COLOR_BROWN
	.exportzp COLOR_LT_RED, COLOR_DK_GREY, COLOR_GREY, COLOR_LT_GREEN, COLOR_LT_BLUE, COLOR_LT_GREY
	
	.exportzp COLOR_CDR_BACK_HIGHLIGHT, COLOR_CDR_TEXT_INV, COLOR_CDR_MEM
	.exportzp COLOR_CDR_ADDR, COLOR_CDR_BYTES, COLOR_CDR_INST, COLOR_CDR_ARGS, COLOR_CDR_LABEL, COLOR_CDR_ERROR

;;
;; Box drawing related routines, for 80x60 mode
;;
	;;  !zone screen

	HDR_COL=1
	HDR_ROW=1
	DATA_ROW=4

	COLOR_BLACK=0
	COLOR_WHITE=1
	COLOR_RED=2
	COLOR_CYAN=3
	COLOR_VIOLET=4
	COLOR_GREEN=5
	COLOR_BLUE=6
	COLOR_YELLOW=7
	COLOR_ORANGE=8
	COLOR_BROWN=9
	COLOR_LT_RED=10
	COLOR_DK_GREY=11
	COLOR_GREY=12
	COLOR_LT_GREEN=13
	COLOR_LT_BLUE=14
	COLOR_LT_GREY=15

	   ;; White-Black
;;      COLOR_CDR_BACK=COLOR_WHITE    | (COLOR_WHITE << 4)
;;      COLOR_CDR_TEXT=COLOR_BLACK    | (COLOR_WHITE << 4)
;;      COLOR_CDR_MEM=COLOR_GREY      | (COLOR_WHITE << 4)
;;      COLOR_CDR_ADDR=COLOR_DK_GREY  | (COLOR_WHITE << 4)
;;      COLOR_CDR_BYTES=COLOR_DK_GREY | (COLOR_WHITE << 4)
;;      COLOR_CDR_INST=COLOR_BLUE     | (COLOR_WHITE << 4)
;;      COLOR_CDR_ARGS=COLOR_BLUE     | (COLOR_WHITE << 4)

	     ;; Black-White with different args
;;      COLOR_CDR_BACK=COLOR_WHITE    | (COLOR_WHITE << 4)
;;      COLOR_CDR_TEXT=COLOR_BLACK    | (COLOR_WHITE << 4)
;;      COLOR_CDR_MEM=COLOR_GREY      | (COLOR_WHITE << 4)
;;      COLOR_CDR_ADDR=COLOR_DK_GREY  | (COLOR_WHITE << 4)
;;      COLOR_CDR_BYTES=COLOR_DK_GREY | (COLOR_WHITE << 4)
;;      COLOR_CDR_INST=COLOR_BLUE     | (COLOR_WHITE << 4)
;;      COLOR_CDR_ARGS=COLOR_LT_BLUE  | (COLOR_WHITE << 4)
;;      COLOR_CDR_LABEL=COLOR_BLACK   | (COLOR_WHITE << 4)

	     ;; Black-White with different args
;;      COLOR_CDR_BACK=COLOR_BLACK    | (COLOR_BLACK << 4)
;;      COLOR_CDR_TEXT=COLOR_WHITE    | (COLOR_BLACK << 4)
;;      COLOR_CDR_MEM=COLOR_GREY      | (COLOR_BLACK << 4)
;;      COLOR_CDR_ADDR=COLOR_DK_GREY  | (COLOR_BLACK << 4)
;;      COLOR_CDR_BYTES=COLOR_LT_GREY | (COLOR_BLACK << 4)
;;      COLOR_CDR_INST=COLOR_LT_BLUE  | (COLOR_BLACK << 4)
;;      COLOR_CDR_ARGS=COLOR_LT_BLUE  | (COLOR_BLACK << 4)

	     ;; Grey background
;;      COLOR_CDR_BACK=COLOR_LT_GREY  | (COLOR_LT_GREY << 4)
;;      COLOR_CDR_TEXT=COLOR_BLACK    | (COLOR_LT_GREY << 4)
;;      COLOR_CDR_MEM=COLOR_BLACK     | (COLOR_LT_GREY << 4)
;;      COLOR_CDR_ADDR=COLOR_DK_GREY  | (COLOR_LT_GREY << 4)
;;      COLOR_CDR_BYTES=COLOR_DK_GREY | (COLOR_LT_GREY << 4)
;;      COLOR_CDR_INST=COLOR_BLUE     | (COLOR_LT_GREY << 4)
;;      COLOR_CDR_ARGS=COLOR_BLUE     | (COLOR_LT_GREY << 4)

	     ;; Cyan background
;;      COLOR_CDR_BACK=COLOR_CYAN    | (COLOR_CYAN << 4)
;;      COLOR_CDR_TEXT=COLOR_BLACK   | (COLOR_CYAN << 4)
;;      COLOR_CDR_MEM=COLOR_GREY     | (COLOR_CYAN << 4)
;;      COLOR_CDR_ADDR=COLOR_DK_GREY | (COLOR_CYAN << 4)
;;      COLOR_CDR_BYTES=COLOR_BROWN  | (COLOR_CYAN << 4)
;;      COLOR_CDR_INST=COLOR_BLUE    | (COLOR_CYAN << 4)
;;      COLOR_CDR_ARGS=COLOR_BLUE    | (COLOR_CYAN << 4)
;;      COLOR_CDR_LABEL=COLOR_GREEN  | (COLOR_CYAN << 4)

	     ;; Blue background
	COLOR_CDR_BACK_HIGHLIGHT=        COLOR_DK_GREY
	COLOR_CDR_TEXT_INV=COLOR_ORANGE
	COLOR_CDR_MEM=COLOR_WHITE
	COLOR_CDR_ADDR=COLOR_LT_GREY
	COLOR_CDR_BYTES=COLOR_LT_GREY
	COLOR_CDR_INST=COLOR_LT_RED
	COLOR_CDR_ARGS=COLOR_LT_RED
	COLOR_CDR_LABEL=COLOR_LT_GREEN
	COLOR_CDR_ERROR=COLOR_WHITE
	
	     ;; Yellow background
;;      COLOR_CDR_BACK=COLOR_YELLOW   | (COLOR_YELLOW << 4)
;;      COLOR_CDR_TEXT=COLOR_BLACK    | (COLOR_YELLOW << 4)
;;      COLOR_CDR_MEM=COLOR_BLACK     | (COLOR_YELLOW << 4)
;;      COLOR_CDR_ADDR=COLOR_DK_GREY  | (COLOR_YELLOW << 4)
;;      COLOR_CDR_BYTES=COLOR_DK_GREY | (COLOR_YELLOW << 4)
;;      COLOR_CDR_INST=COLOR_BLUE     | (COLOR_YELLOW << 4)
;;      COLOR_CDR_ARGS=COLOR_BLUE     | (COLOR_YELLOW << 4)

	HLINE=$43
	VLINE=$5D
	UR=$6E
	LR=$7D
	UL=$70
	LL=$6D

	CURSOR_DN=$11
	CURSOR_UP=$91

	DELETE=$14
	DBL_QUOTE=$22

	SCR_QUOTE=39

;;
;; Clear the screen
;;
clear 
	stz    SCR_ROW
cl_loop
	stz    SCR_COL
	vgoto
	ldx    #80
	jsr    prtspaceto
	inc    SCR_ROW
	lda    SCR_ROW
	cmp    #60
	bne    cl_loop
	
	rts

;;
;; Init State Variables
;; Initialize the environment 
;;
init_screen_variables

	lda     K_TEXT_COLOR
	sta     orig_color

	LoadW   ERR_MSG,$0
	
	kerjsr  SCREEN
	stx     screen_width
	sty     screen_height
	tya
	sec
	sbc     #4
	sta     screen_row_prompt

	sbc     #(DATA_ROW+2)
	sta     screen_row_data_count
	
	;; figure out the last row, just above the prompt area
	tya                       ; get screen_height
	sec
	sbc     #5                ; 4 rows, and - 1 because row counting starts at zero :-)
	sta     screen_last_row

	rts

;;
;; Set the screen color
;; Input A: Screen fg color
screen_set_fg_color
	sta     r15L
	lda     orig_color
	and     #$F0
	ora     r15L
	sta     K_TEXT_COLOR
	rts
	
;;
;; Read key with prompt
;;
read_key_with_prompt
	jsr     gotoPrompt

	ldx     #49
	ldy     #3
	jsr     draw_box

	ldy     screen_row_prompt
	iny
	sty     SCR_ROW
	ldx     #HDR_COL+2
	stx     SCR_COL
	vgoto

	jsr     prtstr
	             
@read_key_with_prompt_loop
	kerjsr  GETIN
	beq     @read_key_with_prompt_loop
	             
	pha
	             
	ldy     screen_row_prompt
	sty     SCR_ROW
	ldx     #1
	stx     SCR_COL
	vgoto

	ldx     #49                     ; Last screen column
	ldy     #3
	jsr     erase_box

	pla
	rts
	             
;;
;; Print a prompt, then call read string
;; Input r1 - prompt string ptr
;;       r2 - Preload value ptr, if NULL - no preload
;;
read_string_with_prompt
	ldy     screen_row_prompt
	sty     SCR_ROW
	ldx     #1
	stx     SCR_COL
	vgoto

	ldx     #49
	ldy     #3
	jsr     draw_box

	ldy     screen_row_prompt
	iny
	sty     SCR_ROW
	ldx     #HDR_COL+2
	stx     SCR_COL
	vgoto

	jsr     prtstr               ; Print prompt string
	
	;; read_string_core needs this later
	lda     SCR_COL
	sta     r11H

	lda     r2L
	ora     r2H
	bne     read_string_with_prompt_preload
	jsr     read_string
	php

	bcc     read_string_with_continue
	plp
	rts

read_string_with_prompt_preload	             
	MoveW   r2,r1
	jsr     read_string_preloaded
	php             ; Save error / success condition

read_string_with_continue
	ldy     screen_row_prompt
	sty     SCR_ROW
	ldx     #1
	stx     SCR_COL
	vgoto

	ldx     #49
	ldy     #3
	jsr     erase_box
	plp             ; Restore error / success condition
	rts


;;	
;; Alternate entry point for read_string, does not clear the buffer.
;; Input r1 - Stored content to preload
;; 
read_string_preloaded
	PushW   r2
	LoadW   r2,input_string
	jsr     util_strcpy
	jsr     prtstr
	PopW    r2
	bra     read_string_core
	
;;
;; read_string
;; read a string from the keyboard, if the user presses "escape" the operation is terminated
;; Input - none
;; Output - String stored in input_string
;;        - r1 -> input_string
;;
;; Side Effects - A,Y,r11,r12
;;
;; Carry == 0, input_string considered valid, == 1, user pressed escaped
;;
;; r11L tracks insert position in the string
;; r11H records column at start of string
;; r12L original color
;; r13L flash color

	INPUT_LENGTH=64

read_string
	stz     input_string
	lda     SCR_COL
	sta     r11H
	
read_string_core	
	LoadW   r1,input_string

	;; r12 original color
	;; r13 flash colors
	lda     K_TEXT_COLOR
	sta     r12L
	asl
	asl
	asl
	asl
	sta     r13L
	lda     r12L
	lsr
	lsr
	lsr
	lsr
	ora     r13L
	sta     r13L

	jsr     util_strlen
	sty     input_string_length
	sty     r11L                        ;; insert point starts at beginning (e.g. append)

rdstring_in
	kerjsr  GETIN
	bne     rdstring_got_one

	IncW    input_string_cursor
	lda     input_string_cursor+1
	bit     #$40
	bne     rdstring_unflash_cursor
	
rdstring_flash_cursor
	ldx     #r13
	bra     rdstring_flash_output

rdstring_unflash_cursor
	ldx     #r12

rdstring_flash_output
	ldy     r11L
	cpy     input_string_length
	bmi     rdstring_existing_char
	lda     #' '
	bra     rdstring_output

rdstring_existing_char	
	lda     (r1),y
	
rdstring_output	
	jsr     rdstring_out
	
	bra     rdstring_in

rdstring_got_one
	jsr     rdstring_unflash ; Make sure last selected character is not highlighted.

	cmp     #CR
	beq     @rdstring_accept

	cmp     #DEL
	beq     @rdstring_del
	
	cmp     #F8
	beq     @rdstring_escape

	cmp     #KEY_STOP
	beq     @rdstring_escape

	cmp     #CUR_LEFT
	beq     @rdstring_left

	cmp     #CUR_RIGHT
	beq     @rdstring_right

	ldy     r11L
	sta     (r1),y

	ldx     #r12
	jsr     rdstring_out   

	lda     input_string_length
	cmp     r11L
	bne     @rdstring_no_incr
	
	inc     input_string_length
	
@rdstring_no_incr	
	cpy     #INPUT_LENGTH
	beq     @rdstring_accept

	inc     r11L
	bra     rdstring_in

@rdstring_del    
	lda     input_string_length
	beq     rdstring_in

	cmp     r11L
	bne     rdstring_in

	lda     #' '
	ldx     #r12
	jsr     rdstring_out
	
	dec     input_string_length
	dec     r11L

	jmp     rdstring_in

@rdstring_accept
	clc

@rdstring_exit
	;;  replace colors in case the cursor was in flash state
	lda     r12L
	lda     r12H
	
	ldy     input_string_length
	lda     #0
	sta     (r1),y
	             
	rts
	
@rdstring_escape
	stz     input_string_length
	sec     
	bra     @rdstring_exit

	;; LEFT
@rdstring_left
	lda     r11L
	beq     @rdstring_left_exit
	dec
	sta     r11L
@rdstring_left_exit
	jmp     rdstring_in

	;; RIGHT
@rdstring_right
	lda     r11L
	cmp     input_string_length
	beq     @rdstring_right_exit
	inc
	sta     r11L
@rdstring_right_exit
	jmp     rdstring_in
	
;;
;; output character from inside of read_string
;; Input A - Character
;;       X - register number for colors
;;
rdstring_out
	pha
	lda     $00,x
	sta     K_TEXT_COLOR
	
	clc
	lda     r11L
	adc     r11H
	sta     SCR_COL
	vgoto
	
	pla
	jsr     petscii_to_scr
	charOutA
	rts
	
;; 
;; rdstring_unflash
;; 
rdstring_unflash
	pha
	ldx     #r12
	ldy     r11L
	lda     (r1),y
	bne     :+
	lda     #' '
:  
	jsr     rdstring_out
	pla
	rts

;;
;; Draw a box, at the current X-Y locaton
;; Input X - Width
;;       Y - Height
;;       Carry = 1 erase content, = 0 just draw outline
;;	
;; Clobbers M1 holds width/height
;;          M2 holds SCR_COL/ROW   
;;          r11L erase flag
;;
draw_box
	pha
	
	stz     r11L
	bcc     @draw_box_no_erase
	inc     r11L

@draw_box_no_erase	
	stx     M1L                    ; Save sizes for later
	sty     M1H

	lda     SCR_COL
	sta     M2L
	lda     SCR_ROW
	sta     M2H

	txa
	tay                             ; Load width for horiz routine
	lda     #UL
	jsr     draw_horizontal_line
	charOut UR

	dec     M1H
	dec     M1H                     ; Account for top & bottom horiz lines

@draw_box_vloop
	lda     M2L
	sta     SCR_COL
	inc     SCR_ROW
	vgoto

	ldx     M1L
	jsr     draw_box_center_lines
	dec     M1H
	bne     @draw_box_vloop

	inc     SCR_ROW
	lda     M2L
	sta     SCR_COL
	vgoto  

	lda     #LL
	ldy     M1L
	jsr     draw_horizontal_line
	charOut LR
 
	pla
	rts

;;
;; Draw center lines in a box:  "| multiple spaces |"
;; Input X - Width
;;        
draw_box_center_lines
	dex             ;; Account for a vline

	lda             #VLINE
	charOutA
	lda             r11L
	beq             @draw_box_center_no_erase
	
	dex             ;; Account for the second vline
@draw_box_center_loop
	lda             #CHR_SPACE
	charOutA
	dex
	bne             @draw_box_center_loop
	bra             @draw_box_center_exit

@draw_box_center_no_erase
	dex
	txa
	clc
	adc            SCR_COL
	sta            SCR_COL
	jsr            vera_goto

@draw_box_center_exit
	lda            #VLINE
	charOutA
	     
	rts

;;
;; Erase a box at SCR_COL, SCR_ROW, with XY size
;; Input X - Width of box
;;       Y - Height of box
;;
erase_box
	txa
	beq     erase_exit
	tya
	beq     erase_exit
	     
	lda     SCR_COL
	sta     M1L
	stx     M1H

erase_box_row_loop
	ldx     M1L
	stx     SCR_COL
	ldx     M1H

	vgoto

erase_box_col_loop
	lda     #CHR_SPACE
	charOutA

	dex
	bne     erase_box_col_loop

	inc     SCR_ROW
	dey
	bne     erase_box_row_loop

erase_exit
	rts

;;
;; Print horizontal line from current position to end of line
;; Input Y - Width
;;       A - First character to print
draw_horizontal_line
	phx
	phy

	pha
	lda     K_TEXT_COLOR
	tax
	pla
	     
	sta     VERA_DATA0
	stx     VERA_DATA0

	;; increment the column so COL/ROW are correct afterwards
	tya
	dec
	clc
	adc     SCR_COL
	sta     SCR_COL
 
	dey
	dey
	lda     #HLINE

@draw_horizontal_loop
	sta     VERA_DATA0
	stx     VERA_DATA0
	dey
	bne     @draw_horizontal_loop
	
	ply
	plx
	rts

;;
;; Print vertical line from current position to down, to height
;; Input Y - Height
;;       A - First character of line
draw_vertical_line
	phx
	phy

@draw_vertical_loop
	sta     VERA_DATA0
	lda     K_TEXT_COLOR
	sta     VERA_DATA0

	phy
	inc     SCR_ROW
	ldx     SCR_COL
	ldy     SCR_ROW
	jsr     vera_goto
	ply

	lda     #VLINE

	dey
	bne     @draw_vertical_loop

	ply
	plx
	rts


;;
;; Save VERA state (to bank_assy)
;; Does not save the data registers, MUST be called with bank_assy seleced
;;
save_vera_state
	pushBankVar  bank_assy
	sec                           ; Interrogate XY
	kerjsr       PLOT
	stx          screen_save_plot_x
	sty          screen_save_plot_y

	sec                           ; interrogate mode
	kerjsr       SCRMOD
	sta          screen_save_mode

	;; set to 80 col mode for debugger
	lda          #MODE_80_60
	clc
	kerjsr       SCRMOD
	      
	popBank
	rts

;;
;; Restore VERA state (from bank_assy)
;; Does not restore the data registers
;;
restore_vera_state
	lda          screen_save_mode

	;; restore to 40 col mode
	clc
	kerjsr       SCRMOD
	      
	ldx          screen_save_plot_x
	ldy          screen_save_plot_y
	clc                           ; Set XY
	kerjsr       PLOT
	
	rts
 
;;
;; Save the user screen
;;

	LAST_COL=80*2
	LAST_ROW=60
	ROW_BANK_SWITCH=LAST_ROW/2
	save_screen=$a000

save_user_screen
	pushBankVar bank_assy

	sec       ; get mode
	kerjsr    SCRMOD
	sta       screen_save_mode

	clc
	kerjsr    PLOT
	stx       screen_save_plot_x
	sty       screen_save_plot_y
	
;	LoadW     r0,0
;	LoadW     r1,0
;	kerjsr    FB_CURSOR_POSITION

	LoadW     r1,320
	LoadW     r2,200
	LoadW     r3,save_mover

	jsr       save_restore_user_screen_iter
	
	popBank
	rts
	
	;;
	;; Iterate over all rows, calling the row mover
	;;
save_restore_user_screen_iter
	switchBankVar bank_scr1

	LoadW     r0,save_screen
	LoadW     r4,0 ; Row counter
	
@save_restore_iter_loop	
	jsr       save_restore_user_screen_row
	LoadW     TMP1,$c000
	SubW      r0,TMP1
	ifGE      TMP1,r1,@save_restore_iter_incr
	LoadW     r0,save_screen
	dec       BANK_CTRL_RAM
@save_restore_iter_incr
	IncW      r4
	ifNe16    r4,r2,@save_restore_iter_loop
	rts

	;;
	;; Save one row of screen data
	;;
save_restore_user_screen_row
	PushW     r1
@sr_user_line_loop
	lda       r1H
	beq       @sr_user_tail
	dec       r1H
	ldy       #0
@sr_user_256_loop
	jsr       mover_shim
	iny
	bne       @sr_user_256_loop
   inc       r0H
	bra       @sr_user_line_loop
@sr_user_tail
   lda       r1L
	beq       @sr_user_exit
	ldy       #0
@sr_user_tail_loop	
	jsr       mover_shim
	iny
	cpy       r1L
	bne       @sr_user_tail_loop
@sr_user_exit
	PopW      r1
	tya
	clc
	adc       r0L
	sta       r0L
	bcc       :+
	inc       r0H
:	
	rts

	;;
	;; Restore the user screen
	;;
restore_user_screen
	pushBankVar bank_assy
	lda       screen_save_mode
	clc
	kerjsr    SCRMOD

	LoadW     r0,0
	LoadW     r1,0
	kerjsr    FB_CURSOR_POSITION

	LoadW     r1,320
	LoadW     r2,200
	LoadW     r3,restore_mover

	switchBankVar bank_scr1

	jsr       save_restore_user_screen_iter
	
	popBank
	rts

	;;
	;; Movers called from the iter loop
	;;
mover_shim
	jmp       (r3)
	
save_mover
   lda       VERA_DATA0
   sta       (r0),y
   rts

restore_mover
	lda       (r0),y
	sta       VERA_DATA0
   rts

;;
;; ------------------------------------------------------------
;; Scrollback module, so an scroll backwards
;; Implemented as a stack of 16 bit values, scrollback_ptr always pointing to top of stack
;; ------------------------------------------------------------

scrollback_top_ptr      = $A000
scrollback_ptr          = $c000 - 2
scrollback_start_ptr    = scrollback_ptr ; also means an empty stack, will not write here
scrollback_low_water    = scrollback_ptr 
SCROLLBACK_COUNT        = (scrollback_low_water - scrollback_top_ptr) / 2

;;
;; Initialize the scrollback structure
;;
screen_clear_scrollback
	pushBankVar     bank_scrollback
	LoadW           scrollback_ptr,scrollback_start_ptr
	popBank
	rts

;;
;; Get the PREVIOUS address for the instruction prior to address in r1
;; Output r0 - previous address
;;        C - C == 0 valid A, C == 1 no prior info available
;;
screen_get_prev_scrollback_address
	pushBankVar    bank_scrollback

	MoveW          scrollback_ptr,TMP2
	
; Manually expanded ifGE macro, to handle immediate argument	
;	ifGE           TMP2,#scrollback_low_water,screen_fail
	
	lda				TMP2H
	cmp				#>scrollback_low_water
	bcc				:+
	bne				screen_fail
	lda				TMP2L
	cmp				#<scrollback_low_water
	bcs				screen_fail

:	
	ldy            #0
	lda            (TMP2),y
	sta            r0L
	iny
	lda            (TMP2),y
	sta            r0H
	

;	AddVW          2,TMP2
;  MoveW          TMP2,scrollback_ptr
	
	lda				TMP2
	clc
	adc				#2
	sta				scrollback_ptr
	bcc				screen_exit
	inc				scrollback_ptr+1
	
screen_exit       ; Common exit for routines
	popBank
	clc
	rts
	
screen_fail       ; Common exit routines
	popBank
	sec
	rts


;;
;; Append the scroll information to the scroll back list
;; Input r1 - Address to push
;;
screen_add_scrollback_address
	pushBankVar   bank_scrollback
	            
	MoveW          scrollback_ptr,TMP2
	
	; Manually expanded ifGE, with #immediate argument
   ; ifGE           #scrollback_top_ptr,TMP2,@screen_add_roll
	
   ifVGE          scrollback_top_ptr,TMP2,@screen_add_roll
	
	sec
	lda            TMP2L
	sbc            #2
	sta            TMP2L
   sta				scrollback_ptr
	bcs            @screen_store_address
	dec            TMP2H
   dec				scrollback_ptr+1

@screen_store_address
	ldy            #0
	lda            r1L
	sta            (TMP2),y
	iny
	lda            r1H
	sta            (TMP2),y
   bra            screen_exit
	            
@screen_add_roll
	;; push entire stack down by one entry, cutting off the oldest
	PushW          r0
	PushW          r1
	PushW          r2

	;; r0 = src
	LoadW          r0,scrollback_top_ptr
	            
	;; r1 = dst
	LoadW          r1,scrollback_top_ptr+2
	            
	;; r2 = byte_count
	LoadW          r2,(SCROLLBACK_COUNT*2 - 2)

	kerjsr         MEMCOPY

	PopW           r2
	PopW           r1
	PopW           r0
	bra            @screen_store_address

;;
;;  prtstr_at_xy
;;  Print a petcsii string at X-Y coordinates
;;  Input - r1 string to print
;;          X, Y - screen location for print	
;;
prtstr_at_xy
	jsr    vera_goto_xy
	;; Drop straight into prtstr

;;  prtstr
;;  Print petscii string
;;
;; Input - String address in zp r1
;;
prtstr
	ldy     #0
prtstr_loop
	lda     (r1),y
	beq     prtstr_exit
	cmp     #CR
	beq     @prtstr_cr
	
	jsr    petscii_to_scr
	
	charOutA

@prtstr_incr	
	iny
	bne     prtstr_loop
	inc     r1H             ; printed 256 characters, bump ptr, keep going
	bra     prtstr_loop

@prtstr_cr
	stz     SCR_COL
	inc     SCR_ROW
	jsr     vera_goto
	bra     @prtstr_incr
	
prtstr_exit
	rts

;;
;; Print a string to a file (instead of screen)
;; Input r1 - ptr to the string
;; Clobbers A, Y
;; 
bs_out_str 
	ldy         #0
:  
	lda        (r1),y
	beq        :+
	cmp        #$A4 ; Fake underscore character from CLC
	bne        @bs_out_str_doit
	lda        #'_'
@bs_out_str_doit
	kerjsr     CHROUT
	iny
	bne        :-
	inc        r1H
	bra        :-
:
	rts

;;
;;
;;
prtstr_shim
	lda        print_to_file
	bne        bs_out_str
	jmp        prtstr
	
	;; No rts since control is switched to the appropriate routine

;;
;; Print horizontal line from current position to end of line
;;
print_horizontal_line
	lda     screen_width
	sec
	sbc     SCR_COL
	bne     print_horizontal_continue
	rts

print_horizontal_continue
	tay                     ; Y = count of columns

print_horizontal_loop
	lda     #$44            ; horizontal line
	charOutA
	dey
	bne     print_horizontal_loop

	rts

;;
;; Move cursor to prompt location
;;
gotoPrompt
	lda        #HDR_COL
	sta        SCR_COL
	lda        screen_row_prompt
	sta        SCR_ROW
	vgoto
	rts


;;
; prtxlatedcodes
;; Print a series bytes, as petscii characters
;; Input r2 - address of bytes
;;        A - number of bytes
;; Clobbers - Y
;;
prtxlatedcodes
	sta     r5L
	ldy     #0
@prtxlatedcodes_lp
	lda     (r2),y                  ;; get bytes value
	sec
	sbc     #$40 ; tmp
	charOutA
	iny
	tya
	cmp     r5L
	bne     @prtxlatedcodes_lp
	rts

;;
; prthexbytes
;; Print a series of bytes
;; Input r2 - address of bytes
;;        A - number of bytes
;; Clobbers - Y
;;
prthexbytes
	sta     r5L
	ldy     #0
@prthexbytes_lp
	lda     (r2),y                  ;; get bytes value
	tax
	jsr     prthex
	charOut  CHR_SPACE
	iny
	tya
	cmp     r5L
	bne     @prthexbytes_lp
	rts

;;
;; prthex
;; Print a hex value
;; Input - X hex byte value
;; Side effects
;;

prthex
	phy
	pha        ;; Preserve accumulator
	
	lda        K_TEXT_COLOR
	tay
	          
	txa

	;; Do first digit
	lsr
	lsr
	lsr
	lsr

	jsr        prthexdigit
	txa      
	jsr        prthexdigit

	pla        ;; restore accumulator
	ply
	rts

;;	
;;	Print the hex digit in A
;;	
prthexdigit
	and        #$0f
	ora        #'0'            ; Add "0"
	cmp        #'9'+1          ; Is it a decimal digit?
	bcc        @prthexdigit_print ; Yes! output it
	sbc        #$39            ; Adjust offset to A-F
@prthexdigit_print
	charOutA
	rts
	
;;
;; prtspaceto
;; Prints space until column in X is reached
;; Input X - column to stop at
;;
prtspaceto
	pha                        ;; Save A
	phy                        ;; Save Y

	;; ColCount = ColDesired - CurCol + 1

	txa
	cmp        SCR_COL
	beq        @prtspaceto_exit ;; Done, nothing to do

	sec
	sbc        SCR_COL         ;; A < Desired - CurCol
	bmi        @prtspaceto_exit
	tay
	          
	;; Update the column tracker after this operation
	txa
	sta        SCR_COL
	   
	lda        #CHR_SPACE          ;; #$ff for debug
	ldx        orig_color          ;; COLOR_CDR_TEXT for debug

@prtspaceto_loop
	dey
	sta        VERA_DATA0
	stx        VERA_DATA0
	bne        @prtspaceto_loop

@prtspaceto_exit
	ply                        ;; Restore Y
	pla                        ;; Restore A
	rts

;;
;; rdhex2
;; Read a hex string, convert to binary, and return the binary value.
;; Input A  - Count of expected digits
;;       r1 - Prompt string
;;       r2 - Preload value ($FFFF is the 'don't use' value)
;;	
;; Output
;;       r2              - Binary value (for historical and compat reasons)
;;       input_hex_value - Binary value
;;       input_hex_bank  - A bank value, if set
;;       input_hex_set   - Zero if bank value not specified, One if the bank value is significan
;;       Z == 1 valid address, == 0 no address
;;       C == 1 error (and not vald, Z will be == 1), == 0 no error
;;
rdhex2
	;; Init input string
	stz     input_string

	;; r1 already contains the prompt
	lda     r2L
	and     r2H
	cmp     #$FF
	bne     rdhex2_read_the_string_for_preload
	LoadW   r2,0   ; No preload string address
	bra     rdhex2_read_the_string

rdhex2_read_the_string_for_preload
	;; Format the preload value for input
	stz     decoded_str_next
	LoadW   r10,code_buffer
	lda     r2H
	jsr     decode_push_hex
	lda     r2L
	jsr     decode_push_hex
	ldy     decoded_str_next
	lda     #0
	sta     (r10),y
	MoveW   r10,r2  ; preload string address

rdhex2_read_the_string
	jsr     read_string_with_prompt
	bcc     @rdhex2_continue
	jmp     rdhex_error_exit

@rdhex2_continue
	stz     input_hex_value
	stz     input_hex_value+1
	stz     input_hex_bank
	stz     input_hex_bank_set

	callR1 util_trim_string,input_string
	             
	ldy     #0
	lda     (r1),y
	beq     rdhex_error_exit
	             
rdhex_convert
	cmp     #':'
	bne     rdhex_09

	;; Bank designator

	lda     input_hex_bank_set
	ora     input_hex_value+1
	bne     rdhex_error_exit        ; if bank already set, or vallue > $ff, spec an error

	lda     input_hex_value
	sta     input_hex_bank
	inc     input_hex_bank_set
	stz     input_hex_value
	stz     input_hex_value+1

	bra     rdhex_incr

rdhex_09
	;; in A, convert to hex nibble
	cmp     #'0'
	bmi     rdhex_error_exit
	cmp     #('9'+1)
	bpl     rdhex_af
	sec
	sbc     #'0'
	jsr     rdhex_asl_value         ; preserves A
	ora     input_hex_value
	sta     input_hex_value
	
	bra     rdhex_incr

rdhex_af
	cmp     #'A'
	bmi     rdhex_error_exit
	cmp     #('F'+1)
	bpl     rdhex_error_exit
	jsr     rdhex_asl_value         ; preserves A
	sec
	sbc     #('A'-10)               ; leaves an A as 10, F as 15, carry still set from sbc!
	ora     input_hex_value
	sta     input_hex_value

rdhex_incr
	iny
	tya
	cmp     input_string_length
	bpl     rdhex_exit

	lda     (r1),y
	bra     rdhex_convert

	rts
	;; do conversion from 'A'-'F' to $A - $F

	iny
	bra     rdhex_convert                

rdhex_exit
	lda     input_hex_value
	sta     r2L
	lda     input_hex_value+1
	sta     r2H

	lda     #1                      ; clear zero flag, no error
	;; Ensure banking is only supplied for $A000 - $BFFF
	cmp     #$A0
	bmi     rdhex_exit_no_bank
	cmp     #$C0
	bpl     rdhex_exit_no_bank

	stz     input_hex_bank_set

rdhex_exit_no_bank
	lda     #1                      ; clear zero flag, no error
	clc                             ; no error
	rts

rdhex_error_exit
;                lda     #0                      ; set zero flag, not valid
	sec                             ; error
	rts

rdhex_noerror_exit
	lda     #0                      ; set zero flag, not valid
	clc                             ; no error
	rts

;;
;; Sub for rdhex, shift r2 left by 4 bits
;;
rdhex_asl_value
	pha
	;; shift r2H left by 4 bits
	lda     input_hex_value+1
	asl
	asl
	asl
	asl
	sta     input_hex_value+1

	;; get high nibble of r2L, and add to r2H
	lda     input_hex_value
	lsr
	lsr
	lsr
	lsr
	clc
	adc     input_hex_value+1
	sta     input_hex_value+1

	;; shift r2L
	lda     input_hex_value
	asl
	asl
	asl
	asl
	sta     input_hex_value

	pla
	rts

;;
;; print_header
;; Print the F1 F3, etc header, with labels
;;
print_header
	ldx     #HDR_COL
	ldy     #(HDR_ROW+1)
	jsr     prtstr_at_xy            ; r1 has sub header from caller

	ldx     #HDR_COL
	ldy     #HDR_ROW
	callR1  prtstr_at_xy,fn_header

	ldx     BANK_CTRL_RAM
	jsr     prthex

	ldx     #0
	ldy     SCR_ROW
	iny                             ; Save a byte, vera_goto will store in SCR_COL, SCR_ROW

	lda     #50
	sta     SCR_COL
	jsr     vera_goto
	callR1  prtstr,str_region_start
	jsr     vec_meta_get_region
	ldx     r0H
	jsr     prthex
	ldx     r0L
	jsr     prthex
	
	charOut ','
	charOut '$'

	ldx     r1H
	jsr     prthex
	ldx     r1L
	jsr     prthex
	
	callR1       prtstr,str_region_end

	lda     orig_color
	sta     K_TEXT_COLOR
	jsr     print_horizontal_line
	rts
	
fn_header            .byte " F1   F2   F3   F4   F5    F6    F7   F8         RAM BANK = ", 0
str_region_start     .byte "PRGM REGION[$", 0
str_region_end       .byte "]", CR, CR, 0
