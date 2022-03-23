;;;
;;; Label meta data for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_META_L__
	__X16_META_L__=1

	.import meta_find_label, meta_delete_label, meta_relocate_labels, meta_find_label, meta_lookup_label
	.import meta_clear_watches, meta_clear_meta_data, meta_add_label, meta_print_banked_label
	.import meta_get_region, meta_get_label, meta_tag_version
	
	.endif
