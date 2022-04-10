;;;
;;; Vaiables for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020-2021 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.export assy_selected_instruction, assy_last_disp_instruction, assy_selected_row, original_sp
	.export mem_last_addr, mem_last_bank, input_hex_bank_set, input_hex_bank, input_hex_value, run_break_shim
	
	.data
 
assy_selected_instruction  .word 0
assy_last_disp_instruction .word 0   ; So cursor down can know when to scroll
assy_selected_row          .byte 0

original_sp                .byte 0
	
mem_last_addr              .word 0
mem_last_bank              .byte 0
input_hex_bank_set         .byte 0
input_hex_bank             .byte 0
input_hex_value            .word 0

SHIM_BUFFER_SIZE .set 22

	;; Shim code for running user program, needed to switch ROM bank prior to run.
	;; Also contains BRK shim, again to switch ROM banks. This space can not be used
	;; for anything else during user program executions.
run_break_shim:	         .res SHIM_BUFFER_SIZE

