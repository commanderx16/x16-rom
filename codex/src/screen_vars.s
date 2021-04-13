;;;
;;; Screen control vars for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.psc02                    ; Enable 65c02 instructions
	.feature labels_without_colons
	
	.data
	
	.export orig_color, input_string_length, input_string, input_string_cursor
	.export screen_width, screen_height, screen_row_prompt, screen_row_data_count, screen_last_row 
	.export print_to_file

orig_color            .byte 0
input_string_length   .byte 0
input_string          .res 64, 0
input_string_cursor   .word 0    ; timer to blink

print_to_file         .byte 0

screen_width          .byte 0
screen_height         .byte 0
screen_row_prompt     .byte 0
screen_row_data_count .byte 0
screen_last_row       .byte 0

