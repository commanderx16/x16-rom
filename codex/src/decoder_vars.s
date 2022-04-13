;;;
;;; Assembly decoder vars for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.data
	
	.export decoded_str_next, code_buffer
	
decoded_str_next .byte   0
	
	;; code_buffer is shared between the encoder and decoder
	;; Since both operate at different times, there should be no conflict
code_buffer      .res   32,0        

