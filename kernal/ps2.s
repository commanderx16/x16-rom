port_ddr  =d2ddra
port_data   =d2pra
bit_data=1              ; 6522 IO port data bit mask  (PA0)
bit_clk =2              ; 6522 IO port clock bit mask (PA1)

MODIFIER_SHIFT = 1 ; C64:  Shift
MODIFIER_ALT   = 2 ; C64:  Commodore
MODIFIER_CTRL  = 4 ; C64:  Ctrl
MODIFIER_WIN   = 8 ; C128: Alt
MODIFIER_CAPS  = 16; C128: Caps

;
; set keyboard layout .a
;
setkbd	tax
	lda #<keymaps
	sta keytab
	lda #>keymaps
	sta keytab+1
	txa
	beq setkb1      ;found
setkb5	ldy #0
setkb4	lda (keytab),y  ;descriptor length
	beq setkbd      ;end of list
setkb2	clc
	adc keytab      ;skip it
	sta keytab
	bcc setkb3
	inc keytab+1
setkb3	dex
	bne setkb4
setkb1	rts


; cycle keyboard layouts
cycle_layout:
	ldx #1
	jsr setkb5
; put name into keyboard buffer
	ldx #$8d ; shift + cr
	stx keyd
	ldy #1
:	lda (keytab),y
	beq :+
	sta keyd,y
	iny
	cpy #6
	bne :-
:	txa
	sta keyd,y
	iny
	iny
	sty ndx
	rts

scnkey	jsr receive_down_scancode_no_modifiers
	beq drv_end

	tay

	cpx #0
	bne down_ext
; *** regular scancodes
	cpy #$01 ; f9
	beq cycle_layout
	cmp #$83 ; convert weird f7 scancode
	bne not_f7
	lda #$02 ; this one is unused
	tay
not_f7:
	cmp #$0e ; scancodes < $0E and > $68 are independent of modifiers
	bcc is_unshifted
	cmp #$68
	bcc not_numpad
is_unshifted:
	ldx #4 * 2
	bne bit_found ; use unshifted table

not_numpad:




	ldx #0
	lda shflag2
	cmp #MODIFIER_ALT | MODIFIER_CTRL
	bne find_bit
	ldx #3 * 2
	bne bit_found ; use AltGr table

find_bit:
	lsr
	bcs bit_found
	inx
	inx
	cpx #4 * 2
	bne find_bit

bit_found:
;	lda kbdtab,x
	sta ckbtab
;	lda kbdtab + 1,x
	sta ckbtab + 1
	ldx #BANK_KERNAL
	lda #ckbtab
	sta fetvec
	jsr fetch
	beq drv_end
	jmp add_to_buf

down_ext:
	cpx #$e1 ; prefix $E1 -> E1-14 = Pause/Break
	beq is_stop
	cmp #$4a ; Numpad /
	bne not_4a
	lda #'/'
	bne add_to_buf
not_4a:	cmp #$5a ; Numpad Enter
	beq is_enter
	cpy #$6c ; special case shift+home = clr
	beq is_home
not_5a: cmp #$68
	bcc drv_end
	cmp #$80
	bcs drv_end
nhome:	lda tab_extended-$68,y
	bne add_to_buf
drv_end:
	rts

; or $80 if shift is down
is_home:
	ldx #$13 * 2; home (-> clr)
	.byte $2c
is_enter:
	ldx #$0d * 2 ; return (-> shift+return)
	.byte $2c
is_stop:
	ldx #$03 * 2 ; stop (-> run)
	lda shflag2
	lsr ; shift -> C
	txa
	ror
; passes into add_to_buf

;****************************************
; ADD CHAR TO KBD BUFFER
;****************************************
add_to_buf:
	cmp #3 ; stop
	bne add1
	ldx #$7f
	.byte $2c
add1:	ldx #$ff
	stx $91
	ldx ndx ; length of keyboard buffer
	cpx xmax
	bcs add2 ; full, ignore
	sta keyd,x ; store
	inc ndx
add2:	rts

;****************************************
; RECEIVE BYTE
; out: A: byte (0 = none)
;      Z: byte available
;           0: yes
;           1: no
;      C:   0: parity OK
;           1: parity error
;****************************************
; The byte receive function is based on
; "AT-Keyboard" by İlker Fıçıcılar
;****************************************
receive_byte:
; test for badline-safe time window
; set input, bus idle
	lda port_ddr ; set CLK and DATA as input
	and #$ff-bit_clk-bit_data
	sta port_ddr ; -> bus is idle, keyboard can start sending

	lda #bit_clk+bit_data
	ldy #10 * mhz
