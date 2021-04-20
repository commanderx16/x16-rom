;;;
;;; RAM bank control for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.exportzp BANK_CTRL_ROM, BANK_CTRL_RAM
	.export bank_initialize, bank_pop, bank_push, set_dirty

	.include "bank_assy.inc"
	.include "bank_assy_vars.inc"
	
	__X16_BANK__=1
	.include "x16_kernal.inc"

	BANK_CTRL_RAM = $00
	BANK_CTRL_ROM = $01

bank_initialize
	;; Make sure kernel swapped in so BRK instruction doesn't
	;; run through an incompatible stack framing routine, making
	;; the brk handler confused. 2019-10-18
	;;

	sec
	kerjsr MEMTOP
	
	dec                       ; A = max bank number
	
	sta     bank_max
	dec
	sta     bank_assy
	dec
	sta     bank_meta_l
	dec
	sta     bank_meta_i
	dec
	sta     bank_plugin
	dec
	sta     bank_scrollback
	dec
	sta     bank_scr1
	dec
	sta     bank_scr2
	rts

;;;
;;; Pop a bank (from stack) and restore bank value
;;; Input - bank value on stack
;;;
;;; Clobbers - TMP1, X, Y
;;; 
;;; To perform this operation, the routine will pull the bank address,
;;; set the bank_control, move the return address, return from routine.
;;; 
bank_pop
	pha                     ; Save A
	phx
	lda    #1               ; Setup TMP1 to point into stack
	sta    TMP1H
	tsx
	stx    TMP1L

	ldy    #5
	lda   (TMP1),y
	sta   BANK_CTRL_RAM

	;; Move the return address down by one byte 
	dey
	lda   (TMP1),y               ; (),4
	iny
	sta   (TMP1),y               ; (),5

	ldy   #3
	lda   (TMP1),y               ; (),3
	iny
	sta   (TMP1),y               ; (),4
	
	plx
	pla                          ; Restore A
	ply                          ; Discard old address value, get return address staged.
	rts
	
;;;
;;; Bank push
;;; Input - Bank value in A
;;;
;;; Clobbers TMP1, TMP2
;;;
bank_push
	stx   TMP2L

	plx                     ; Return addr low byte
	stx   TMP1L
	plx                     ; Return address hi byte
	stx   TMP1H

	ldx   BANK_CTRL_RAM
	phx
	sta   BANK_CTRL_RAM

	ldx   TMP1H             ; Set up return address, then do the return
	phx
	ldx   TMP1L
	phx

	ldx   TMP2L

	rts
	
;;
;; Set dirty bit to value in A
;;
set_dirty
	tay
	lda         bank_assy
	jsr         bank_push
	sty         assy_dirty
	jsr         bank_pop
	rts

