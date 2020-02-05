; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE


screen_check_space_ends_line:

	jsr screen_get_logical_line_end_ptr

	jsr screen_get_char
	cmp #$20

	rts