:	dey
	beq lc08c
	bit port_data
	bne :- ; wait for CLK=0 and DATA=0 (start bit)

	lda #bit_clk
lc044:	bit port_data ; wait for CLK=1 (not ready)
	beq lc044
	ldy #9 ; 9 bits including parity
lc04a:	bit port_data
	bne lc04a ; wait for CLK=0 (ready)
	lda port_data
	and #bit_data
	cmp #bit_data
	ror kbdbyte ; save bit
	lda #bit_clk
lc058:	bit port_data
	beq lc058 ; wait for CLK=1 (not ready)
	dey
	bne lc04a
	rol kbdbyte ; get parity bit into C
lc061:	bit port_data
	bne lc061 ; wait for CLK=0 (ready)
lc065:	bit port_data
	beq lc065 ; wait for CLK=1 (not ready)
lc069:	jsr kbdis
	lda kbdbyte
	beq lc08b ; zero -> return
	php ; save parity
lc07c:	lsr a ; calculate parity
	bcc lc080
	iny
lc080:	cmp #0
	bne lc07c
	tya
	plp ; transmitted parity
	adc #1
	lsr a ; C=0: parity OK
	lda kbdbyte
lc08b:	rts

lc08c:	clc
	lda #0
	sta kbdbyte
	beq lc069 ; always

kbdis:	lda port_ddr
	ora #bit_clk+bit_data
	sta port_ddr ; set CLK and DATA as output
	lda port_data
	and #$ff - bit_clk ; CLK=0
	ora #bit_data ; DATA=1
	sta port_data
	rts

;****************************************
; RECEIVE SCANCODE:
; out: X: prefix (E0, E1; 0 = none)
;      A: scancode low (0 = none)
;      C:   0: key down
;           1: key up
;      Z: scancode available
;           0: yes
;           1: no
;****************************************
receive_scancode:
	jsr receive_byte
	bcs rcvsc1 ; parity error
	bne rcvsc2 ; non-zero code
rcvsc1:	lda #0
	rts
rcvsc2:	cmp #$e0 ; extend prefix 1
	beq rcvsc3
	cmp #$e1 ; extend prefix 2
	bne rcvsc4
rcvsc3:	sta prefix
	beq receive_scancode ; always
rcvsc4:	cmp #$f0
	bne rcvsc5
	rol brkflg ; set to 1
	bne receive_scancode ; always
rcvsc5:	pha
	lsr brkflg ; break bit into C
	ldx prefix
	lda #0
	sta prefix
	sta brkflg
	pla ; lower byte into A
	rts

;****************************************
; RECEIVE SCANCODE AFTER shflag
; * key down only
; * modifiers have been interpreted
;   and filtered
; out: X: prefix (E0, E1; 0 = none)
;      A: scancode low (0 = none)
;      Z: scancode available
;           0: yes
;           1: no
;****************************************
receive_down_scancode_no_modifiers:
	jsr receive_scancode
	beq no_key
	jsr scancode_to_joystick
	php
	jsr check_mod
	bcc no_mod
	plp
	bcc key_down
	eor #$ff
	and shflag2
	.byte $2c
key_down:
	ora shflag2
	sta shflag2
key_up:	lda #0 ; no key to return
	rts
no_mod:	plp
	bcs key_up
no_key:	rts ; original Z is retained

; XXX handle caps lock

check_mod:
	cpx #$e1
	beq ckmod1
	cmp #$11 ; left alt (0011) or right alt (E011)
	bne nmd_alt
	cpx #$e0 ; right alt
	bne :+
	lda #MODIFIER_ALT | MODIFIER_CTRL
	.byte $2c
:	lda #MODIFIER_ALT
	sec
	rts
nmd_alt:
	cmp #$14 ; left ctrl (0014) or right ctrl (E014)
	beq md_ctl
	cpx #0
	bne ckmod2
	cmp #$12 ; left shift (0012)
	beq md_sh
	cmp #$59 ; right shift (0059)
	beq md_sh
ckmod1:	clc
	rts
ckmod2:	cmp #$1F ; left win (001F)
	beq md_win
	cmp #$27 ; right win (0027)
	bne ckmod1
md_win:	lda #MODIFIER_WIN
	.byte $2c
md_alt:	lda #MODIFIER_ALT
	.byte $2c
md_ctl:	lda #MODIFIER_CTRL
	.byte $2c
md_sh:	lda #MODIFIER_SHIFT
	sec
	rts

