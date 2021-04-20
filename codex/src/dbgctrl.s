;;;
;;; Control logic for debug methods, stepping, etc.
;;; For the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.export step_apply, step_suspend, debug_get_brk_adjustment
	.export registers_save, registers_restore

	.exportzp JMP_INSTRUCTION, BRK_INSTRUCTION

	.include "bank.inc"
	.include "bank_assy.inc"
	.include "bank_assy_vars.inc"
	.include "decoder.inc"
	.include "x16_kernal.inc"


	BRK_INSTRUCTION=$00

;;
;; step_apply - Given an address (r1), set a step-break after the
;; the instruction at r1. If the instruction at r1 is a branch,
;; two step-breaks will be placed, one for each possible path of the
;; branch (except for bra).
;;
;; Assumes that all steps have been suspended.
;;
;; INPUT r1 - Next address to execute, step-break after
;;        X - Bank number (valid for $a000 - $bfff)
;;
step_apply
	pushBankVar   bank_assy

	;; Set up step_1
	lda   r1H
	cmp   #$a0
	bmi   @step_apply_bank_0
	cmp   #$c0
	bpl   @step_apply_bank_0
	stx   step_1_bank
	bra   @step_set_brk

@step_apply_bank_0
	stz   step_1_bank

@step_set_brk
	lda   step_1_bank
	sta   BANK_CTRL_RAM
	         
	ldy   #1
	lda   (r1),y                     ; get first arg byte, in case it's a branch
	sta   M2L
	iny
	lda   (r1),y                     ; get second arg byte in case it's a jmp
	sta   M2H
	         
	jsr   step_jmp_apply
	bcc   @step_regular
	lda   #0                         ; fake out byte_count.mode
	pha   
	bra   @step_ins_break
	         
@step_regular
	jsr   decode_get_entry           ; Set up M1 to point to the entry
	ldy   #1
	lda   (M1),y                     ; Get byte_count.mode
	pha

	;; Increment r1 to point to break location
	lsr                              ; Isolate byte count
	lsr
	lsr
	lsr
	lsr
	clc
	adc   r1L
	sta   r1L
	bcc   :+
	inc   r1H

:  ;; r1 pointing to instruction following instruction

@step_ins_break
	lda   bank_assy
	sta   BANK_CTRL_RAM
	         
	lda   r1L
	sta   step_1_addr
	lda   r1H
	sta   step_1_addr+1

	;; Set break instruction in target, note delicate bank switching
	lda   step_1_bank
	sta   BANK_CTRL_RAM
	lda   (r1)
	sta   M2H                  ; save for bank switch
	lda   #BRK_INSTRUCTION
	sta   (r1)
	lda   bank_assy
	sta   BANK_CTRL_RAM
	lda   M2H
	sta   step_1_byte

	;; Check to see if it's a branch
	pla   
	and   #$1f
	cmp   #MODE_BRANCH
	bne   @step_set_exit

	;; set values for possible branch target
	lda   M2L                  ; Grab branch offset
	clc
	adc   r1L
	sta   r1L
	bcc   :+
	inc   r1H                  ; r1 pts to branch target
:  
	dey
	lda   step_1_bank
	sta   BANK_CTRL_RAM
	lda   (r1),y               ; get branch target opcode
	tax                        ; Save for after hi ram page switch
	lda   #BRK_INSTRUCTION
	sta   (r1),y
	lda   bank_assy
	sta   BANK_CTRL_RAM
	txa
	sta   step_2_byte
	lda   r1L
	sta   step_2_addr
	lda   r1H
	sta   step_2_addr+1
	lda   step_1_bank
	sta   step_2_bank
	         
@step_set_exit
	popBank
	rts
	         
	JMP_INSTRUCTION = $4c
	JMP_IND_INSTRUCTION = $6c
	JMP_IND_X_INSTRUCTION = $7c
	         
;;
;; Check for those pesky JMP instructions, set values as needed for step_apply
;; Input r1 - Pointing to next instruction to execute
;;       M2 - two byte arguments from JMP
;; Output r1 - New ptr to next instruction to execute
;; Carry     - if set, JMP applied
;;
;; NOTE: This is just a routine to support code readabibility, and should not be called outside of step_apply.
;;
step_jmp_apply
	lda   (r1)                       ; Get next opcode
	cmp   #JMP_INSTRUCTION
	bne   @step_jmp_next

	MoveW  M2,r1                     ; r1 = jmp dst
	bra   @step_jmp_done

@step_jmp_next
	cmp   #JMP_IND_INSTRUCTION
	bne   @step_jmp_next2

	ldy   #0
	lda   (M2),y
	sta   r1L
	iny
	lda   (M2),y
	sta   r1H
	bra   @step_jmp_done

@step_jmp_next2
	cmp   #JMP_IND_X_INSTRUCTION
	bne   @step_jmp_exit
	
	pushBankVar   bank_assy
	ldx   brk_data_x
	popBank
	clc
	txa
	adc   M2L
	sta   M2L
	bcc   :+
	inc   M2H

