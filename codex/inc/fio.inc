;;;
;;; Code block manipulation routines for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_FILE_IO__
	__X16_FILE_IO__=1

	.import file_open,file_open_seq_read_str,file_open_seq_write_str,file_set_error,file_replace_ext
   .import file_load_bank_a000, file_save_bank_a000

	.endif
