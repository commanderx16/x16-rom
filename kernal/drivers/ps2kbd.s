;----------------------------------------------------------------------
; PS/2 Keyboard Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "../../banks.inc"
.include "../../io.inc"

; code
.import ps2_receive_byte; [ps2]
.import joystick_from_ps2; [joystick]
; data
.import save_ram_bank; [declare]
.import mode; [declare]
.importzp ckbtab; [declare]
.import fetch, fetvec; [routines]
.import kbdmeta, ikbdmeta ; [keymap]

.export kbd_config, kbd_scan, kbd_clear, kbd_put, kbd_get, kbd_peek, kbd_remove, kbd_get_modifiers, kbd_get_stop

MODIFIER_SHIFT = 1 ; C64:  Shift
MODIFIER_ALT   = 2 ; C64:  Commodore
MODIFIER_CTRL  = 4 ; C64:  Ctrl
MODIFIER_WIN   = 8 ; C128: Alt
MODIFIER_CAPS  = 16; C128: Caps

.segment "KVARSB0"

keyd:	.res 10          ;    irq keyboard buffer
ndx:	.res 1           ;$C6 index to keyboard q
shflag:	.res 1           ;    shift flag byte
prefix:	.res 1           ;    X16: PS/2: prefix code (e0/e1)
brkflg:	.res 1           ;    X16: PS/2: was key-up event
stkey:	.res 1           ;$91 stop key flag: $ff = stop down
curkbd:	.res 1           ;    X16: current keyboard layout index
kbdnam:	.res 6           ;    keyboard layout name
kbdtab:	.res 10          ;    pointers to shift/alt/ctrl/altgr/unshifted tables

.segment "PS2KBD"

;
; API
;
kbd_config:
	KVARS_START
	jsr _kbd_config
	KVARS_END
	rts

kbd_scan:
	KVARS_START
	jsr _kbd_scan
	KVARS_END
	rts

kbd_clear:
	KVARS_START
	jsr _kbd_clear
	KVARS_END
	rts

kbd_put:
	KVARS_START
	phx
	jsr add_to_buf
	plx
	KVARS_END
	rts

kbd_get:
	KVARS_START
	jsr _kbd_get
	KVARS_END
	rts

kbd_peek:
	KVARS_START
	lda ndx
	beq :+
	lda keyd
:	KVARS_END
	rts

kbd_remove:
	KVARS_START
	jsr _kbd_remove
	KVARS_END
	rts

kbd_get_modifiers:
	KVARS_START
	lda shflag
	KVARS_END
	rts

kbd_get_stop:
	KVARS_START
	lda stkey	;
	eor #$ff        ;set z if stkey is true
	KVARS_END
	rts

;
; set keyboard layout .a
;  $ff: reload current layout (PETSCII vs. ISO might have changed)
;
_kbd_config:
	cmp #$ff
	bne :+
	lda curkbd
:	tay
	bit mode
	bvs setkb0      ;ISO
	lda #<kbdmeta
	ldx #>kbdmeta
	bne setkb3
setkb0:	lda #<ikbdmeta
	ldx #>ikbdmeta
setkb3:	sta 2
	stx 3
	lda #2
	sta fetvec
	tya
setkb2:	sta curkbd
	asl
	asl
	asl
	asl             ;*16
	tay
	ldx #BANK_KEYBD
	jsr fetch
	beq setkb2      ;end of list? set #0
	ldx #0
setkb1:	phx
	ldx #BANK_KEYBD
	jsr fetch
	plx
	sta kbdnam,x    ;8 bytes kbnam, 8  bytes kbtab
	inx
	iny
	cpx #16
	bne setkb1
	rts

; cycle keyboard layouts
cycle_layout:
	ldx curkbd
	inx
	txa
	jsr _kbd_config
; put name into keyboard buffer
	ldy #$8d ; shift + cr
	sty keyd
	ldx #0
:	lda kbdnam,x
	beq :+
	sta keyd + 1,x
	inx
	cpx #6
	bne :-
:	tya
	sta keyd + 1,x
	inx
	inx
	stx ndx
	rts

_kbd_scan:
	jsr receive_down_scancode_no_modifiers
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
	lda shflag
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
	lda kbdtab,x
	sta ckbtab
	lda kbdtab + 1,x
	sta ckbtab + 1
	ldx #BANK_KEYBD
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
	bra :+
is_enter:
	ldx #$0d * 2 ; return (-> shift+return)
	bra :+
is_stop:
	ldx #$03 * 2 ; stop (-> run)
:	lda shflag
	lsr ; shift -> C
	txa
	ror
; passes into add_to_buf

;****************************************
; ADD CHAR TO KBD BUFFER
;****************************************
add_to_buf:
	stz stkey
	cmp #3 ; stop
	bne :+
	dec stkey
:	ldx ndx ; length of keyboard buffer
	cpx #10 ;maximum type ahead buffer size
	bcs add2 ; full, ignore
	sta keyd,x ; store
	inc ndx
add2:	rts

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
	ldx #1
	jsr ps2_receive_byte
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
	jsr joystick_from_ps2
	php
	jsr check_mod
	bcc no_mod
	plp
	bcc key_down
	eor #$ff
	and shflag
	bra :+
key_down:
	ora shflag
:	sta shflag
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
	bra :++
:	lda #MODIFIER_ALT
:	sec
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
	bra :+
md_alt:	lda #MODIFIER_ALT
	bra :+
md_ctl:	lda #MODIFIER_CTRL
	bra :+
md_sh:	lda #MODIFIER_SHIFT
: sec
	rts

tab_extended:
	;         end      lf hom
	.byte $00,$00,$00,$9d,$00,$00,$00,$00 ; @$68 (HOME is special cased)
	;     ins del  dn      rt  up
	.byte $94,$14,$11,$00,$1d,$91,$00,$00 ; @$70
	;             pgd         pgu brk
	.byte $00,$00,$00,$00,$00,$00,$03,$00 ; @$78

_kbd_clear:
	stz ndx
	rts

_kbd_get:
	lda ndx         ;queue index
	beq lp0         ;nobody there...exit
	sei
;
;remove character from queue
;
_kbd_remove:
	ldy keyd
	ldx #0
:	lda keyd+1,x
	sta keyd,x
	inx
	cpx ndx
	bne :-
	dec ndx
	tya
	cli
lp0:	clc             ;good return
	rts
