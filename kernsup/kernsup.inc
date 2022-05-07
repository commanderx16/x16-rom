.byte 0,0,0                       ; $FEA8
.byte 0,0,0                       ; $FEAB
.byte 0,0,0                       ; $FEAE
.byte 0,0,0                       ; $FEB1
.byte 0,0,0                       ; $FEB4
.byte 0,0,0                       ; $FEB7
.byte 0,0,0                       ; $FEBA

bridge kbdbuf_peek                ; $FEBD
bridge kbdbuf_get_modifiers       ; $FEC0
bridge kbdbuf_put                 ; $FEC3

bridge i2c_read_byte              ; $FEC6
bridge i2c_write_byte             ; $FEC9

bridge monitor                    ; $FECC

bridge entropy_get                ; $FECF

bridge keymap                     ; $FED2

bridge console_set_paging_message ; $FED5
bridge console_put_image          ; $FED8
bridge console_init               ; $FEDB
bridge console_put_char           ; $FEDE
bridge console_get_char           ; $FEE1

bridge memory_fill                ; $FEE4
bridge memory_copy                ; $FEE7
bridge memory_crc                 ; $FEEA
bridge memory_decompress          ; $FEED
bridge sprite_set_image           ; $FEF0
bridge sprite_set_position        ; $FEF3

bridge FB_init                ; $FEF6
bridge FB_get_info            ; $FEF9
bridge FB_set_palette         ; $FEFC
bridge FB_cursor_position     ; $FEFF
bridge FB_cursor_next_line    ; $FF02
bridge FB_get_pixel           ; $FF05
bridge FB_get_pixels          ; $FF08
bridge FB_set_pixel           ; $FF0B
bridge FB_set_pixels          ; $FF0E
bridge FB_set_8_pixels        ; $FF11
bridge FB_set_8_pixels_opaque ; $FF14
bridge FB_fill_pixels         ; $FF17
bridge FB_filter_pixels       ; $FF1A
bridge FB_move_pixels         ; $FF1D

bridge GRAPH_init          ; $FF20
bridge GRAPH_clear         ; $FF23
bridge GRAPH_set_window    ; $FF26
bridge GRAPH_set_colors    ; $FF29
bridge GRAPH_draw_line     ; $FF2C
bridge GRAPH_draw_rect     ; $FF2F
bridge GRAPH_move_rect     ; $FF32
bridge GRAPH_draw_oval     ; $FF35
bridge GRAPH_draw_image    ; $FF38
bridge GRAPH_set_font      ; $FF3B
bridge GRAPH_get_char_size ; $FF3E
bridge GRAPH_put_char      ; $FF41
bridge macptr              ; $FF44: macptr
bridge enter_basic         ; $FF47: enter_basic
bridge close_all           ; $FF4A: CLOSE_ALL – close all files on a device
bridge clock_set_date_time ; $FF4D: clock_set_date_time - set date and time
bridge clock_get_date_time ; $FF50: clock_get_date_time - get date and time
bridge joystick_scan       ; $FF53: joystick_scan
bridge joystick_get        ; $FF56: joystick_get
bridge lkupla              ; $FF59: LKUPLA
bridge lkupsa              ; $FF5C: LKUPSA
bridge screen_mode         ; $FF5F: get/set screen mode
bridge screen_set_charset  ; $FF62: activate 8x8 text mode charset
.byte 0,0,0                ; $FF65: PFKEY – program a function key [NYI]
bridge mouse_config        ; $FF68: mouse_config
bridge mouse_get           ; $FF6B: mouse_get
jmp xjsrfar                ; $FF6E: JSRFAR – gosub in another bank
bridge mouse_scan          ; $FF71: mouse_scan
bridge indfet              ; $FF74: FETCH – LDA (fetvec),Y from any bank
bridge stash               ; $FF77: STASH – STA (stavec),Y to any bank
bridge cmpare              ; $FF7A: CMPARE – CMP (cmpvec),Y to any bank
bridge primm               ; $FF7D: PRIMM – print string following the caller’s code

.byte $ff                  ; space for KERNAL version

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
