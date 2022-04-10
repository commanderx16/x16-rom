;;;
;;; Codex vectors, for use by plugins.
;;;
;;; Copyright 2020-2021 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __CX_VECTORS__
	__CX_VECTORS__=1

vec_meta_get_region         = $FAE2
vec_meta_add_label          = $FAE5
vec_meta_delete_label       = $FAE8
vec_meta_get_label          = $FAEB
vec_meta_find_label         = $FAEE
vec_meta_expr_iter_next     = $FAF1
vec_meta_print_banked_label = $FAF4
vec_decode_next_instruction = $FAF7
vec_decode_next_argument    = $FAFA
vec_decode_get_byte_count   = $FAFD   

	.endif
