.include "../banks.inc"

.import bjsrfar, banked_irq

.macro bridge_internal segment, symbol
	.local address
	.segment segment
address = *
	.segment "KERNSUP"
symbol:
	jsr bjsrfar
	.word address
	.byte BANK_KERNAL
	rts
	.segment segment
	jmp symbol
.endmacro

.macro bridge symbol
	bridge_internal "KERNSUPV", symbol
.endmacro

.macro bridge2 symbol
	bridge_internal "KERNSUPV2", symbol
.endmacro

.macro bridge4 symbol
	bridge_internal "KERNSUPV4", symbol
.endmacro

.segment "KERNSUPV4"
	bridge4 GRAPH_LL_init                ; $FE00
	bridge4 GRAPH_LL_get_info            ; $FE03
	bridge4 GRAPH_LL_cursor_position     ; $FE06
	bridge4 GRAPH_LL_cursor_next_line    ; $FE09
	bridge4 GRAPH_LL_get_pixel           ; $FE0C
	bridge4 GRAPH_LL_get_pixels          ; $FE0F
	bridge4 GRAPH_LL_set_pixel           ; $FE12
	bridge4 GRAPH_LL_set_pixels          ; $FE15
	bridge4 GRAPH_LL_set_8_pixels        ; $FE18
	bridge4 GRAPH_LL_set_8_pixels_opaque ; $FE1B
	bridge4 GRAPH_LL_fill_pixels         ; $FE1E
	bridge4 GRAPH_LL_filter_pixels       ; $FE21
	bridge4 GRAPH_LL_move_pixels         ; $FE24


	.segment "KERNSUPV2"

	.byte 0,0,0                ; $FF00
	.byte 0,0,0                ; $FF03
	.byte 0,0,0                ; $FF06
	.byte 0,0,0                ; $FF09
	.byte 0,0,0                ; $FF0C
	.byte 0,0,0                ; $FF0F
	.byte 0,0,0                ; $FF12
	.byte 0,0,0                ; $FF15
	.byte 0,0,0                ; $FF18

	bridge2 GRAPH_init         ; $FF1B
	bridge2 GRAPH_clear        ; $FF1E
	bridge2 GRAPH_set_window   ; $FF21
	bridge2 GRAPH_set_colors   ; $FF24
	bridge2 GRAPH_draw_line    ; $FF27
	bridge2 GRAPH_draw_rect    ; $FF2A
	bridge2 GRAPH_move_rect    ; $FF2D
	bridge2 GRAPH_draw_oval    ; $FF30
	bridge2 GRAPH_draw_image   ; $FF33
	bridge2 GRAPH_set_font     ; $FF36
	bridge2 GRAPH_get_char_size; $FF39
	bridge2 GRAPH_put_char     ; $FF3C

	.byte 0,0,0
	.byte 0,0

	bridge2 monitor             ; $FF44: monitor
	bridge2 restore_basic       ; $FF47: restore_basic
	bridge2 close_all           ; $FF4A: CLOSE_ALL – close all files on a device
	bridge2 clock_set_date_time ; $FF4D: clock_set_date_time - set date and time
	bridge2 clock_get_date_time ; $FF50: clock_get_date_time - get date and time
	bridge2 joystick_scan       ; $FF53: joystick_scan
	bridge2 joystick_get        ; $FF56: joystick_get
	bridge2 lkupla              ; $FF59: LKUPLA
	bridge2 lkupsa              ; $FF5C: LKUPSA
	bridge2 swapper             ; $FF5F: SWAPPER – switch between 40 and 80 columns
	.byte 0,0,0                 ; $FF62: DLCHR – init 80-col character RAM  [NYI]
	.byte 0,0,0                 ; $FF65: PFKEY – program a function key [NYI]
	bridge2 mouse_config        ; $FF68: mouse_config
	bridge2 mouse_get           ; $FF6B: mouse_get
	jmp bjsrfar                 ; $FF6E: JSRFAR – gosub in another bank
	.byte 0,0,0                 ; $FF71: JMPFAR – goto another bank
	bridge2 indfet              ; $FF74: FETCH – LDA (fetvec),Y from any bank
	bridge2 stash               ; $FF77: STASH – STA (stavec),Y to any bank
	bridge2 cmpare              ; $FF7A: CMPARE – CMP (cmpvec),Y to any bank
	bridge2 primm               ; $FF7D: PRIMM – print string following the caller’s code

.segment "KERNSUPV"

	.byte $ff       ;

	bridge cint
	bridge ioinit
	bridge ramtas

	bridge restor
	bridge vector

	bridge setmsg
	bridge secnd
	bridge tksa
	bridge memtop
	bridge membot
	bridge scnkey
	bridge settmo
	bridge acptr
	bridge ciout
	bridge untlk
	bridge unlsn
	bridge listn
	bridge talk
	bridge readst
	bridge setlfs
	bridge setnam
	bridge open
	bridge close
	bridge chkin
	bridge ckout
	bridge clrch
	bridge basin
	bridge bsout
	bridge loadsp
	bridge savesp
	bridge settim
	bridge rdtim
	bridge stop
	bridge getin
	bridge clall
	bridge udtim
	bridge scrorg
	bridge plot
	bridge iobase

	;private
	jmp monitor
	.byte 0

	.word $ffff ; nmi
	.word $ffff ; reset
	.word banked_irq

