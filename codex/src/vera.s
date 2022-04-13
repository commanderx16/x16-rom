;;;
;;; VERA interface for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	VERA_ADDR_LO=$9F20
	VERA_ADDR_MID=$9F21
	VERA_ADDR_HI=$9F22
	VERA_DATA0=$9F23
	VERA_DATA1=$9F24
	VERA_CTRL=$9F25
	VERA_IEN=$9F26
	VERA_ISR=$9F27
	
	VERA_CTRL_SEL=$00

	.export vera_out_a, vera_goto_xy, vera_goto, VERA_DATA0, VERA_DATA1, VERA_ADDR_LO, VERA_ADDR_MID, VERA_ADDR_HI
	
	.include "kvars.inc"
	.include "x16_kernal.inc"
	.include "screen_vars.inc"

;;
;; Vera print char
;; Input A - screen code
vera_out_a
	sta   VERA_DATA0
	lda   K_TEXT_COLOR
	sta   VERA_DATA0
	inc   SCR_COL
	rts
	         
;;
;; Vera goto (aka PLOT) via X-Y registers
;;
vera_goto_xy
	stx    SCR_COL
	sty    SCR_ROW
	jsr    vera_goto
	rts

;;
;; Vera goto (aka PLOT) via SCR_COL, SCR_ROW
;;
vera_goto
	lda    SCR_COL
	asl
	sta    VERA_ADDR_LO
	lda    SCR_ROW
	clc
	adc    #$B0
	sta    VERA_ADDR_MID
	lda    #$11
	sta    VERA_ADDR_HI
	rts
