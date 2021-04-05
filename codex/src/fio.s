;;;
;;; Code block manipulation routines for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

   .psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.export file_open,file_open_seq_read_str,file_open_seq_write_str,file_set_error,file_replace_ext,file_load_bank_a000

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
   rts
	
;;
;; Print error - Set error message ptr into ERR_MSG
;;
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

ERR_NONE         .byte "NO ERROR", 0
ERR_TOO_MANY     .byte "TOO MANY FILES", 0
ERR_OPEN         .byte "FILE ALREADY OPEN", 0
ERR_NOT_OPEN     .byte "FILE NOT OPEN", 0
ERR_NOT_FND      .byte "FILE NOT FOUND", 0
ERR_NOT_PRESENT  .byte "DEVICE NOT PRESENT", 0
ERR_NOT_INPUT    .byte "NOT AN INPUT FILE", 0
ERR_NOT_OUTPUT   .byte "NOT AN OUTPUT FILE", 0
ERR_MISSING_FN   .byte "MISSING FILE NAME", 0
ERR_BAD_DEV_NUM  .byte "BAD DEVICE NUMBER", 0
	
file_open_seq_read_str  .byte ",S,R", 0
file_open_seq_write_str .byte ",S,W", 0
	
	
;;
;; Replace the extension on the file (input_string) with the one pointed to r1
;; Input r1 - destination string
;;       r2 - ptr to extension string
;;       r3 - ptr to open arguments, e.g. ",s,w" or ",s,r"
;;
;; Clobbers r4L
;;
file_replace_ext
   ;; modify the string to be XXX.DBG
   ;; Find the last instance of "." and 
   ;; append .DBG
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
;;       
file_load_bank_a000
	php

	MoveW      r1,r2      ; r2 = extension ptr
	LoadW      r1,input_string
   LoadW      r3,file_open_seq_read_str
   jsr        file_replace_ext
                
	;; Rely on the preservation of r1
   lda        input_string_length
   sta        r2L
   lda        #4
   sta        r2H
   jsr        file_open
   bcs        file_load_debug_the_error

   ldx        #4
   kerjsr     CHKIN
 
	LoadW      r0,$a000
   kerjsr     BASIN ; Skip "load address" in file
   kerjsr     BASIN
	ldy        #0

@file_load_bank_a000_loop
   kerjsr     READST
   bne        @file_load_bank_a000_exit
	
   kerjsr     BASIN ; Get one byte
   sta        (r0),y
		
   iny
   cpy        #0
   bne        @file_load_bank_a000_loop
   inc        r0H
   bra        @file_load_bank_a000_loop
	
@file_load_bank_a000_exit
   lda        #4
   kerjsr     CLOSE
   ldx        #0
   kerjsr     CHKIN

	plp
   bcc        @file_load_bank_a000_final_exit

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

str_debug_incompat .byte "INCOMPATIBLE DBG INFO", 0
