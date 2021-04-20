;;;
;;; $A000 definitions for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.feature labels_without_colons
;;
;; NO ACTUAL .word, .byte, etc. It's all just address calculations
;;

;;
;; Banked variables.
;; Code must switch bank prior to acess
;;
	
	;; Watches look like
	;;   !byte 0 ; type
	;;   !byte 1 ; bank
	;;   !word 1 ; address

	;; Enumerations of watch types
	WATCH_EMPTY = 0
	WATCH_BYTE  = 1
	WATCH_WORD  = 2
	WATCH_CSTR  = 3
	WATCH_PSTR  = 4

	WATCH_ENTRY_SIZE  = 4
	WATCH_ENTRY_COUNT = $10
	WATCH_BYTE_COUNT  = WATCH_ENTRY_COUNT * WATCH_ENTRY_SIZE ; 25 watches @ 4 bytes each
	WATCH_NON_HIGHLIGHT=$fc   ; Make it = 0 - size(watch)


	.if WATCH_BYTE_COUNT > 255
	.warning "Watch variables too big, fix display_watches"
	.endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;; Enumerations and constants
	.exportzp WATCH_EMPTY, WATCH_BYTE, WATCH_WORD, WATCH_CSTR, WATCH_PSTR
	.exportzp WATCH_ENTRY_SIZE, WATCH_ENTRY_COUNT, WATCH_BYTE_COUNT, WATCH_NON_HIGHLIGHT
	
	;; bank_assy
	.export orig_file_name
	.export watch_counter, watch_highlight, watch_start
	.export watch_guard
	.export old_brk_vector, brk_data_valid, brk_bank, brk_data_psr
	.export brk_data_pc, brk_data_a, brk_data_x, brk_data_y, brk_data_sp
	.export brk_data_la, brk_data_fa, brk_data_sa
	.export step_1_bank, step_1_addr, step_1_byte
	.export step_2_bank, step_2_addr, step_2_addr, step_2_byte
	.export vera_save_addr_hi, vera_save_addr_mid, vera_save_addr_lo
	.export vera_save_ctrl, vera_save_ien, vera_save_isr
	.export screen_save_plot_x, screen_save_plot_y, screen_save_mode
	.export reg_save, reg_save_end, tmp_string_stash, tmp_string_end
	.export assy_dirty

	;; bank_meta_l
	.export meta_tag, meta_rgn_start, meta_rgn_end, meta_exec_addr, meta_str_addr
	.export label_count, label_end_addr, label_data_start

	;; bank_meta_i
	.export meta_i_tag, meta_i_last, meta_i_entry_0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.segment "CODEX_STATE"
	
	.org $A000
	
orig_file_name    .res 64
	
watch_counter     .res 1
watch_highlight   .res 1
watch_start       .repeat WATCH_ENTRY_COUNT
	               .res WATCH_ENTRY_SIZE
	               .endrep
	
watch_guard       .res 2   
	
old_brk_vector    .res 2
brk_data_valid    .res 1	
brk_bank          .res 1
brk_data_psr      .res 1	
brk_data_pc       .res 2	
brk_data_a        .res 1
brk_data_x        .res 1
brk_data_y        .res 1
brk_data_sp       .res 1
brk_data_la       .res 1
brk_data_fa       .res 1
brk_data_sa       .res 1
	
step_1_bank       .res 1	
step_1_addr       .res 2	
step_1_byte       .res 1	
	
step_2_bank       .res 1	
step_2_addr       .res 2	
step_2_byte       .res 1	
	                             
vera_save_addr_hi  .res 1
vera_save_addr_mid .res 1
vera_save_addr_lo  .res 1
vera_save_ctrl     .res 1
vera_save_ien      .res 1
vera_save_isr      .res 1

screen_save_plot_x .res 1
screen_save_plot_y .res 1
screen_save_mode   .res 1

reg_save           .res 30
reg_save_end

tmp_string_stash   .res 64
tmp_string_end     .res 1

assy_dirty         .res 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;; Meta data as stored in a memory bank (bank_meta_l)
	.segment "META_L"
	
	.org $A000
meta_tag           .res 6
meta_rgn_start     .res 2
meta_rgn_end       .res 2
meta_exec_addr     .res 2
meta_str_addr      .res 2

label_count        .res 2
label_end_addr     .res 2
label_data_start   .res 2
	             
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;; Meta expressions for individual instructions in (bank_meta_i)
fg                  .segment "META_I"
	
	                .org $a000
meta_i_tag         .res 6
meta_i_last        .res 2
meta_i_entry_0     .res 2

	;; end of metadata
	
