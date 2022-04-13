;;;
;;; Utility routines for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.include "x16_kernal.inc"
	
	.export util_trim_string, util_strcpy, util_strcmp, util_parse_hex
	.export util_ends_with, util_split_string, util_str_contains, util_strlen
	
;;
;; Trim string - Remove leading and trailing whitespace
;; Input r1 - String
;; Output r1 - trimmed string
;;
util_trim_string
	;; start at beginning

	ldy     #0
@util_trim_loop1
	lda     (r1),y
	beq     @util_trim_update_head
	cmp     #(' '+1)
	bpl     @util_trim_update_head
	iny
	bra     @util_trim_loop1

@util_trim_update_head
	clc
	tya
	adc     r1L
	sta     r1L
	bcc     :+
	inc     r1H
:  

	;; trim to the end
	;; find the end, then back up
	      
	ldy     #$ff                    ; Start at beginning of partial trimmed string
@util_trim_loop2
	iny     
	lda     (r1),y
	bne     @util_trim_loop2

	;; end, found, work backward
@util_trim_loop3
	lda     (r1),y
	cmp     #(' '+1)
	bpl     @util_trim_update_tail
	dey
	tya
	cmp     #$ff
	bne     @util_trim_loop3

@util_trim_update_tail
	iny
	lda      #0
	sta      (r1),y
	rts


;;
;; Copy a string from r1 to r2
;;
util_strcpy
	ldy   #$ff
@strcpy_loop
	iny
	lda   (r1),y
	sta   (r2),y
	bne   @strcpy_loop

	rts

;;
;; Compare a string
;; Input r1 - str1
;;       r2 - str2
;; Return Z = 1 - means strings matched (eq)
;; Return Z = 0 - means strings did not match (not eq)
;; If not eq, A == 1 for r1 > r2
;;            A == $ff r1 < r2
;;
util_strcmp
	ldy   #0

@util_strcmp_check
	lda   (r1),y
	ora   (r2),y
	beq   @util_strcmp_exit       ; Hit end of both strings
	      
	lda   (r1),y                  ; Hit end of r1, means r2 is greater
	beq   @util_strcmp_exit_greater

	lda   (r2),y
	beq   @util_strcmp_exit_less
	      
	lda   (r1),y
	cmp   (r2),y
	bmi   @util_strcmp_exit_less
	bne   @util_strcmp_exit_greater

	iny
	bne   @util_strcmp_check

@util_strcmp_exit
	lda   #SUCCESS                      ; Z = 1, found means matched
	rts

@util_strcmp_exit_less
	lda   #FAIL
	rts
	      
@util_strcmp_exit_greater
	lda   #$ff
	rts

;;
;; Get string length of string @ r1
;; Input
;; r1 - Pointer to string
;; Output
;; X/Y - Length of string
;;
util_strlen
	ldy   #0
	ldx   #0
@util_strlen_loop
	lda   (r1),y
	beq   @util_strlen_exit
	iny
	bne   @util_strlen_loop
	ldy   #0
	inx
	inc   r1H
	bra   @util_strlen_loop
	
@util_strlen_exit
	rts
	
;;
;; Convert string to hex, assumes a trimmed string
;;
;; Global routine for unit test access
;;
;; Input  r1 - Points to hex string (up to 4 characters)
;; Output r1 - binary value
;;
util_parse_hex
	stz      TMP1L
	stz      TMP1H

	ldy      #0

	lda     (r1)
	beq     @util_parse_hex_error_exit
	
@util_parse_loop
	lda     (r1),y
	beq     @util_parse_hex_exit

@util_parse_hex_09
	;; in A, convert to hex nibble
	cmp     #'0'
	bmi     @util_parse_hex_error_exit
	cmp     #('9'+1)
	bpl     @util_parse_hex_af
	sec
	sbc     #'0'
	jsr     @util_parse_hex_asl_TMP1         ; preserves A

	bra     @util_parse_hex_add

@util_parse_hex_af
	cmp     #'A'
	bmi     @util_parse_hex_error_exit
	cmp     #('F'+1)
	bpl     @util_parse_hex_error_exit
	jsr     @util_parse_hex_asl_TMP1         ; preserves A
	sec
	sbc     #('A'-10)                      ; leaves an A as 10, F as 15, carry still set from sbc!

