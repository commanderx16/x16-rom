;;;
;;; Additional vectors for Codex, mainly so the external plugins can access functionality
;;;
;;; Copyright 2020-2021 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.include "decoder.inc"
	.include "meta.inc"
	.include "meta_i.inc"
	
	.segment "CODEX_VECS"

	.export  vec_meta_get_region, vec_meta_get_label, vec_meta_find_label, vec_meta_expr_iter, vec_meta_print_banked_label
	.export  vec_decode_next_instruction, vec_decode_next_argument, vec_decode_get_byte_count

vec_meta_get_region:          jmp   meta_get_region
vec_meta_add_label:				jmp   meta_add_label
vec_meta_delete_label:			jmp   meta_delete_label
vec_meta_get_label:           jmp   meta_get_label
vec_meta_find_label:          jmp   meta_find_label
vec_meta_expr_iter:           jmp   meta_expr_iter_next
vec_meta_print_banked_label:  jmp   meta_print_banked_label
vec_decode_next_instruction:  jmp   decode_next_instruction
vec_decode_next_argument:     jmp   decode_next_argument
vec_decode_get_byte_count:    jmp   decode_get_byte_count

