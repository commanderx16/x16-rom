;;;
;;; Code block manipulation routines for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020-2022 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.export file_open,file_open_seq_read_str,file_open_seq_write_str,file_set_error,file_replace_ext
	.export file_load_bank_a000, file_save_bank_a000

	.include "bank.inc"
	.include "bank_assy.inc"
	.include "bank_assy_vars.inc"
	.include "meta.inc"
	.include "screen.inc"
	.include "screen_vars.inc"
	.include "x16_kernal.inc"
	.include "vera.inc"

;;
;; Open a file
;; Input r1 - File name ptr
;;       r2L - Filename length
;;       r2H - File number
;;
;; Output A - Error code from open
;;        Carry - 1 if error, 0 otherwise   
;;	
file_open
	ldx  r1L
	ldy  r1H
	lda  r2L
	kerjsr SETNAME

	lda  r2H                  ; LFN
	ldx  #$8                  ; Drive
	tay
	kerjsr  SETLFS

	kerjsr  OPEN
	bne     file_open_error
	clc
	rts

file_open_error
	lda     #4                 ; File not found
	sec
	rts
	
;;
;; Print error - Set error message ptr into ERR_MSG
;; Input - Error code
file_set_error
	asl
	tax
	lda   error_table,x
	sta   ERR_MSG
	inx
	lda   error_table,x
	sta   ERR_MSG+1
	rts


ERROR_STR
	.byte  "ERROR: ", 0

error_table
	.word ERR_NONE                ; 0
	.word ERR_TOO_MANY            ; 1
	.word ERR_OPEN                ; 2
	.word ERR_NOT_OPEN            ; 3
	.word ERR_NOT_FND             ; 4
	.word ERR_NOT_PRESENT         ; 5
	.word ERR_NOT_INPUT           ; 6
	.word ERR_NOT_OUTPUT          ; 7
	.word ERR_MISSING_FN          ; 8
	.word ERR_BAD_DEV_NUM         ; 9

ERR_NONE         .byte 0                         ; NO ERROR
ERR_TOO_MANY     .byte "TOO MANY FILES", 0
ERR_OPEN         .byte "FILE ALREADY OPEN", 0
ERR_NOT_OPEN     .byte "FILE NOT OPEN", 0
ERR_NOT_FND      .byte "FILE NOT FOUND", 0
ERR_NOT_PRESENT  .byte "DEV NOT PRESENT", 0      ; DEV NOT PRESENT
ERR_NOT_INPUT    .byte "NOT INPUT FILE", 0       ; NOT AN INPUT FILE
ERR_NOT_OUTPUT   .byte "NOT OUTPUT FILE", 0      ; NOT AN OUTPUT FILE
ERR_MISSING_FN   .byte "MISSING FNAME", 0        ; MISSING FILE NAME
ERR_BAD_DEV_NUM  .byte "BAD DEV NUMBER", 0       ; BAD DEVICE NUMBER
	
file_open_seq_read_str  .byte ",S,R", 0
file_open_seq_write_str .byte ",S,W", 0
	
	
;;
;; Replace the extension on the file (input_string) with the one pointed to r1
;; Input r1 - destination string
;;       r2 - ptr to extension string
;;       r3 - ptr to open arguments, e.g. ",s,w" or ",s,r"
;;
;; Output A - length of value in destination string
;;
;; Clobbers r4L
;;
file_replace_ext
	;; modify the string to be XXX.DBG
	;; Find the last instance of "." and 
	;; append the extension, e.g. ".DBG"
	stz        r4L

	ldy        #0

@file_replace_fix_loop
	lda        (r1),y
	beq        @file_replace_fix_append

	cmp        #'.'
	beq        @file_replace_fix_append

	iny
	bra        @file_replace_fix_loop

@file_replace_fix_append
	sty        r4L                  ;; remember the index

	lda        r2L
	ora        r2H
	beq        @file_replace_end_extension

	ldy        #0
@file_replace_fix_append_loop
	lda       (r2),y
	beq       @file_replace_end_extension
	phy
	ldy       r4L
	sta       (r1),y
	inc       r4L
	ply                             ;; index into extension
	iny
	bra       @file_replace_fix_append_loop
	
@file_replace_end_extension	
	
	;; If open arguments are pointing to zero, skip
	lda       r3L
	ora       r3H
	beq       @file_replace_ext_exit
	ldy       #0
	
@file_replace_ext_append_mode
	lda       (r3),y
	phy
	ldy       r4L
	sta       (r1),y
	inc       r4L
	ply
	iny
	cmp       #0
	bne       @file_replace_ext_append_mode
	
@file_replace_ext_mode_complete
	lda       r4L
	dec
	sta       input_string_length

@file_replace_ext_exit
	rts
	             
	

;;
;; Load data into an extended RAM bank $A000
;; Input_string - filename	
;; Input r1 - ptr to new extension
;;       C  - clear, do tag comparison, set, do NOT do tag comparison	
;;       
file_load_bank_a000
	php
	MoveW      r1,r2      ; r2 = extension ptr
	LoadW      r1,input_string
	LoadW      r3,0
	jsr        file_replace_ext
	             
	lda   #0              ; logical file number
	ldx   #8              ; device number
	ldy   #1              ; 0 == load to address in file
	kerjsr SETLFS

	ldx   #<input_string
	ldy   #>input_string
	lda   input_string_length
	kerjsr SETNAME

	lda   #0
	kerjsr LOAD
	
	bcs   file_load_debug_the_error
	jsr   file_set_error
	
	dec        BANK_CTRL_RAM ; Load incremented the RAM bank
	
	plp
	bcs	@file_load_bank_a000_final_exit

	; Check the meta tags for compatibility with current implementation
	LoadW      r0,meta_tag_version
	LoadW      r1,$A000
	ldy        #0

@file_load_bank_a000_chk_loop
	lda        (r0),y
	sta        r2L
	lda        (r1),y
	cmp        r2L
	bne        file_load_debug_bad_dbg
	iny
	cpy        #6
	bne        @file_load_bank_a000_chk_loop

@file_load_bank_a000_final_exit
	clc
	rts

file_load_debug_the_error
	jsr      file_set_error
	sec
	rts

file_load_debug_bad_dbg
	lda      #<str_debug_incompat
	sta      ERR_MSG
	lda      #>str_debug_incompat
	sta      ERR_MSG+1
	sec
	rts

str_debug_incompat .byte "INVALID DBG INFO", 0

;
; Save bank A000-BFFF, to same filename as entered for the main program, but extension is passed in via r1
; Output C == 0: Save successful, C == 1: Save failed, error code in A
;
file_save_bank_a000
	MoveW  r1,r2    ; r2 = extension string
	LoadW  r1,input_string
	LoadW  r3,0
	jsr   file_replace_ext
	
	lda   #0              ; logical file number
	ldx   #8              ; device number
	ldy   #1              ; 0 == load to address in file
	kerjsr SETLFS

	ldx   #<input_string
	ldy   #>input_string
	lda   input_string_length
	kerjsr SETNAME
	
	jsr   meta_get_region
	IncW   r1

	LoadW r0,$A000
	ldx   #$00
	ldy   #$C0
	lda   #r0
	kerjsr SAVE
	rts
