;;;
;;; BASIC bootstrap Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.import  main_entry

	.org     $801
	
	.segment "BOOTSTRAP"
	.word    *
	
basic_loader:  
	.byte $0B,$08,$01,$00,$9E,$32,$30,$36,$31,$00,$00,$00   ; Adds BASIC line:  1 SYS 2061
	
	jmp   main_entry
	