@util_parse_hex_add
	ora     TMP1L
	sta     TMP1L

@util_parse_hex_incr
	iny
	tya
	cmp     #5
	bpl     @util_parse_hex_error_exit
	      
	bra     @util_parse_loop

@util_parse_hex_exit
	MoveW    TMP1,r1
	clc
	rts

@util_parse_hex_error_exit
	sec
	rts

;;
;; ASL TMP1, utility for util_parse_hex
;;
@util_parse_hex_asl_TMP1
	;; Make 1 nibble space in high byte
	asl      TMP1H
	asl      TMP1H
	asl      TMP1H
	asl      TMP1H

	;; Get nibble to be incorporated into M1H
	pha
	lda      TMP1L
	and      #$f0
	lsr
	lsr
	lsr
	lsr
	ora      TMP1H
	sta      TMP1H
	pla

	;; Shift low order byte
	asl      TMP1L
	asl      TMP1L
	asl      TMP1L
	asl      TMP1L
	rts

;;
;; Test a string to see if it has a matching suffix.
;; Do not call with a suffix longer than the test string, results undefined.
;;   e.g. "test" ends_with "testing" would be undefined
;;
;; Input r1 - pointer to test string
;; Input r2 - pointer to the suffix template
;; Output Z = 1 - The string does end with the template
;;        Z = 0 - The string does NOT end with the template
;;        A - Length of r1 (side effect, but it's useful)
;; Tmp use  TMP1  - used to store some index values in compare loop
;;          TMP2  - used to store some index values in compare loop
;;
util_ends_with
	;; prescan to find length of suffix
	ldy       #$ff
@util_ends_scan_loop
	iny
	lda       (r2),y
	bne       @util_ends_scan_loop

	tya
	sta       TMP2H           ; Save length

	ldy       #$ff
@util_ends_scan_loop2
	iny
	lda       (r1),y
	bne       @util_ends_scan_loop2

	tya
	sta       TMP1H           ; Save length
	sta       TMP1L           ; Save length for return

@util_ends_scan_test_loop
	ldy       TMP2H
	lda       (r2),y
	sta       TMP2L

	ldy       TMP1H
	lda       (r1),y
	cmp       TMP2L
	bne       @util_ends_scan_error

	dec       TMP1H
	dec       TMP2H
	bpl       @util_ends_scan_test_loop

@util_ends_scan_done
	lda       TMP1L           ; Return length
	cmp       TMP1L           ; Indicate success, set Z = 1
	rts

@util_ends_scan_error
	lda       #1            ; Inidicate failure
	rts

;;
;; Split a string into two parts, used by instruction encoder. The string
;; parts are delimited by the first instance of a character specified in A.
;; This split takes place in situ for the original string.
;; This routine assumes that the input string was trimmed.
;;
;; This method is global for access by unit test driver
;;
;; Input  r1 - Original string
;;         A - character to split on
;; Output r1 - First part of string
;;        r2 - Second part of string
;;
util_split_string
	sta   TMP1L

	ldy   #$ff
@util_split_loop
	iny   
	lda   (r1),y
	beq   @util_split_string_not_found ; Leave r2 pointing at NUL to indicate no second string
	cmp   TMP1L
	bne   @util_split_loop

	;; put a NUL at the split
	lda   #0
	sta   (r1),y

@util_split_string_done
	iny
@util_split_string_not_found
	MoveW   r1,r2
	tya
	clc
	adc      r2L
	sta      r2L
	bcc      :+
	inc      r2H
:  
	rts

;;
;; string contains - string contains a character
;; Input X  - character to check for
;;       r1 - test string
;; Output Z = 1 the string did contain the character
;;        Z = 0 the string did NOT contain the character
;;
util_str_contains
	stx   TMP1L
	ldy   #0

@util_str_contains_loop
	lda   (r1),y
	beq   @util_str_contains_not
	cmp   TMP1L
	beq   @util_str_contains_exit
	iny
	bra   @util_str_contains_loop
	      
@util_str_contains_exit
	lda   #0
	rts

@util_str_contains_not
	lda   #1
	rts

