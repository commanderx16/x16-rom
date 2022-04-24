;;;
;;; RAM bank control for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_BANK__
	        __X16_BANK__=1

	.importzp BANK_CTRL_ROM, BANK_CTRL_RAM
	.import bank_initialize, bank_pop, bank_push, set_dirty

	.macro pushBankVar b
	lda      b
	jsr      bank_push
	.endmacro

	.macro pushBankX
	txa
	jsr      bank_push
	.endmacro

	.macro switchBankVar b
	lda      b
	sta      BANK_CTRL_RAM
	.endmacro

	.macro popBank
	jsr   bank_pop
	.endmacro

	.endif
