;;;
;;; UI keypress routine dispatcher for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.export get_and_dispatch, fn_dispatch

	.include "dispatch_vars.inc"
	.include "x16_kernal.inc"

;;
;; Dispatch to user routines based on F1-F8 keys.
;; Never dispatches from F9
;;

;;
;; Get an input character from the keyboard, then dispatch
;;
get_and_dispatch
	kerjsr  GETIN
	beq     get_and_dispatch
	                     
	LoadW   ERR_MSG,0

	jsr     fn_dispatch
	rts

;;
;; Dispatch to method based on contents of A
;; F1 - F8. Will not dispatch if outside the 
;; range OR the table entry is $0000
fn_dispatch
	cmp     #F8
	bne     :+
	sec
	rts
:  
	cmp     #F1
	bmi     fn_exit
	cmp     #F9
	bmi     fn_dispatch_valid
fn_exit
	clc
	rts

	     ; In range, convert to offset
fn_dispatch_valid
	sec
	sbc     #F1
	asl
	tax

	LoadW   r1,dispatch_current_table

	ldy     #0
	lda     (r1),y
	sta     M1L
	iny
	lda     (r1),y
	sta     M1H

	txa
	tay
	lda     (M1),y
	sta     dispatch_vector

	iny
	lda     (M1),y
	sta     dispatch_vector+1

	ora     dispatch_vector
	beq     :+                              ; Null check, don't jump through $0000

	jmp     (dispatch_vector)

	;; Only here if the table contained NULL
:  
	txa                                     ; Restore the test character, in case the caller 
	lsr
	clc                                     ; wants to do something else.
	adc     #F1

	rts
