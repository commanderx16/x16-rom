;;;
;;; Code block manipulation routines for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020-2022 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.export edit_insert, edit_delete

	.include "bank.inc"
	.include "bank_assy.inc"
	.include "bank_assy_vars.inc"
	.include "decoder.inc"
	.include "meta.inc"
	.include "meta_i.inc"
	.include "x16_kernal.inc"

;;
;; Insert a number of bytes into the existing code region, expanding the region
;; Assumes that r1 is in the current region.
;; Input r1 - Insert location
;;        X - number of bytes to insert
;;
;; Register Usage
;;       r2 - 16 bit signed offset
;;
edit_insert
	phx
	PushW      r1

	;; Create 16 sit signed offset for edit_relocate
	stx        r2L
	stz        r2H
	         
	jsr        meta_relocate_labels      ; Rely on preserving X
	jsr        edit_relocate             ; Rely on preserving X
	         
	                                                                                
@meta_apply_expression
	pushBankVar   bank_meta_l
 
	lda        meta_rgn_end
	sec
	sbc        r1L
	sta        r2L
	lda        meta_rgn_end+1
	sbc        r1H
	sta        r2H
	IncW       r2                        ; r2 = (end - start + 1), Block Size
	         
	;; Increment region end by the byte count
	txa
	clc
	adc      meta_rgn_end
	sta      meta_rgn_end
	bcc      :+
	inc      meta_rgn_end+1
:  
	;; push the bytes (in the block) down by X
	MoveW      r1,r0                     ; r0 = SRC
	txa
	clc
	adc        r1L                       ; r1 = dst
	sta        r1L
	bcc        :+
	inc        r1H
:  
	popBank
	         
	kerjsr     MEMCOPY

	;; Do this last, since it might alter in memory code.
	PopW       r1
	pla                                  ; restore byte offset
	sta        r2L
	stz        r2H
	jsr        meta_relocate_expr
	         
	rts
	         
;;
;; Delete a number of bytes from the existing code region, shrinking the region
;; Assumes that r1 is in the current region.
;; Input r1 - Delete location
;;        X - number of bytes to delete
;;
;; Register Usage
;;       r2 - 16 bit signed offset
;;
edit_delete
	PushW      r1
	phx   
	jsr        meta_delete_label                ; Delete any labels at this location
	plx  
	PopW       r1                               ; Discard results of delete
	             
	;; Create 16 bit negative offset for edit_relocate
	txa
	sta        r2L
	lda        #0
	sec
	sbc        r2L
	sta        r2L
	lda        #$ff
	sta        r2H

	jsr      meta_relocate_labels          ; Rely on preserving X
	jsr      edit_relocate                 ; Rely on preserving X
	jsr      meta_delete_expr              ; Rely upon preservation of X
	
	stx      r7L                           ; Will be needed later on for region_end adjustment
	         
	PushW    r2
	pushBankVar   bank_meta_l

	;; remove the indicated bytes, r1 already pointing at destination
	stx      r3L
	         
	lda      r1H                           ; r1 = dst,
	sta      r0H
	lda      r1L
	clc
	adc      r3L
	sta      r0L
	bcc      :+
	inc      r0H                           ; r0 = src = dst + size
:  
	lda      meta_rgn_end
	clc												; size needs +1, e.g. size = end - start + 1
	sbc      r1L
	sta      r2L
	lda      meta_rgn_end+1
	sbc      r1H
	sta      r2H                           ; r2 = size

;	IncW     r2 - accomplished by the clc before the first sbc in the most recent block of code
	         
	popBank
	kerjsr   MEMCOPY
	PopW     r2                            ; Put r1 into r2

	;; Relocate expressions
	jsr        meta_relocate_expr

	pushBankVar bank_meta_l
	         
	;; Decrement region end by the byte count
	lda      meta_rgn_end
	sec
	sbc      r7L
	sta      meta_rgn_end
	bcs      :+
	dec      meta_rgn_end+1
:  
	popBank
	         
	rts

;;
;; Input r1 - edit location
;;       r2 - 16 bit signed offset
;;        A - Number of bytes to edit (signed), positive for insert, negative for delete
;; Preserves X
;; Register usage
;;                r3 - Copy of insert point for .edit_relocate_addr_16
;;                r4 - Instruction pointer to scan
;;                r5 - End of region
;;
edit_relocate
	phx

	pushBankVar    bank_meta_l
	lda            meta_rgn_start
	sta            r4L
	lda            meta_rgn_start+1
	sta            r4H

	lda            meta_rgn_end
	sta            r5L
	lda            meta_rgn_end+1
	sta            r5H

	MoveW          r1,r3
	PushW          r1

