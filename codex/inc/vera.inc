;;;
;;; VERA interface for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_VERA__
	__X16_VERAL__=1

	.import vera_out_a, vera_goto_xy, vera_goto, VERA_DATA0, VERA_DATA1, VERA_ADDR_LO, VERA_ADDR_MID, VERA_ADDR_HI

	;;
	;; Output character
	;; Clobbers A,Y
	.macro charOut c 
	lda     #c
	jsr     vera_out_a
	.endmacro

	;;
	;; Inline characer writer (from accumulator)
	;; Clobbers A,Y
	;;
	.macro charOutA
	jsr    vera_out_a
	.endmacro
	
	.macro vgotoXY col, row
	ldx    #col
	ldy    #row
	jsr    vera_goto_xy
	.endmacro
	
	.macro vgoto
	jsr    vera_goto
	.endmacro
	
	.endif
	
