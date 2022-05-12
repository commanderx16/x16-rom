;----------------------------------------------------------------------
; PS/2 Keyboard Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.macpack longbranch
.include "banks.inc"
.include "regs.inc"
.include "io.inc"
.include "mac.inc"

; code
.import ps2_receive_byte; [ps2]
.import joystick_from_ps2_init, joystick_from_ps2; [joystick]
; data
.import mode; [declare]
.import fetch, fetvec; [memory]
.importzp tmp2

.import kbdbuf_put
.import shflag
.import keyhdl
.import check_charset_switch

.import memory_decompress_internal ; [lzsa]

.export kbd_config, kbd_scan, receive_scancode_resume, keymap

MODIFIER_SHIFT = 1 ; C64:  Shift
MODIFIER_ALT   = 2 ; C64:  Commodore
MODIFIER_CTRL  = 4 ; C64:  Ctrl
MODIFIER_WIN   = 8 ; C128: Alt
MODIFIER_CAPS  = 16; C128: Caps
MODIFIER_4080  = 32; 40/80 DISPLAY
MODIFIER_ALTGR = MODIFIER_ALT | MODIFIER_CTRL
; set of modifiers that are toggled on each key press
MODIFIER_TOGGLE_MASK = MODIFIER_CAPS | MODIFIER_4080

TABLE_COUNT = 11
KBDNAM_LEN = 14

.segment "ZPKERNAL" : zeropage
ckbtab:	.res 2           ;    used for keyboard lookup

.segment "KVARSB0"

prefix:	.res 1           ;    PS/2: prefix code (e0/e1)
brkflg:	.res 1           ;    PS/2: was key-up event
curkbd:	.res 1           ;    current keyboard layout index
dk_shift:
	.res 1
dk_scan:
	.res 1

.segment "KEYMAP"
keymap_data:
	.res TABLE_COUNT*128

caps:	.res 16 ; for which keys caps means shift
deadkeys:
	.res 224
kbdnam:
	.res KBDNAM_LEN ; zero-terminated
keymap_len = * - keymap_data

.segment "PS2KBD"

kbd_config:
	KVARS_START
	jsr _kbd_config
	KVARS_END
	rts

keymap:
	KVARS_START
	jsr _keymap
	KVARS_END
	rts

kbd_scan:
	KVARS_START
	jsr _kbd_scan
	KVARS_END
	rts

;
; set keyboard layout .a
;  $ff: reload current layout (PETSCII vs. ISO might have changed)
;
_kbd_config:
	stz dk_scan ; clear dead key

	cmp #$ff
	bne :+
	lda curkbd
:	pha

	lda #<$c000
	sta tmp2
	lda #(>$c000) >> 1
	sta tmp2+1
	lda #tmp2
	sta fetvec

; get keymap
	pla
	sta curkbd
	asl
	asl
	asl
	asl             ;*16
	rol tmp2+1
	tay
	ldx #BANK_KEYBD
	jsr fetch
	bne :+
	sec             ;end of list
	rts
:
; get name
	ldx #0
:	phx
	ldx #BANK_KEYBD
	jsr fetch
	plx
	sta kbdnam,x
	inx
	iny
	cpx #KBDNAM_LEN
	bne :-
; get address
	ldx #BANK_KEYBD
	jsr fetch
	pha
	iny
	ldx #BANK_KEYBD
	jsr fetch
	sta tmp2+1
	pla
	sta tmp2

; copy into banked RAM
	PushW r0
	PushW r1
	PushW r4
	lda tmp2
	sta r0
	lda tmp2+1
	sta r0+1
	lda #<keymap_data
	sta r1
	lda #>keymap_data
	sta r1+1
	LoadW r4, kbd_getsrc
	lda #r0
	sta fetvec
	jsr memory_decompress_internal
	PopW r4
	PopW r1
	PopW r0
	jsr joystick_from_ps2_init
	clc             ;ok
	rts

kbd_getsrc:
	php
	phx
	phy
	ldy #0
	ldx #BANK_KEYBD
	lda #r0
	jsr fetch
	inc r0L
	bne :+
	inc r0H
:	ply
	plx
	plp
	rts


; cycle keyboard layouts
cycle_layout:
	ldx curkbd
	inx
	txa
:	jsr _kbd_config
	lda #0
	bcs :-          ;end of list? use 0
