;;;
;;; Interface for metadata bank for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020-2022 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.export meta_find_label, meta_delete_label, meta_relocate_labels, meta_lookup_label
	.export meta_clear_watches, meta_clear_meta_data, meta_add_label, meta_print_banked_label
	.export meta_get_region, meta_get_label, meta_tag_version

	.include "bank.inc"
	.include "bank_assy.inc"
	.include "bank_assy_vars.inc"
	.include "dbgctrl.inc"
	.include "decoder_vars.inc"
	.include "meta_i.inc"
	.include "screen.inc"
	.include "utility.inc"
	.include "x16_kernal.inc"
	
;;
;; Clear watch variables
;; 
meta_clear_watches
	pushBankVar bank_assy
	stz   watch_counter
	lda   #WATCH_NON_HIGHLIGHT
	sta   watch_highlight

	LoadW  r1,watch_start

	ldy   #WATCH_BYTE_COUNT
	lda   #0
@clear_watches_loop
	sta   (r1),y
	dey
	bpl   @clear_watches_loop

	;; Clear saved registers
	stz   brk_data_valid

	popBank
	rts

;;
;; Clear debug meta data
;; Input r1 - New region start address, assumed length 0, preserves value
;; Clobbers TMP1 & TMP2   
;;
meta_clear_meta_data
	pushBankVar bank_meta_l
	
	LoadW    TMP1,meta_data
	LoadW    TMP2,label_init_constant

	ldy     #(label_init_constant_end - label_init_constant - 1)
@clear_label_loop
	lda     (TMP2),y
	sta     (TMP1),y
	dey
	bpl     @clear_label_loop

	lda     r1L
	ora     r1H
	beq     @clear_meta_i
	             
	;; Set region values, start
	lda     r1H
	sta     r0H
	sta     meta_rgn_start+1
	sta     meta_exec_addr+1
	             
	lda     r1L
	sta     r0L
	sta     meta_rgn_start
	sta     meta_exec_addr

	DecW    r0
	lda     r0L
	sta     meta_rgn_end
	lda     r0H
	sta     meta_rgn_end+1

@clear_meta_i
	lda     bank_meta_i
	sta     BANK_CTRL_RAM
	LoadW   TMP1,inst_init_constant
	LoadW   TMP2,$a000
	ldy     #(inst_init_constant_end - inst_init_constant)
@clear_meta_i_loop
	lda     (TMP1),y
	sta     (TMP2),y
	dey
	bpl     @clear_meta_i_loop
@clear_exit
	popBank

	rts

;;
;; Return meta_rgn_start, meta_rgn_end in r0, r1
;;
meta_get_region
	pushBankVar   bank_meta_l
	MoveW         meta_rgn_start,r0
	MoveW         meta_rgn_end,r1
	popBank
	rts
	
;;
;; Find a label
;; Input  - r1 == value being searched for
;; Output - Z  == 0 Not found
;;        - Z  == 1 Found, r1 is valid
;;        - r0 ptr to label string
;; Clobbers - M1, y
;;
meta_find_label
	pushBankVar bank_meta_l
	PushW	r1
	jsr     meta_find_label_entry
	bne     :+
	ldy     #2
	lda     (M1),y
	sta     r0L
	iny
	lda     (M1),y
	sta     r0H

	PopW	r1
	jmp     meta_success
:  
	PopW	r1
	jmp     meta_error

;;
;; Find a label record
;; Input  - r1 == value being searched for
;; Output - Z  == 0 Not found
;;        - Z  == 1 Found, r1 is valid
;;        - M1 ptr to label entry
;; Clobbers - A, Y
;;
meta_find_label_entry
	LoadW   M1,label_data_start

@find_label_entry_loop
	;; Check for end of list
	ldy     #0
	lda     (M1),y
	iny
	ora     (M1),y
	iny
	ora     (M1),y
	iny
	ora     (M1),y
	bne     @find_label_entry_test

	lda     #FAIL
	rts

@find_label_entry_test
	;; Test this entry
	ldy     #0
	lda     (M1),y
	cmp     r1L
	bne     @find_label_entry_incr
	iny
	lda     (M1),y
	cmp     r1H
	bne     @find_label_entry_incr

	;; found it. Output in M1

	lda     #SUCCESS
	rts

