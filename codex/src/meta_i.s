;;;
;;; Instruction meta data for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020-2022 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons

	.exportzp META_FN_NONE, META_FN_HI_BYTE, META_FN_LO_BYTE
	.exportzp META_DATA_BYTE, META_DATA_WORD, META_DATA_PSTR, META_DATA_CSTR
	
	.exportzp META_FN_ADDR_MASK, META_FN_DATA_MASK, META_FN_MASK, META_I_RECORD_SIZE
	
	.export meta_delete_expr, meta_relocate_expr, meta_save_expr, meta_find_expr, meta_expr_iter_next

	.include "bank.inc"
	.include "bank_assy.inc"
	.include "bank_assy_vars.inc"
	.include "x16_kernal.inc"
	
	;; !zone meta_instruction
	
	META_FN_NONE    = 0
	META_FN_HI_BYTE = 1
	META_FN_LO_BYTE = 2

	; Data level meta, so data segments show properly
	META_DATA_BYTE  = 3
	META_DATA_WORD  = 4
	META_DATA_PSTR  = 5
	META_DATA_CSTR  = 6

	META_FN_ADDR_MASK  = $80               ; bit 7 means it's an address
	META_FN_DATA_MASK  = $40               ; bit 6 means that this is a data statement expression
	META_FN_MASK       = $3f               ; bits 5-0 are significant for the META enumeration
	META_I_RECORD_SIZE = 5

;;
;; Save a meta expression. if META_FN == NONE or > LAST, does nothing.
;; Input  X - Meta FN value
;;       r1 - Value
;;       r2 - Address
;;
meta_save_expr
	txa
	and      #META_FN_MASK
;	cmp      #META_FN_NONE						; because NONE==0, no need for compare.
	bne      @meta_save_check2
	rts

@meta_save_check2
	lda      r2L
	and      r2H
	cmp      #$ff
	bne      @meta_save_work
	rts

@meta_save_work
	pushBankVar   bank_meta_i
	phx
	PushW    r1
	PushW    r2
	      
	MoveW    r2,r1
	jsr      meta_find_expr
	php
	MoveW    r1,r0
	plp
	beq      meta_save_write
	      
meta_save_insert
	;; r1 points to insert point

	;; Calc size of post insert region -> r3
	lda    meta_i_last
	sec
	sbc    r1L
	sta    r2L
	lda    meta_i_last+1
	sbc    r1H
	sta    r2H                 ; r2 == size

	;; Source address
	MoveW   r1,r0              ; r0 == src
	      
	;; Destination is insert + RECORD_SIZE
	clc
	lda     r1L
	adc     #META_I_RECORD_SIZE
	sta     r1L
	bcc     :+
	inc     r1H                ; r1 == src
:  

	PushW   r0
	kerjsr  MEMCOPY
	PopW    r0
	      
	;; Update "last" ptr
	clc
	lda     meta_i_last
	adc     #META_I_RECORD_SIZE
	sta     meta_i_last
	bcc     :+
	inc     meta_i_last+1
:  

meta_save_write
	;; Write the expression over an old one, or in the new spot just created
	PopW    r2
	PopW    r1
	plx
	      
	ldy   #0
	lda   r2L
	sta   (r0),y
	iny
	lda   r2H
	sta   (r0),y
	iny
	      
	txa
	sta   (r0),y
	iny

	lda   r1L
	sta   (r0),y
	iny
	lda   r1H
	sta   (r0),y

	popBank
	      
@meta_save_exit
	rts

;;
;; meta_expr_iter
;; Input r4 - Pointer to next expre
;; Output r11  - Address of expression
;;        r12L - Expression enum
;;        r13  - Expression value
;;	
meta_expr_iter_next
	pushBankVar    bank_meta_i
	
	ldy           #0
	
	lda           (r4),y
	sta           r11L
	iny
	lda           (r4),y
	sta           r11H
	iny

	lda           (r4),y
	sta           r12L
	iny

	lda           (r4),y
	sta           r13L
	iny
	lda           (r4),y
	sta           r13H

	popBank
	rts
	
;;
;; Find a meta expression.
;; Input  r1 - Address for searching
;; Output r1 - Pointer to expression if found, or expression at the insert point if not found.
;; Clobbers TMP1
;; Output Z = 1 means found, Z = 0 means not found
;;
;; This routine does a stupid linear search. It should be implemented
;; using a cursor to speed up searches during assembly display.
;;
meta_find_expr
	PushW          M1
	pushBankVar    bank_meta_i
	LoadW          M1,meta_i_entry_0
@meta_find_expr_loop
	ldy            #0
	lda            (M1),y
	sta            TMP1L
	iny
	lda            (M1),y
	sta            TMP1H

	cmp            r1H
	bne            :+
	lda            TMP1L
	cmp            r1L
	bne            :+
	bra            @meta_find_expr_exit

:  
	ifGE           TMP1,r1,@meta_find_expr_fail

	;; Skip to next expression
	lda            M1L
	clc
	adc            #META_I_RECORD_SIZE
	sta            M1L
	bcc            :+
	inc            M1H

:  
	bra            @meta_find_expr_loop

@meta_find_expr_exit
	popBank
	MoveW          M1,r1
	PopW           M1
	lda            #0                      ; indicate found
	rts

@meta_find_expr_fail
	popBank
	MoveW          M1,r1
	PopW           M1
	lda            #1                      ; indicate not found
	rts

