;;;
;;; Encoder vars for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.data

	.export encode_pc, encode_buffer_size, encode_dry_run
	.exportzp ENCODE_BUFFER_MAX
	
	ENCODE_BUFFER_MAX = 32
	
encode_pc          .word  0
encode_dry_run     .byte  0
encode_buffer_size .byte  0
