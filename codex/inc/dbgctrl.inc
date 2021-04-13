;;;
;;; Control logic for debug methods, stepping, set breaks, etc.
;;; Uses the banked_variables, break_1, break_2, etc.
;;; For the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_DBGCTRL__
	__X16_DBGCTRL__=1

	.import step_apply, step_suspend, debug_get_brk_adjustment
	.import registers_save, registers_restore
	   
	.importzp JMP_INSTRUCTION, BRK_INSTRUCTION


	.endif
