;;;
;;; PETSCII utilities for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
;;
;; Converting a petscii code to C64 screen codes. 
;; The macro should not be used willy-nilly. 
;; on the other hand, the subroutine might want to be
;; called on an inner loop either.
;;

	NUM1=$61

	.macro petscii2Screen
	   phy
	   pha                            ; save A

	   lsr                            ; Convert character code to table index (chr div 32)
	   lsr
	   lsr
	   lsr
	   lsr
	   tax

	   pla                             ; Restore A <= petscii code
	   clc
	   adc     petscii_to_scr_table,x
	   ply
	.endmacro

	.export petscii_to_scr

;;
;; petscii_to_scr
;; Convert a PETSCII character to a screen code
;; Based on the table at http://sta.c64.org/cbm64pettoscrext.html
;;
;; Input - A the character
;; Output - A the screen code
;;

petscii_to_scr
	petscii2Screen
	rts

petscii_to_scr_table
	.byte   $80     ; $00 - $1f
	.byte   $00     ; $20 - $3f
	.byte   $C0     ; $40 - $5f
	.byte   $E0     ; $60 - $7f
	.byte   $40     ; $80 - $9f
	.byte   $C0     ; $A0 - $bf
	.byte   $00     ; $C0 - $df
	.byte   $80     ; $E0 - $ff