; put name into keyboard buffer
	ldx #0
:	lda kbdnam,x
	beq :+
	jsr kbdbuf_put
	beq :+
	inx
	bra :-
:	lda #$8d ; shift + cr
	jmp kbdbuf_put

;---------------------------------------------------------------
; Get/Set keyboard layout
;
;   In:   .c  =0: set, =1: get
; Set:
;   In:   .x/.y  pointer to layout string (e.g. "DE_CH")
;   Out:  .c  =0: success, =1: failure
; Get:
;   Out:  .x/.y  pointer to layout string
;---------------------------------------------------------------
_keymap:
	bcc @set
	ldx #<kbdnam
	ldy #>kbdnam
	rts

@set:	php
	sei             ;protect ckbtab
	stx ckbtab
	sty ckbtab+1
	lda curkbd
	pha
	lda #0
@l1:	pha
	ldx ckbtab
	ldy ckbtab+1
	phx
	phy
	jsr _kbd_config
	bne @nend
	pla             ;not found
	pla
	pla
	pla
	jsr _kbd_config ;restore original keymap
	plp
	sec
	rts
@nend:
	ply
	plx
	sty ckbtab+1
	stx ckbtab
	ldy #0
@l2:	lda (ckbtab),y
	cmp kbdnam,y
	beq @ok
	pla             ;next
	inc
	bra @l1
@ok:	iny
	cmp #0
	bne @l2
	pla             ;found
	pla
	plp
	clc
	rts

_kbd_scan:
	jsr receive_down_scancode_no_modifiers
	bne :+
	rts
:
	tay

	cpx #0
	jne down_ext
; *** regular scancodes
	cpy #$01 ; f9
	beq cycle_layout
	cmp #$83 ; convert weird f7 scancode
	bne :+
	lda #$02 ; this one is unused
	tay
:
	; combine mode & modifiers into ID byte
	lda mode
	asl
	asl ; bit 6
	php
	lda shflag
	and #<(~MODIFIER_CAPS)
	asl
	plp
	ror

	ldx shflag
	cpx #MODIFIER_CAPS
	jeq handle_caps

cont:
	jsr find_table
	bcs @notab

; For some encodings (e.g. US-Mac), Alt and AltGr is the same, so
; the tables use modifiers $C6 (Alt/AltGr) and $C7 (Shift+Alt/AltGr).
; If we don't find a table and the modifier is (Shift+)Alt/AltGr,
; try these modifier codes.
	lda tmp2
	cmp #$82
	beq @again
	cmp #$83
	beq @again
	cmp #$86
	beq @again
	cmp #$87
	bne @skip
@again:	ora #$46
	jsr find_table
	bcc @skip

@notab:	lda (ckbtab),y
	beq @maybe_dead
	ldx dk_scan
	bne @combine_dead
	jmp kbdbuf_put

; unassigned key or dead key -> save it, on next keypress,
; scan dead key tables; if nothing found, it's unassigned
@maybe_dead:
	sty dk_scan
	lda tmp2
	sta dk_shift
@skip:	rts

; combine a dead key and a second key,
; handling the special case of unsupported combinations
@combine_dead:
	pha
	jsr find_combination
	bne @found
; can't be combined -> two chars: "^" + "x" = "^x"
	lda #' '
	jsr find_combination
	beq :+
	jsr kbdbuf_put
:	pla
	bra @end
@found:	plx            ; clean up
@end:	stz dk_scan
	jmp kbdbuf_put

; use tables to combine a dead key and a second key
; In:  .A               second key
;      dk_shift/dk_scan dead key
; Out: .Z: =1 found
;          .A: ISO code
find_combination:
	pha
	lda #<deadkeys
	sta ckbtab
	lda #>deadkeys
	sta ckbtab+1
; find dead key's group
@loop1:	lda (ckbtab)
	cmp #$ff
	bne :+
	pla
	lda #0 ; end of groups
	rts
:	ldy #1
	cmp dk_shift
	bne :+
	lda (ckbtab),y
	cmp dk_scan
	beq @found1
:	iny
	lda (ckbtab),y ; skip
	clc
	adc ckbtab
	sta ckbtab
	bcc @loop1
	inc ckbtab+1
	bra @loop1