tab_unshifted:
	.byte 0
	.byte KEY_F9           ; $01
	.byte 0
	.byte KEY_F5           ; $03
	.byte KEY_F3           ; $04
	.byte KEY_F1           ; $05
	.byte KEY_F2           ; $06
	.byte KEY_F12          ; $07
	.byte 0
	.byte KEY_F10          ; $09
	.byte KEY_F8           ; $0A
	.byte KEY_F6           ; $0B
	.byte KEY_F4           ; $0C
	.byte KEY_TAB          ; $0D
	.byte KEY_GRAVE        ; $0E
	.byte 0

	.byte 0
	.byte 0                ; $11: Alt
	.byte 0                ; $12: Shift
	.byte 0
	.byte 0                ; $14: Ctrl
	.byte KEY_Q            ; $15
	.byte KEY_1            ; $16
	.byte 0
	.byte 0
	.byte 0
	.byte KEY_Z            ; $1A
	.byte KEY_S            ; $1B
	.byte KEY_A            ; $1C
	.byte KEY_W            ; $1D
	.byte KEY_2            ; $1E
	.byte 0

	.byte 0
	.byte KEY_C            ; $21
	.byte KEY_X            ; $22
	.byte KEY_D            ; $23
	.byte KEY_E            ; $24
	.byte KEY_4            ; $25
	.byte KEY_3            ; $26
	.byte 0
	.byte 0
	.byte KEY_SPACE        ; $29
	.byte KEY_V            ; $2A
	.byte KEY_F            ; $2B
	.byte KEY_T            ; $2C
	.byte KEY_R            ; $2D
	.byte KEY_5            ; $2E
	.byte 0

	.byte 0
	.byte KEY_N            ; $31
	.byte KEY_B            ; $32
	.byte KEY_H            ; $33
	.byte KEY_G            ; $34
	.byte KEY_Y            ; $35
	.byte KEY_6            ; $36
	.byte 0
	.byte 0
	.byte 0
	.byte KEY_M            ; $3A
	.byte KEY_J            ; $3B
	.byte KEY_U            ; $3C
	.byte KEY_7            ; $3D
	.byte KEY_8            ; $3E
	.byte 0

	.byte 0
	.byte KEY_COMMA        ; $41
	.byte KEY_K            ; $42
	.byte KEY_I            ; $43
	.byte KEY_O            ; $44
	.byte KEY_0            ; $45
	.byte KEY_9            ; $46
	.byte 0
	.byte 0
	.byte KEY_PERIOD       ; $49
	.byte KEY_SLASH        ; $4A
	.byte KEY_L            ; $4B
	.byte KEY_SEMICOLON    ; $4C
	.byte KEY_P            ; $4D
	.byte KEY_MINUS        ; $4E
	.byte 0

	.byte 0
	.byte 0
	.byte KEY_APOSTROPHE   ; $52
	.byte 0
	.byte KEY_LEFTBRACKET  ; $54
	.byte KEY_EQUALS       ; $55
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte KEY_RETURN       ; $5A
	.byte KEY_RIGHTBRACKET ; $5B
	.byte 0
	.byte KEY_BACKSLASH    ; $5D
	.byte 0
	.byte 0

	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte KEY_BACKSPACE    ; $66
	.byte 0
	.byte 0
	.byte KEY_1            ; $69
	.byte 0
	.byte KEY_4            ; $6B
	.byte KEY_7            ; $6C
	.byte 0
	.byte 0
	.byte 0

	.byte KEY_0            ; $70
	.byte KEY_NUM_PERIOD   ; $71
	.byte KEY_2            ; $72
	.byte KEY_5            ; $73
	.byte KEY_6            ; $74
	.byte KEY_8            ; $75
	.byte KEY_ESC          ; $76
	.byte 0
	.byte 0
	.byte KEY_PLUS         ; $79
	.byte KEY_3            ; $7A
	.byte KEY_MINUS        ; $7B
	.byte KEY_MULTIPLY     ; $7C
	.byte KEY_9            ; $7D
	.byte 0                ; Scroll Lock
	.byte 0

	.byte 0
	.byte 0
	.byte 0
	.byte KEY_F7           ; $83

tab_extended:
	.byte 0
	.byte KEY_END          ; $69
	.byte 0
	.byte KEY_LEFT         ; $6B
	.byte KEY_HOME         ; $6C
	.byte 0
	.byte 0
	.byte 0
	.byte KEY_INSERT       ; $70
	.byte KEY_DELETE       ; $71
	.byte KEY_DOWN         ; $72
	.byte 0
	.byte KEY_RIGHT        ; $74
	.byte KEY_UP           ; $75
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte KEY_PAGEDOWN     ; $7A
	.byte 0
	.byte 0
	.byte KEY_PAGEUP       ; $7D












