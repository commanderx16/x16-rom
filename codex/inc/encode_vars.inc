;;;
;;; Encoder vars for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_ENCODE_VARS__
	__X16_ENCODE_VARS__=1

	.import encode_pc, encode_buffer_size, encode_dry_run, encode_buffer
	.importzp ENCODE_BUFFER_MAX
	
	.endif
