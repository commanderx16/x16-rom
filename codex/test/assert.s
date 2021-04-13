;;;
;;; Assertions for the unit test driver of the Commander 16 Assembly Environment Unit Tests
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 
	.ifndef __ASSERT__
	__ASSERT__=1

	.code
	
	.macro pass test
	   jsr     testPass
	   callR1 prtstr,test
	.endmacro

	.macro fail test
	   jsr     testFail
	   callR1 prtstr,test
	.endmacro

	.macro fatal test
	   jsr     testFatal
	   callR1 prtstr,test
	   rts
	.endmacro

	.macro assertEqA test,msg
	   ldy       #<msg
	   sty       r1L
	   ldy       #>msg
	   sty       r1H
	   ldx       #test
	   jsr       assertEqACore
	.endmacro

	.macro assertEqR0 cannon
	   lda        #<cannon
	   sta        r5L
	   lda        #>cannon
	   sta        r5H
	   jsr        assertEqR0Core
	.endmacro

	.macro assertEqR1 cannon
	   lda        #<cannon
	   sta        M1L
	   lda        #>cannon
	   sta        M1H
	   jsr        assertEqR1Core
	.endmacro

	PS_MASK_Z=$02
	PS_MASK_C=$01
	     
	.macro assertEqZ msg
	   php
	   LoadW      r1,msg
	   pla
	   and       #PS_MASK_Z
	   jsr       testBool
	.endmacro

	.macro assertNeZ msg
	   php
	   LoadW      r1,msg
	   pla
	   and       #PS_MASK_Z
	   jsr       testNotBool
	.endmacro
	     
	.macro assertCarrySet msg
	   php
	   LoadW      r1,msg
	   pla
	   and       #PS_MASK_C
	   jsr       testBool
	.endmacro

	.macro assertCarryClear msg
	   php
	   LoadW      r1,msg
	   pla
	   and       #PS_MASK_C
	   jsr       testNotBool
	.endmacro

;;
;; A pass condition
;; update counts, set text colors, etc.
;;
testPass
	PushW   r1
	IncW    passed_count
	IncW    total_count
	lda     #COLOR_CDR_PASS
	jsr     screen_set_fg_color
	ldy     #COL_TEST_INDENT
	jsr     prtindent
	callR1  prtstr,str_test_passed
	PopW    r1
	rts

;;
;; A fail condition
;; updaet counts, set text colors, etc.
;;
testFail
	PushW   r1
	IncW    failed_count
	IncW    total_count
	lda     #COLOR_CDR_FAIL
	jsr     screen_set_fg_color
	ldy     #COL_TEST_INDENT
	jsr     prtindent
	callR1  prtstr,str_test_failed
	PopW    r1
	rts

;;
;; A fatal condition
;; update counts, set text colors, etc.
;;
testFatal
	PushW   r1
	IncW    failed_count
	IncW    total_count
	lda     #COLOR_CDR_FATAL
	jsr     screen_set_fg_color
	ldy     #COL_TEST_INDENT
	jsr     prtindent
	callR1  prtstr,str_test_fatal
	PopW    r1
	rts


;;
;; Test some boolean (calculated externally)
;;
testBool
	bne       :+
	jsr       testFail
	bra       :++
:  
	jsr       testPass
:  
	jsr       prtstr
	rts


;;
;; Test some boolean (calculated externally)
;;
testNotBool
	bne       :+
	jsr       testPass
	bra       :++
:  
	jsr       testFail
:  
	jsr       prtstr
	rts


;;
;; Assert that a value is equal
;; Input A  - test value
;;       X  - Cannonical value
;;       r1 - Test description
assertEqACore
	sta     r3L
	             
	lda     r1L
	pha
	lda     r1H
	pha

	txa     
	pha
	ldy     #COL_TEST_INDENT
	jsr     prtindent
	pla

	cmp     r3L

	bne     assertEqA_fail

	IncW    passed_count
	IncW    total_count
	lda     #COLOR_CDR_PASS
	jsr     screen_set_fg_color
	callR1  prtstr,str_test_passed
	pla     
	sta     r1H
	pla     
	sta     r1L
	jsr     prtstr

	rts

