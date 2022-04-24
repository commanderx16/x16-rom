;;;
;;; $A000 definitionsVariables for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020-2021 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __BANK_CX_ASSY__
	__BANK_CX_ASSY__=1

	.import assy_selected_instruction, assy_last_disp_instruction, assy_selected_row, original_sp
	.import mem_last_addr, mem_last_bank, input_hex_bank_set, input_hex_bank, input_hex_value, run_break_shim
	
	.endif
	