@find_label_entry_incr
	lda     #4
	clc
	adc     M1L
	sta     M1L
	bcc     @find_label_entry_loop
	inc     M1H
	jmp     @find_label_entry_loop

;;	
;;	Get a label pointed to by r4
;; Output - r0 ptr to label string
;;        - r1 label value
;;	
meta_get_label
	pushBankVar bank_meta_l
	ldy         #0      
	lda         (r4),y
	sta         r0L
	iny
	lda         (r4),y
	sta         r0H
	iny
	
	lda         (r4),y
	sta         r1L  
	iny
	lda         (r4),y
	sta         r1H
	ora         r1L
	beq         @meta_get_label_exit

	PushW       r2
	LoadW       r2,code_buffer
	jsr         util_strcpy
	PopW        r2
	
	LoadW       r1,code_buffer
	
@meta_get_label_exit
	popBank
	rts
	
;;
;; print_banked_label
;; Print the label, pointed to by r1, in bank_meta_l
;;
meta_print_banked_label
	pushBankVar bank_meta_l
	jsr         prtstr_shim
	popBank
	rts

;;
;; Add a label
;; Input r1 - Ptr to string name of label
;;       r2 - Value (addr, etc) of label
;; Output Z == 1 - Added successfully
;;        Z == 0 - Failed
;;
meta_add_label
	pushBankVar bank_meta_l
	PushW  r2
	PushW  r1
	PushW  r1       ; Will use it in find step 2
	
	;; Do two label existance checks
	;; 1) Look for same value
	;; 2) Look for same string

	MoveW  r2,r1
	jsr  meta_find_label
	bne  @meta_add_label_find2
	jmp  @meta_add_label_exists_error

@meta_add_label_find2
	PopW  r1        ; Here is the second step, using the extra push
	jsr  meta_lookup_label
	bne  @meta_add_label_not_found
	jmp  @meta_add_label_exists_error
	
@meta_add_label_not_found
	;; Scan the table looking for the insert point
	LoadW   M1,label_data_start

@meta_add_scan
	ldy    #2
	lda    (M1),y
	iny
	ora    (M1),y
	bne    @meta_add_scan_chk2
	
	;; Pre terminate
	lda    #0
	iny
	sta    (M1),y
	iny
	sta    (M1),y
	iny
	sta    (M1),y
	iny
	sta    (M1),y
	jmp    @meta_add_do_insert

@meta_add_scan_chk2
	;; If next value is > new value, add here
	ldy    #1
	lda    (M1),y
	cmp    r2H
	bcc    @meta_add_scan_incr
	bne    @meta_add_do_push
	lda    (M1)
	cmp    r2L
	bcs    @meta_add_do_push

@meta_add_scan_incr
	lda    #4
	clc
	adc    M1L
	sta    M1L
	bcc    :+
	inc    M1H
:  
	bra    @meta_add_scan

@meta_add_do_push
	;; Found insert point, move the table down to make room, one slot worth
	MoveW  M1,r0               ; r0 == src

	lda    M1H
	sta    r1H
	lda    #4
	clc
	adc    M1L
	sta    r1L
	bcc    :+
	inc    r1H                ; r1 == target
:  

	;; byte count to move = end_address (M2) - insert_address (M1)
	sec
	lda    label_end_addr
	sbc    M1L
	sta    r2L
	lda    label_end_addr+1
	sbc    M1H
	sta    r2H                ; r2 == size

	;; Add 4 so guard bytes are copied
	clc
	lda    #4
	adc    r2L
	sta    r2L
	bcc    :+
	inc    r2H
:  
	kerjsr MEMCOPY

@meta_add_do_insert
	;; M1 pointing to insert pt, push list down to make room
	PopW  r1
	PopW  r2
	             
	;;
	jsr  meta_insert_record

	jsr  meta_append_string_to_heap
	ldy  #2
	lda  r2L
	sta  (M1),y
	iny
	lda  r2H
	sta  (M1),y

	MoveW  r2,meta_str_addr
	             
	lda    #1
	jsr    set_dirty
	jmp    meta_success

@meta_add_label_exists_error
	pla              ; Discard saved r1, r1, & r2
	pla
	pla
	pla
	pla
	pla
	             
	popBank

	LoadW  ERR_MSG,str_error_exists
	lda   #FAIL
	rts
	               