assertEqA_fail
	IncW    failed_count
	IncW    total_count
	lda     #COLOR_CDR_FAIL
	jsr     screen_set_fg_color
	callR1  prtstr,str_test_failed

	pla     
	sta     r1H
	pla     
	sta     r1L
	jsr     prtstr

	ldy     #(COL_INDENT+6)
	jsr     prtindent
	             
	callR1  prtstr,str_unexpected_value
	ldx     r3L
	jsr     prthex

	inc     SCR_ROW
	stz     SCR_COL
	jsr     vera_goto
	             
	rts

;;
;; Test string equals r0 == r5 (cannonical)
;;
;;
;; assert r0 (test) pointed to same string as r5 (cannononical)
;;
assertEqR0Core
	PushW   r0
	
	ldy     #COL_TEST_INDENT
	jsr     prtindent

	;; Compare strings
	ldy     #0
assertEqR0_loop
	lda     (r0),y
	sta     r3L
	lda     (r5),y
	cmp     r3L
	bne     assertEqR0Core_failed
	ora     r3L
	beq     assertEqR0Core_passed
	iny
	bra     assertEqR0_loop
	;;

	bra     assertEqR0Core_failed

assertEqR0Core_passed
	IncW    passed_count
	IncW    total_count
	lda     #COLOR_CDR_PASS
	jsr     screen_set_fg_color
	callR1  prtstr,str_test_passed
	callR1  prtstr,str_test_matched
	bra     assertEqR0Core_exit

assertEqR0Core_failed
	IncW    failed_count
	IncW    total_count
	lda     #COLOR_CDR_FAIL
	jsr     screen_set_fg_color
	callR1  prtstr,str_test_failed
	callR1  prtstr,str_test_expected

	MoveW   r5,r1
	jsr     prtstr

	callR1  prtstr,str_test_saw

assertEqR0Core_exit
	PopW    r1

	ldy     #0
:
	lda     (r1),y
	beq     assertEqR0Core_done
	jsr     petscii_to_scr
	charOutA
	iny
	bra     :-

assertEqR0Core_done
	lda     #SCR_QUOTE
	charOutA
	             
	stz     SCR_COL
	inc     SCR_ROW
	vgoto
	rts

;;
;; Test string equals r1 == r2 (cannonical)
;;
;;
;; assert r1 (test) pointed to same string as r2 (cannononical)
;;
assertEqR1Core
	lda     r1L
	pha     
	lda     r1H
	pha

	ldy     #COL_TEST_INDENT
	jsr     prtindent

	;; Compare strings
	ldy     #0
assertEqR1_loop
	lda     (r1),y
	sta     r3L
	lda     (M1),y
	cmp     r3L
	bne     assertEqR1Core_failed
	ora     r3L
	beq     assertEqR1Core_passed
	iny
	bra     assertEqR1_loop
	;;

	bra     assertEqR1Core_failed

assertEqR1Core_passed
	IncW    passed_count
	IncW    total_count
	lda     #COLOR_CDR_PASS
	jsr     screen_set_fg_color
	callR1  prtstr,str_test_passed
	callR1  prtstr,str_test_matched
	bra     assertEqR1Core_exit

assertEqR1Core_failed
	IncW    failed_count
	IncW    total_count
	lda     #COLOR_CDR_FAIL
	jsr     screen_set_fg_color
	callR1  prtstr,str_test_failed
	callR1  prtstr,str_test_expected

	lda     M1L
	sta     r1L
	lda     M1H
	sta     r1H
	jsr     prtstr

	callR1  prtstr,str_test_saw

assertEqR1Core_exit
	pla     
	sta     r1H
	pla
	sta     r1L

	ldy     #0
:               lda     (r1),y
	beq     assertEqR1Core_done
	jsr     petscii_to_scr
	charOutA
	iny
	bra     :-

assertEqR1Core_done
	lda     #SCR_QUOTE
	charOutA
	             
	stz     SCR_COL
	inc     SCR_ROW
	vgoto
	rts


;;
;; Print the test header
;; Input r1 - Addr of test description string
;;
testHeader
	lda     r1L
	pha
	lda     r1H
	pha

	lda     orig_color
	sta     K_TEXT_COLOR

	ldy     #COL_INDENT
	jsr     prtindent
	callR1  prtstr,str_test

	pla     
	sta     r1H
	pla     
	sta     r1L
	jsr     prtstr

	rts
	             
;;
;; Prints a specific number of spaces
;; 
prtindent
	jsr        pager

prtindent_loop
	lda        #CHR_SPACE
	charOutA
	dey
	bne        prtindent_loop
	rts


passed_count       .word 0
failed_count       .word 0
total_count        .word 0
	
	.endif