; find mapping in this group
@found1:
	iny
	lda (ckbtab),y  ; convert group length...
	sbc #3          ; (.C = 1)
	lsr
	tax             ; ...into count
	pla
@loop2:	iny
	cmp (ckbtab),y
	beq @found2
	iny
	dex
	bne @loop2
 ; not found in group
	rts             ; (.Z = 1)
@found2:
	iny
	lda (ckbtab),y  ; (.Z = 0)
	rts

; The caps table has one bit per scancode, indicating whether
; caps + the key should use the shifted or the unshifted table.
handle_caps:
	and #$80 ; remember PETSCII vs. ISO
	pha
	phy ; scancode

	tya
	and #7
	tay
	lda #$80
:	cpy #0
	beq :+
	lsr
	dey
	bra :-
:	tax

	pla ; scancode
	pha
	lsr
	lsr
	lsr
	tay
	txa
	and caps,y
	beq :+
	ply ; scancode
	pla
	ora #MODIFIER_SHIFT
	jmp cont
:	ply ; scancode
	pla
	jmp cont

down_ext:
	cpx #$e1 ; prefix $E1 -> E1-14 = Pause/Break
	beq is_stop
	cmp #$4a ; Numpad /
	beq is_numpad_divide
	cmp #$5a ; Numpad Enter
	beq is_enter
	cpy #$69 ; special case shift+end = help
	beq is_end
	cpy #$6c ; special case shift+home = clr
	beq is_home
	cpy #$2f
	beq is_menu
	cmp #$68
	bcc drv_end
	cmp #$80
	bcs drv_end
	lda tab_extended-$68,y
	bne kbdbuf_put2
drv_end:
	rts

is_numpad_divide:
	lda #'/'
	bra kbdbuf_put2
is_menu:
	lda #$06
	bra kbdbuf_put2

; or $80 if shift is down
is_end:
	ldx #$04 * 2; end (-> help)
	bra :+
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
kbdbuf_put2:
	jmp kbdbuf_put

find_table:
.assert keymap_data = $a000, error; so we can ORA instead of ADC and carry
	sta tmp2
	lda #<keymap_data
	sta ckbtab
	lda #>keymap_data
	sta ckbtab+1
	ldx #TABLE_COUNT
@loop:	lda (ckbtab)
	cmp tmp2
	beq @ret        ; .C = 1: found
	lda ckbtab
	eor #$80
	sta ckbtab
	bmi :+
	inc ckbtab+1
:	dex
	bne @loop
	clc             ; .C = 0: not found
@ret:	rts

;****************************************
; RECEIVE SCANCODE:
; out: X: prefix (E0, E1; 0 = none)
;      A: scancode low (0 = none)
;      C:   0: key down
;           1: key up
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
	jmp (keyhdl)	;Jump to key event handler
receive_scancode_resume:
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
	ora #0
	beq no_key
	jsr joystick_from_ps2
	php
	jsr check_mod
	bcc no_mod
	bit #MODIFIER_TOGGLE_MASK
	beq ntoggle
	plp
	bcs key_up
	eor shflag
	bra mstore
ntoggle:
	plp
	bcc key_down
	eor #$ff
	and shflag
	bra mstore
key_down:
	ora shflag
mstore:	sta shflag
	jsr check_charset_switch
key_up:	lda #0 ; no key to return
	rts
no_mod:	plp
	bcs key_up
no_key:	rts ; original Z is retained

check_mod:
	cpx #$e1
	beq ckmod1
	cmp #$11 ; left alt (0011) or right alt (E011)
	bne nmd_alt
	cpx #$e0 ; right alt
	bne :+
	lda #MODIFIER_ALTGR
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
	cmp #$58 ; caps lock (0058)
	beq md_caps
	cmp #$7e ; scroll lock (007e)
	beq md_4080disp
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
	bra :+
md_caps:
	lda #MODIFIER_CAPS
	bra :+
md_4080disp:
	lda #MODIFIER_4080
:	sec
	rts

tab_extended:
	;         end      lf hom              (END & HOME special cased)
	.byte $00,$00,$00,$9d,$00,$00,$00,$00 ; @$68
	;     ins del  dn      rt  up
	.byte $94,$19,$11,$00,$1d,$91,$00,$00 ; @$70
	;             pgd         pgu brk
	.byte $00,$00,$02,$00,$00,$82,$03,$00 ; @$78

