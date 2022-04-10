;;;
;;; Screen control for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_SCREEN__
	__X16_SCREEN__=1

	.import clear, init_screen_variables, screen_set_fg_color, read_key_with_prompt, read_string_with_prompt
	.import read_string, read_string_preloaded, draw_box, draw_box_center_lines, erase_box
	.import draw_horizontal_line, draw_vertical_line, save_vera_state, restore_vera_state, save_user_screen, restore_user_screen
	.import screen_clear_scrollback, screen_get_prev_scrollback_address, screen_add_scrollback_address
	.import prtstr, print_horizontal_line, gotoPrompt, prtxlatedcodes, prthexbytes, prthex, prtspaceto
	.import rdhex2, bs_out_str, prtstr_shim, prtstr_at_xy, print_header

	.import SCROLLBACK_COUNT
	.importzp SCR_QUOTE, DATA_ROW, DBL_QUOTE

	.importzp CURSOR_DN, CURSOR_UP, HDR_ROW, HDR_COL, DELETE, LAST_ROW
	.importzp COLOR_BLACK, COLOR_WHITE, COLOR_RED, COLOR_CYAN, COLOR_VIOLET
	.importzp COLOR_GREEN, COLOR_BLUE, COLOR_YELLOW, COLOR_ORANGE, COLOR_BROWN
	.importzp COLOR_LT_RED, COLOR_DK_GREY, COLOR_GREY, COLOR_LT_GREEN, COLOR_LT_BLUE, COLOR_LT_GREY

	.importzp COLOR_CDR_BACK_HIGHLIGHT, COLOR_CDR_TEXT_INV, COLOR_CDR_MEM
	.importzp COLOR_CDR_ADDR, COLOR_CDR_BYTES, COLOR_CDR_INST, COLOR_CDR_ARGS, COLOR_CDR_LABEL, COLOR_CDR_ERROR
	.endif
