;;;
;;; Assembly decoder vars for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.data
	
	.export decoded_str_next, decoded_str
	
decoded_str_next .byte   0
decoded_str      .res   32,0        

