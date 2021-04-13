;;;
;;; Instruction meta data for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_META_I__
	__X16_META_I__=1

	.importzp META_FN_NONE, META_FN_HI_BYTE, META_FN_LO_BYTE
	.importzp META_DATA_BYTE, META_DATA_WORD, META_DATA_PSTR, META_DATA_CSTR

	.importzp META_FN_ADDR_MASK, META_FN_DATA_MASK, META_FN_MASK, META_I_RECORD_SIZE

	.import meta_delete_expr, meta_relocate_expr, meta_save_expr, meta_find_expr, meta_expr_iter_next

	.endif