;;
;; Insert a new value, return ptr to new record.
;; Input r2  - Value to store
;; Output M1 - Ptr to record
;;
meta_insert_record
	lda   r2L
	sta   (M1)
	ldy   #1
	lda   r2H
	sta   (M1),y

	clc
	inc   label_count
	bcc   :+
	inc   label_count+1
:  
	clc
	lda    #4
	adc    label_end_addr
	sta    label_end_addr
	bcc    :+
	inc    label_end_addr+1
:  
	rts

;;
;; Delete a label value. This is done in several steps:
;;
;; 1) Delete old record
;; 2) Compact string heap
;; 3) Patch string pointers
;;
;; Input r1 - Address of label to delete
;; Output Z = 1 - Found and deleted
;;        Z = 0 - Not found, no deletion
;;
meta_delete_label
	pushBankVar bank_meta_l
	jsr     meta_find_label_entry
	beq     @meta_delete_found

	jmp     meta_error

@meta_delete_found
	;; Step 0 - stash old string pointer
	ldy     #2
	lda     (M1),y
	sta     M2L
	iny
	lda     (M1),y
	sta     M2H

	;; Step 1 - remove old record
	;; dst = M1 @ record to delete
	lda     M1L
	sta     r1L
	lda     M1H
	sta     r1H                        ; r1 == dst
	
	;; src = M1 + 4
	sta     r0H
	clc
	lda     #4
	adc     M1L
	sta     r0L
	bcc     :+
	inc     r0H                        ; r0 == src
:  
	
	;; byte count = end_addr - dst (includes guard bytes)
	lda     label_end_addr
	sec
	sbc     r1L
	sta     r2L
	lda     label_end_addr+1
	sbc     r1H
	sta     r2H                        ; r2 == size

	kerjsr MEMCOPY

	DecW   label_count

	;; Step 2 - compactify the string heap
	;; figure out string length for old string
	ldy      #0
@meta_delete_label_scan
	lda      (M2),y
	beq      @meta_delete_label_compactify
	iny
	bra      @meta_delete_label_scan
	             
@meta_delete_label_compactify
	lda       meta_str_addr              ; SRC addr, also preload r2 for the next step
	sta       r1L
	sta       r0L
	lda       meta_str_addr+1
	sta       r1H
	sta       r0H                         ; r0 == source, r1 == dst

	tya                                   ; DST addr = SRC + strlen(old_string) + 1
	inc
	sta       r4L                         ; Stash (strlen+1) for later use
	clc
	adc       r1L
	sta       r1L
	sta       meta_str_addr
	bcc       :+
	inc       r1H
:  
	lda       r1H
	sta       meta_str_addr+1

	lda       M2L                         ; Byte_count = old_str_addr - SRC
	sec
	sbc       r0L
	sta       r2L
	lda       M2H
	sbc       r0H
	sta       r2H                         ; r2 == size

	kerjsr    MEMCOPY

	;; Step 3 - patch string pointers
	;; any pointers less than DST need to be moved by strlen
	;; M2 == old_string address
	;; For all entries
	;;   if string address <= old_string_address
	;;       string_address = string_address + (strlen+1)
	LoadW     r1,label_data_start
	             
@meta_delete_label_patch_loop
	ldy       #2                          ; Check string ptr, if it's NULL, list is done
	lda       (r1),y
	iny
	ora       (r1),y
	beq       @meta_delete_label_patch_exit

	lda       (r1),y                      ; Not NULL, if str_ptr > old_ptr, skip to next (no need to adjust)
	sta       TMP1H
	dey
	lda       (r1),y
	sta       TMP1L
	             
	ifLT      M2,TMP1,@meta_delete_label_patch_incr

@meta_delete_label_patch_update
	;; Update the entry
	ldy       #2                          ; in case the compare skipped the DEY
	lda       (r1),y
	clc
	adc       r4L
	sta       (r1),y
	bcc       @meta_delete_label_patch_incr
	iny
	lda       (r1),y
	inc
	sta       (r1),y

@meta_delete_label_patch_incr
	;; point to next entry
	lda       #4
	clc
	adc       r1L
	sta       r1L
	bcc       :+
	inc       r1H
:  
	bra       @meta_delete_label_patch_loop

@meta_delete_label_patch_exit
	lda    #1
	jsr    set_dirty
	jmp     meta_success
	             
