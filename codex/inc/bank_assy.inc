;;;
;;; $A000 definitions for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __BANK_ASSY__
	__BANK_ASSY__=1
	
	
										  ; Enumerations and constants
	.importzp WATCH_EMPTY, WATCH_BYTE, WATCH_WORD, WATCH_CSTR, WATCH_PSTR
	.importzp WATCH_ENTRY_SIZE, WATCH_ENTRY_COUNT, WATCH_BYTE_COUNT, WATCH_NON_HIGHLIGHT
	
										  ; bank_assy                  
	.import orig_file_name
	.import watch_counter, watch_highlight, watch_start
	.import watch_guard
	.import old_brk_vector, brk_data_valid, brk_bank, brk_data_psr
	.import brk_data_pc, brk_data_a, brk_data_x, brk_data_y, brk_data_sp
	.import step_1_bank, step_1_addr, step_1_byte
	step_var_start = step_1_bank
	step_var_end   = step_2_byte
	
	.import step_2_bank, step_2_addr, step_2_addr, step_2_byte
	
	.import vera_save_addr_hi, vera_save_addr_mid, vera_save_addr_lo
	.import vera_save_ctrl, vera_save_ien, vera_save_isr
	.import screen_save_plot_x, screen_save_plot_y, screen_save_mode
	.import reg_save, reg_save_end, tmp_string_stash, tmp_string_end
	.import assy_dirty
	
	meta_data = meta_tag
	
										  ; bank_meta_l
	.import meta_tag, meta_rgn_start, meta_rgn_end, meta_exec_addr, meta_str_addr
	.import label_count, label_end_addr, label_data_start
	label_meta_data = label_count;
	
										  ; bank_meta_i
	.import meta_i_tag, meta_i_last, meta_i_entry_0
	
	.endif
	