edit_relocate_loop
	ifGE           r4,r5,edit_relocate_exit
	         
	MoveW          r4,r1
	
	PushW          r1
	switchBankVar  bank_meta_i
	jsr            meta_find_expr
	bne            @edit_relocate_no_meta
	; Check this location for data pseudo instructions
	ldy            #2
	lda            (r1),y
	and            #META_FN_MASK
	cmp            #META_DATA_BYTE
	bmi            @edit_relocate_no_meta
	switchBankVar  bank_meta_l                            ; Effectively skip over the pseudo statement, just increment the instruction ptr
	PopW           r1
	bra            edit_relocate_check2
@edit_relocate_no_meta
	switchBankVar  bank_meta_l
	PopW           r1

@edit_relocate_check_inst
	lda            (r4)
	jsr            decode_get_entry
	ldy            #1
	lda            (M1),y
	and            #MODE_MASK
	cmp            #MODE_BRANCH
	bne            @edit_relocate_check
	jsr            edit_relocate_branch
	bra            edit_relocate_check2

@edit_relocate_check
	cmp            #MODE_ABS
	bmi            edit_relocate_check2
	cmp            #(MODE_ABS_X_IND+1)
	bpl            edit_relocate_check2

	jsr            edit_relocate_addr_16

edit_relocate_check2
	;; Point to next instruction
	lda            (r4)
	jsr            decode_get_byte_count   ; Will get the byte count for pseudo instructions as well
	         
	clc
	adc            r4L
	sta            r4L
	bcc            :+
	inc            r4H
:  
	bra            edit_relocate_loop

edit_relocate_exit
	PopW           r1
	popBank
	plx
	rts


;;
;; Relocate a 16 bit address
;; Input r2 - 16 bit signed offset
;;       r3 - Insert point
;;       r4 - Ptr to current instruction
;;       r5 - Region end
;; Clobbers r1
edit_relocate_addr_16
	ldy            #1
	lda            (r4),y
	sta            TMP1L
	iny
	lda            (r4),y
	sta            TMP1H

	ifLT           TMP1,r3,@edit_relocate_addr_16_skip
	ifLT           r5,TMP1,@edit_relocate_addr_16_skip

	dey
	lda            r2L
	clc
	adc            TMP1L
	sta            (r4),y
	iny
	lda            r2H
	adc            TMP1H
	sta            (r4),y
	         
@edit_relocate_addr_16_skip
	rts
	         
;;
;; Relocate a relative offset
;; Input r2 - 16 bit signed offset
;;       r3 - Insert point
;;       r4 - Ptr to current instruction
;; Clobbers TMP1
;;
;; Register definitions for this method

	TRGT=TMP1
	INSTPTR=r4
	INSERT=r3
	         
edit_relocate_branch
	ldy            #1
	lda            (INSTPTR),y
	sta            TMP1L
	bit            #$80
	beq            @edit_relocate_zero_extend
	lda            #$ff
	sta            TMP1H
	bra            @edit_relocate_add

@edit_relocate_zero_extend
	stz            TMP1H

@edit_relocate_add
	lda            TMP1L
	clc
	adc            r4L
	sta            TMP1L
	lda            TMP1H
	adc            r4H
	sta            TMP1H
	         
	;; Add byte count for branch, TMP1 == branch target
	clc
	lda            TMP1L
	adc            #2
	sta            TMP1L
	bcc            :+
	inc            TMP1H
:  
	;; Process backwards banches different than forward branches
	lda            (INSTPTR),y
	bit            #$80
	beq            @edit_relocate_forward

@edit_relocate_backward
	;;
	;; if (trgt >= insert) || (insert > instptr) skip
	;;
	ifGE           TRGT,INSERT,@edit_relocate_branch_skip
	ifLT           INSTPTR,INSERT,@edit_relocate_branch_skip
	lda            (r4),y
	sec
	sbc            r2L
	sta            (r4),y
	rts
	         
@edit_relocate_forward
	;;
	;; if (instptr >= insert) || (insert > trgt) skip
	;;
	ifGE           INSTPTR,INSERT,@edit_relocate_branch_skip
	ifLT           TRGT,INSERT,@edit_relocate_branch_skip
	lda            (r4),y
	clc
	adc            r2L
	sta            (r4),y
	rts

@edit_relocate_branch_skip
	rts
	