:  
	ldy   #0
	lda   (M2),y
	sta   r1L
	iny
	lda   (M2),y
	sta   r1H

@step_jmp_done
	sec
	rts
	         
@step_jmp_exit
	clc
	rts
	         
;;
;; step_suspend - Restore step-breaks, and replace byte opcodes.
;;
step_suspend
	pushBankVar  bank_assy
	LoadW        M1,step_var_start
	ldy          #0
	lda          (M1),y
	sta          M2L                 ; Save for instruction restore
	iny
	lda          (M1),y
	sta          r1L
	iny
	lda          (M1),y
	sta          r1H
	ora          r1L
	beq          @step_suspend_exit  ; If not set, do no harm
	iny
	lda          (M1),y              ; old opcode for step 1
	sta          M2H
	lda          M2L
	sta          BANK_CTRL_RAM
	lda          M2H
	sta          (r1)

	lda          bank_assy
	sta          BANK_CTRL_RAM
	ldy          #4
	lda          (M1),y              ; save bank two for instruction restore
	iny

	lda          (M1),y              ; addr 2
	sta          r1L
	iny
	lda          (M1),y
	sta          r1H
	ora          r1L
	beq          @step_suspend_exit
	iny
	         
	lda          (M1),y              ; old opcode step 2
	sta          M2H
	lda          M2L
	sta          BANK_CTRL_RAM
	lda          M2H
	sta          (r1)
	         
@step_suspend_exit
	;; Zero out steps
	lda          bank_assy
	sta          BANK_CTRL_RAM
	LoadW        r1,step_var_start
	ldy          #<(step_var_end - step_var_start)
	lda          #0
	
:  
	sta          (r1),y
	dey
	bne          :-
	         
	popBank
	rts

;;
;; Get brk adjustment
;; Will look at brk_data_pc and brk_data_pc+1, assumes bank is BANK_ASSY
;;
;; Depending on how the break was invoked, calculate an offset from the break.
;; Cases are:
;; 1: step : byte count of original instruction + 1 (to fix stupid 6502 behvior
;; 2: User break: 1 (to fix stupid 6502 behavior)
;;
debug_get_brk_adjustment
	LoadW  M1,step_var_start
	ldx   #0

	;; Temporary target address to compare with breaks
	lda   brk_data_pc+1
	sta   M2H
	lda   brk_data_pc
	sec
	sbc   #2
	sta   M2L
	bcs   @get_brk_adj_loop
	dec   M2H
	         
	         ; Find a matching step-break
@get_brk_adj_loop
	ldy   #0
	lda   (M1),y            ; bank
	cmp   brk_bank
	bne   @get_brk_adj_inc
	iny

	lda   (M1),y            ; addr low
	cmp   M2L
	bne   @get_brk_adj_inc
	iny

	lda   (M1),y            ; addr hi
	cmp   M2H
	bne   @get_brk_adj_inc
	iny
	         
	;; found it
	lda   #2
	rts
	         
@get_brk_adj_inc
	inx
	txa
	cmp   #(2)   ; two steps
	beq   @get_brk_adj_exit
	         
	lda   M1L
	clc
	adc   #4
	sta   M1L
	bcc   :+
	inc   M1H
:  
	bra   @get_brk_adj_loop

@get_brk_adj_exit
	lda   #1
	rts
	         
;;
;; Save user zero page locations r0 through r15, and x16 since CodeX uses it for screen coords
;;
registers_save
	;;  Don't use "pushBank" here, since it alters temp registers
	lda          BANK_CTRL_RAM
	pha
	lda          bank_assy
	sta          BANK_CTRL_RAM
	
	lda          r0L
	sta          reg_save
	lda          r0H
	sta          reg_save+1
	lda          r1L
	sta          reg_save+2
	lda          r1H
	sta          reg_save+3

	;; From ptr
	lda          #2
	sta          r0L
	stz          r0H

	;; To ptr
	LoadW        r1,reg_save

	ldy          #4                  ; Since r0 & r1 have been saved, start at r2
:  
	lda          (r0),y
	sta          (r1),y
	iny
	tya
	cmp          #(LAST_ZP_REGISTER - r0L + 1)
	bne          :-
	      
	popBank
	rts


;;
;; Restore user zero page locations r0 - r15, including x16 (scr coords)
;;
registers_restore
	pushBankVar bank_assy
	;; src ptr
	lda          #2
	sta          r0L
	stz          r0H

	;; From ptr
	LoadW         r1,reg_save

	ldy          #4                  ; Since r0 & r1 will be restored, start at r2
:  
	lda          (r1),y
	sta          (r0),y
	iny
	cpy          #(LAST_ZP_REGISTER - r0L + 1)
	bne          :-
	      
	lda          reg_save
	sta          r0L
	lda          reg_save+1
	sta          r0H
	lda          reg_save+2
	sta          r1L
	lda          reg_save+3
	sta          r1H

	;; Don't use popBank here since it mucks about with TMP1 & TMP2
	pla
	sta BANK_CTRL_RAM

	rts