;;
;; Relocate all meta expression, for address values.
;; Input  r1 - insert point
;;        r2 - offset, 16 bit signed offset
;; Clobbers r3, r4
;; Output Z = 1 means found, Z = 0 means not found
;;
;; This routine does a stupid linear search. It should be implemented
;; using a cursor to speed up searches during assembly display.
;;
meta_relocate_expr
	pushBankVar    bank_meta_l
	MoveW          meta_rgn_end,r3
	      
	switchBankVar  bank_meta_i
	LoadW          r4,meta_i_entry_0
@meta_reloc_expr_loop
	ldy            #0

	lda            (r4),y
	cmp            #$ff
	bne            @meta_reloc_check
	iny
	lda            (r4),y
	cmp            #$ff
	beq            @meta_reloc_expr_exit

@meta_reloc_check
	ldy            #0
	jsr            @meta_reloc_expr_addr      ; Adjust the expression address
	      
	ldy            #2 
	lda            (r4),y
	and            #META_FN_ADDR_MASK
	beq            @meta_reloc_next

	iny
	jsr            @meta_reloc_expr_addr      ; Adjust the target address

@meta_reloc_apply
	jsr            @meta_apply_expression
	      
@meta_reloc_next
	;; Skip to next expression
	lda            r4L
	clc
	adc            #META_I_RECORD_SIZE
	sta            r4L
	bcc            :+
	inc            r4H

:  
	bra            @meta_reloc_expr_loop

@meta_reloc_expr_exit
	popBank
	lda            #0                      ; indicate found
	rts

;;
;; Adjust an expression addr pointed to by (r4),y
;; Input r4 - Pointer to the expression
;;          Y - Points to address value inside of expression
;;         r1 - Insert point
;;         r2 - 16 bit signed offset
;;         r3 - Region end
;; Clobbers TMP2
;;
@meta_reloc_expr_addr
	lda            (r4),y
	sta            TMP2L                      ; TMP2 = expr_target
	iny
	lda            (r4),y
	sta            TMP2H

	ifLT           TMP2,r1,@meta_reloc_expr_addr_exit   ; If expr_target < insert_location, don't relocate.
	ifLT           r3,TMP2,@meta_reloc_expr_addr_exit   ; If expr_target > region_end, don't relocate.
	      
	dey
	clc
	lda            r2L
	adc            TMP2L
	sta            (r4),y
	bcc            @meta_reloc_expr_addr_exit
	iny
	lda            TMP2H
	adc            r2H
	sta            (r4),y

@meta_reloc_expr_addr_exit
	rts

;;
;; For a given expression, evaluate it and replace the function value into memory
;; Input r4 - points to expression
;; Clobbers M1
;; Preserve X for caller's benefit
;;
@meta_apply_expression
	pushBankVar    bank_meta_i
	PushW          r1
	phx
	      
	MoveW          r4,r1

	ldy            #0
	lda            (r4),y
	sta            M1L
	iny
	lda            (r4),y
	sta            M1H
	
	jsr            @meta_eval_expression
	bcs            @meta_apply_exit
	      
	IncW           M1
	lda            r1L
	sta            (M1)

@meta_apply_exit
	plx
	PopW           r1
	popBank
	rts
	      
;;
;; For a pre-parsed expression, evaluate it and return the value in r1
;; Input r4 - points to expression
;; Output r1 - value of expression
;;
@meta_eval_expression
	ldy            #2
	lda            (r1),y
	and            #META_FN_MASK
	asl
	tax
	jmp            (@meta_eval_case,x)
	rts


@meta_eval_case
	.word          @meta_eval_none      ; FN_NONE
	.word          @meta_eval_hi_byte   ; FN_HI_BYTE
	.word          @meta_eval_lo_byte   ; FN_LO_BYTE

@meta_eval_none
	sec
	rts

@meta_eval_hi_byte
	iny
	iny
	lda            (r4),y
	sta            r1L
	stz            r1H
	clc
	rts

@meta_eval_lo_byte
	iny
	lda            (r4),y
	sta            r1L
	stz            r1H
	clc
	rts

;;
;; Delete an expression. 
;; 
;; Input r1 - Address for searching
;;        X - byte count for corresponding deleted instruction
;; Preserves r2,r3
;;
meta_delete_expr
	stx            TMP2L                   ; save for relocation pass
	      
	PushW          r1
	jsr            meta_find_expr          ; r1 = expression to delete
	beq            @meta_delete_continue
	PopW           r1
	rts
	      
@meta_delete_continue
	PushW          r2
	PushW          r3
	      
	pushBankVar    bank_meta_i
	      
	;; r1 dst - already set by "find"
	;; r0 src
	lda            r1H
	sta            r0H
	      
	lda            r1L
	clc
	adc            #META_I_RECORD_SIZE
	sta            r0L
	bcc            :+
	inc            r0H                     ; r0 == src
	      
:
	;; r2 byte count
	lda            meta_i_last
	sec
	sbc            r0L
	sta            r2L
	lda            meta_i_last+1
	sbc            r0H
	sta            r2H                     ; r3 == size

	kerjsr         MEMCOPY

	;; Update "last" pointer
	lda            meta_i_last
	sec
	sbc            #META_I_RECORD_SIZE
	sta            meta_i_last
	bcs            :+
	dec            meta_i_last+1
:  

@meta_delete_relocate_exit
	popBank

	PopW           r3
	PopW           r2
	PopW           r1
	ldx            TMP2L
	rts
