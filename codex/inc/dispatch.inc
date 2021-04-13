;;;
;;; UI keypress routine dispatcher for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_DISPATCH__
	__X16_DISPATCH__=1

	.import get_and_dispatch, fn_dispatch

	.macro setDispatchTable t
	LoadW dispatch_current_table, t
	.endmacro

	.include "dispatch_vars.inc"

	.endif
