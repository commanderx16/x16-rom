;;;
;;; Load address for plugin files
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.import  main_entry

	.org     $a000
	
	.segment "PLUGIN"
	.word    *
	
	jmp   main_entry
	
