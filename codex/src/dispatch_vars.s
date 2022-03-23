;;;
;;; Dispatch module varss for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.data
	
	.export dispatch_vector, dispatch_current_table
	
dispatch_vector         .word   0
dispatch_current_table  .word   0