;;
;; Put a string in the heap
;; Input r1 - Ptr to string to copy
;;
;; Output   r1 - ptr to heaped string
;; Clobbers r3, A, Y
;;
;; NB: Can't use KERNAL MEMCOPY here, sometimes this routine is copying from CodeX rom,
;;     and MEMCOPY doesn't know how to do that.
;;   
meta_append_string_to_heap
	jsr    util_strlen
	sty    r15L
	stx    r15H
	IncW   r15           ; Account for terminating NUL
	
	;; r1 = meta_str_addr (top of heap) - string size
	sec
	lda    meta_str_addr
	sbc    r15L
	sta    r2L
	lda    meta_str_addr+1
	sbc    r15H
	sta    r2H

	jsr    util_strcpy
	rts
	
inst_init_constant
	.byte   "CDF04",0
	.word   $a00d           ;; initial count
	.word   $FFFF           ;; addr end tag
	.byte   META_FN_NONE    ;; FN end tag
	.word   $FFFF           ;; value end tag
inst_init_constant_end
	
label_init_constant
	.byte   "CDF04",0       ;; Tag
	.word   $8000           ;; Region start
	.word   $8000           ;; Region end
	.word   $8000           ;; exec address
	.word   $c000           ;; top of strings
	.word   0               ;; Label counts
	.word   $a012           ;; Initial end of label data
	.word   0               ;; End of data flags
	.word   0               ;; End of data flags
label_init_constant_end

meta_tag_version
	.byte   "CDF04",0
	             
str_error_exists
	.byte   "LABEL EXISTS", 0

;;
;; Relocate labels, during insert or delete
;; Input r1   - code insert/delete point
;;       r2   - 16 bit signed offset
;;
;; Register Usage
;;       TMP1 - pointer to label entries
;;       TMP2 - label value
;;       M1   - region end
;;
meta_relocate_labels
	PushW   r1
	phx

	;; Loop over all entries, if entry is > relocation point, push value down, store back
@meta_relocate_start
	pushBankVar   bank_meta_l
	LoadW     TMP1,label_data_start

	MoveW   meta_rgn_end,M1
	IncW    M1

@meta_relocate_loop
	ldy      #0
	lda      (TMP1),y
	sta      TMP2L
	iny
	lda      (TMP1),y
	sta      TMP2H
	            
	ifLT    TMP2,r1,@meta_relocate_incr
	ifGE    TMP2,M1,@meta_relocate_incr

	;; label value is in range, adjust it, then re-save it
	ldy      #0
	clc
	lda      TMP2L
	adc      r2L
	sta      (TMP1),y
	iny
	lda      TMP2H
	adc      r2H
	sta      (TMP1),y

	;; Increment to next entry
@meta_relocate_incr
	ldy      #0
	lda      (TMP1),y
	iny
	ora      (TMP1),y
	iny
	ora      (TMP1),y
	iny
	ora      (TMP1),y
	beq      @meta_relocate_loop_exit
	
	lda      TMP1L
	clc
	adc      #4
	sta      TMP1L
	bcc      @meta_relocate_loop
	inc      TMP1H
	bra      @meta_relocate_loop
	            
@meta_relocate_loop_exit
	popBank

	;; done
	plx
	PopW    r1
	rts

;;
;; Look up a label value based on string
;; Input r1 - String pointer
;; Output r1 - label value
;;        Z = 0 - Not found
;;        Z = 1 - Found, r1 is valid
meta_lookup_label
	pushBankVar   bank_meta_l
	LoadW     TMP1,label_data_start

@lookup_loop
	ldy      #0
	lda      (TMP1),y
	iny
	ora      (TMP1),y
	iny
	ora      (TMP1),y
	iny
	ora      (TMP1),y
	beq      meta_error
	dey
	            
	PushW    r2
	lda      (TMP1),y
	sta      r2L
	iny
	lda      (TMP1),y
	sta      r2H
	jsr      util_strcmp
	beq      @lookup_found
	PopW     r2

	;; Point to next entry
	lda      #4
	clc
	adc      TMP1L
	sta      TMP1L
	bcc      :+
	inc      TMP1H
:  
	bra      @lookup_loop
	            
@lookup_found
	PopW     r2
	ldy      #0
	lda      (TMP1),y
	sta      r1L
	iny
	lda      (TMP1),y
	sta      r1H
	            
meta_success
	popBank
	lda   #SUCCESS
	clc
	rts
	            
meta_error
	popBank
	lda   #FAIL
	sec
	rts

