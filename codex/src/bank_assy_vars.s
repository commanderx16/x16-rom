;;;
;;; Vars to record predefined banks for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.ifndef __X16_BANK_ASSY_VARS__
	__X16_BANK_ASSY_VARS__=1

	.data
	
	.export bank_max, bank_assy, bank_scr1, bank_scr2, bank_meta_l, bank_meta_i, bank_rom_orig, bank_plugin, bank_scrollback

bank_max        .byte 0
bank_assy       .byte 0
bank_meta_l     .byte 0
bank_meta_i     .byte 0
bank_plugin     .byte 0
bank_scrollback .byte 0
bank_scr1       .byte 0
bank_scr2       .byte 0
bank_rom_orig   .byte 0

	.endif
   
