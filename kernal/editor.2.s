scrsz   =$4000          ;screen ram size, rounded up to power of two
scrmsk  =(>scrsz)-1     ;for masking offset in screen ram

;screen scroll routine
;
scrol	lda sal
	pha
	lda sah
	pha
;
;   s c r o l l   u p
;
scro0	ldx #$ff
	dec tblx
	dec lsxp
	dec lintmp
scr10	inx             ;goto next line
	jsr setpnt      ;point to 'to' line
	cpx nlinesm1    ;done?
	bcs scr41       ;branch if so
;
	lda #0          ;setup from pntr
	sta sal
	lda ldtb1+1,x
	jsr scrlin      ;scroll this line up1
	bmi scr10
;
scr41
	jsr clrln
;
	ldx #0          ;scroll hi byte pointers
scrl5	lda ldtb1,x
	and #$7f
	ldy ldtb1+1,x
	bpl scrl3
	ora #$80
scrl3	sta ldtb1,x
	inx
	cpx nlinesm1
	bne scrl5
;
	ldy nlinesm1
	lda ldtb1,y
	ora #$80
	sta ldtb1,y
	lda ldtb1       ;double line?
	bpl scro0       ;yes...scroll again
;
	inc tblx
	inc lintmp
	lda shflag
	and #4
	beq mlp42
;
	lda #mhz
	ldy #0
mlp4	nop             ;delay
	dex
	bne mlp4
	dey
	bne mlp4
	sec
	sbc #1
	bne mlp4
	sty ndx         ;clear key queue buffer
;
mlp42	ldx tblx
;
pulind	pla             ;restore old indirects
	sta sah
	pla
	sta sal
	rts

newlin
	ldx tblx
bmt1	inx
	lda ldtb1,x     ;find last display line of this line
	bpl bmt1        ;table end mark=>$ff will abort...also
bmt2	stx lintmp      ;found it
;generate a new line
	cpx nlinesm1    ;is one line from bottom?
	beq newlx       ;yes...just clear last
	bcc newlx       ;<nlines...insert line
	jsr scrol       ;scroll everything
	ldx lintmp
	dex
	dec tblx
	jmp wlog30
newlx	lda sal
	pha
	lda sah
	pha
	ldx nlines
scd10	dex
	jsr setpnt      ;set up to addr
	cpx lintmp
	bcc scr40
	beq scr40       ;branch if finished
	lda #0          ;set from addr
	sta sal
	lda ldtb1-1,x
	jsr scrlin      ;scroll this line down
	bmi scd10
scr40
	jsr clrln
	ldx nlinesm2
scrd21
	cpx lintmp      ;done?
	bcc scrd22      ;branch if so
	lda ldtb1+1,x
	and #$7f
	ldy ldtb1,x     ;was it continued
	bpl scrd19      ;branch if so
	ora #$80
scrd19	sta ldtb1+1,x
	dex
	bne scrd21
scrd22
	ldx lintmp
	jsr wlog30
;
	jmp pulind      ;go pul old indirects and return
;
; scroll line from sal to pnt
;
scrlin
	and #scrmsk     ;clear any garbage stuff
	ora hibase      ;put in hiorder bits
	sta sal+1

	;destination into addr1
	lda #$10
	sta verahi
	lda pnt
	sta veralo
	lda pnt+1
	sta veramid

	lda #1
	sta veractl

	;source into addr2
	lda #$10
	sta verahi
	lda sal
	sta veralo
	lda sal+1
	sta veramid

	lda #0
	sta veractl

	ldy llenm1
scd20	lda veradat2    ;character
	sta veradat
	lda veradat2    ;color
	sta veradat
	dey
	bpl scd20
	rts
;
; set up pnt and y
; from .x
;
setpnt	lda #0
	sta pnt
	lda ldtb1,x
	and #scrmsk
	ora hibase
	sta pnt+1
	rts
;
; clear the line pointed to by .x
;
clrln	ldy llen
	jsr setpnt
	lda pnt
	sta veralo      ;set base address
	lda pnt+1
	sta veramid
	lda #$10        ;auto-increment = 1
	sta verahi
clr10	lda #$20
	sta veradat     ;store space
	lda color       ;always clear to current foregnd color
	sta veradat
	dey
	bne clr10
	rts

;
;put a char on the screen
;
dspp	ldy #2
	sty blnct       ;blink cursor
dspp2	ldy pntr
	jsr stapnty
	stx veradat     ;color to screen
	rts

key	jsr scnmse      ;scan mouse (do this first to avoid sprite tearing)
	jsr $ffea       ;update jiffy clock
	lda blnsw       ;blinking crsr ?
	bne key4        ;no
	dec blnct       ;time to blink ?
	bne key4        ;no
	lda #20         ;reset blink counter
repdo	sta blnct
	ldy pntr        ;cursor position
	lsr blnon       ;carry set if original char
	ldx gdcol       ;get char original color
	php
	jsr ldapnty     ;get character
	inc blnon       ;set to 1
	plp
	bcs key5        ;branch if not needed
	sta gdbln       ;save original char
	lda veradat     ;get original color
	sta gdcol       ;save it
	ldx color       ;blink in this color
	lda gdbln       ;with original character
;
key5
	bit isomod
	bpl key3
	cmp #$9f
	bne key2
	lda gdbln
	.byte $2c
key2	lda #$9f
	.byte $2c
key3	eor #$80        ;blink it
	jsr dspp2       ;display it
;
key4
	jsr scnkey      ;scan keyboard
;
kprend
.if 0 ; VIA#2 timer IRQ for 60 Hz
	lda d1t1l       ;clear interupt flags
.else
	lda #1
	sta veraisr
.endif
	ply             ;restore registers
	plx
	pla
	rti             ;exit from irq routines

; ****** general keyboard scan ******
;
port_ddr  =d2ddrb
port_data   =d2prb
bit_data=1              ; 6522 IO port data bit mask  (PA0)
bit_clk =2              ; 6522 IO port clock bit mask (PA1)

MODIFIER_SHIFT = 1 ; C64:  Shift
MODIFIER_ALT   = 2 ; C64:  Commodore
MODIFIER_CTRL  = 4 ; C64:  Ctrl
MODIFIER_WIN   = 8 ; C128: Alt
MODIFIER_CAPS  = 16; C128: Caps

; cycle keyboard layouts
cycle_layout:
	ldx curkbd
	inx
	txa
	jsr setkbd
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
	.byte $2c
is_enter:
	ldx #$0d * 2 ; return (-> shift+return)
	.byte $2c
is_stop:
	ldx #$03 * 2 ; stop (-> run)
	lda shflag
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
	stx stkey
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
	lda port_ddr,x ; set CLK and DATA as input
	and #$ff-bit_clk-bit_data
	sta port_ddr,x ; -> bus is idle, keyboard can start sending

	lda #bit_clk+bit_data
	ldy #10 * mhz
:	dey
	beq lc08c
	bit port_data,x
	bne :- ; wait for CLK=0 and DATA=0 (start bit)

	lda #bit_clk
lc044:	bit port_data,x ; wait for CLK=1 (not ready)
	beq lc044
	ldy #9 ; 9 bits including parity
lc04a:	bit port_data,x
	bne lc04a ; wait for CLK=0 (ready)
	lda port_data,x
	and #bit_data
	cmp #bit_data
	ror kbdbyte ; save bit
	lda #bit_clk
lc058:	bit port_data,x
	beq lc058 ; wait for CLK=1 (not ready)
	dey
	bne lc04a
	rol kbdbyte ; get parity bit into C
lc061:	bit port_data,x
	bne lc061 ; wait for CLK=0 (ready)
lc065:	bit port_data,x
	beq lc065 ; wait for CLK=1 (not ready)
lc069:	jsr ps2dis
	lda kbdbyte
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
	ldy #1 ; Z=0
	rts

lc08c:	jsr ps2dis
	clc
	lda #0 ; Z=1
	rts

kbdis:	ldx #1 ; PA: keybaord
	jsr ps2dis
	dex    ; PB: mouse
ps2dis:	lda port_ddr,x
	ora #bit_clk+bit_data
	sta port_ddr,x ; set CLK and DATA as output
	lda port_data,x
	and #$ff - bit_clk ; CLK=0
	ora #bit_data ; DATA=1
	sta port_data,x
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
	ldx #1
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
	and shflag
	.byte $2c
key_down:
	ora shflag
	sta shflag
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


mouseBtn  = $0780
mouseXPos = $0781
mouseYPos = $0783
mspar     = $0785

mouseLeft = $07c0
mouseRight = $07c2
mouseTop = $07c4
mouseBottom = $07c6
.global scnmse
scnmse:
	lda #0
	sta mouseLeft
	sta mouseLeft+1
	sta mouseTop
	sta mouseTop+1
	lda #<640
	sta mouseRight
	lda #>640
	sta mouseRight+1
	lda #<480
	sta mouseBottom
	lda #>480
	sta mouseBottom+1

	ldx #0
	jsr receive_byte
	bcs scnms1 ; parity error
	bne scnms2 ; no data
scnms1:	rts
scnms2:
.if 0
	; heuristic to test we're not out
	; of sync:
	; * overflow needs to be 0
	; * bit #3 needs to be 1
	; The following codes sent by
	; the mouse will also be skipped
	; by this logic:
	; * $aa: self-test passed
	; * $fa: command acknowledged
	tax
	and #$c8
	cmp #$08
	bne scnms1
	txa
.endif
	sta mouseBtn

	ldx #0
	jsr receive_byte
	clc
	adc mouseXPos
	sta mouseXPos

	lda mouseBtn
	and #$10
	beq :+
	lda #$ff
:	adc mouseXPos+1
	sta mouseXPos+1

	ldx #0
	jsr receive_byte
	clc
	adc mouseYPos
	sta mouseYPos

	lda mouseBtn
	and #$20
	beq :+
	lda #$ff
:	adc mouseYPos+1
	sta mouseYPos+1

; check bounds (from GEOS)
	ldy mouseLeft
	ldx mouseLeft+1
	lda mouseXPos+1
	bmi @2
	cpx mouseXPos+1
	bne @1
	cpy mouseXPos
@1:	bcc @3
	beq @3
@2:	sty mouseXPos
	stx mouseXPos+1
@3:

	ldy mouseRight
	ldx mouseRight+1
	cpx mouseXPos+1
	bne @4
	cpy mouseXPos
@4:	bcs @5
	sty mouseXPos
	stx mouseXPos+1
@5:

	ldy mouseTop
	ldx mouseTop+1
	lda mouseYPos+1
	bmi @2a
	cpx mouseYPos+1
	bne @1a
	cpy mouseYPos
@1a:	bcc @3a
	beq @3a
@2a:	sty mouseYPos
	stx mouseYPos+1
@3a:

	ldy mouseBottom
	ldx mouseBottom+1
	cpx mouseYPos+1
	bne @4a
	cpy mouseYPos
@4a:	bcs @5a
	sty mouseYPos
	stx mouseYPos+1
@5a:

; sprite
	lda mspar
	bpl @s2 ; don't update sprite pos
	ldx #$02
	stx veralo
	ldx #$50
	stx veramid
	ldx #$1F
	stx verahi
	and #$7f
	cmp #2 ; scale
	beq :+
	lda mouseXPos
	ldx mouseXPos+1
	sta veradat
	stx veradat
	lda mouseYPos
	ldx mouseYPos+1
	bra @s1
:	lda mouseXPos+1
	lsr
	tax
	lda mouseXPos
	ror
	sta veradat
	stx veradat
	lda mouseYPos+1
	lsr
	tax
	lda mouseYPos
	ror
@s1:	sta veradat
	stx veradat

@s2:	rts

sprite_addr = $10000 + 320 * 200 ; after background screen

; A: $00 hide mouse
;    n   show mouse, set mouse cursor #n
;    $FF show mouse, don't configure mouse cursor
; X: $00 no-op
;    $01 set scale to 1
;    $02 set scale to 2
mouse:
	cpx #0
	beq mous1
;  set scale
	stx mspar
mous1:	cmp #0
	bne mous2
; hide mouse, disable sprite #0
	lda mspar
	and #$7f
	sta mspar
	lda #$06
	sta veralo
	lda #$50
	sta veramid
	lda #$1F
	sta verahi
	lda #0
	sta veradat
	rts
; show mouse
mous2:	cmp #$ff
	beq mous3
	; we ignore the cursor #, always set std pointer
	lda #<sprite_addr
	sta veralo
	lda #>sprite_addr
	sta veramid
	lda #$10 | (sprite_addr >> 16)
	sta verahi
	ldx #0
@1:	lda #8
	sta 0
	lda mouse_sprite_mask,x
	ldy mouse_sprite_col,x
@2:	asl
	bcs @3
	stz veradat
	pha
	tya
	asl
	tay
	pla
	bra @4
@3:	pha
	tya
	asl
	tay
	bcc @5
	lda #1  ; white
	.byte $2c
@5:	lda #16 ; black
	sta veradat
	pla
@4:	dec 0
	bne @2
	inx
	cpx #32
	bne @1

mous3:	lda mspar
	ora #$80 ; flag: mouse on
	sta mspar
	lda #$00
	sta veralo
	lda #$40
	sta veramid
	lda #$1F
	sta verahi
	lda #1
	sta veradat ; enable sprites

	lda #$00
	sta veralo
	lda #$50
	sta veramid
	lda #<(sprite_addr >> 5)
	sta veradat
	lda #1 << 7 | >(sprite_addr >> 5) ; 8 bpp
	sta veradat
	lda #$06
	sta veralo
	lda #3 << 2 ; z-depth: in front of everything
	sta veradat
	lda #1 << 6 | 1 << 4 ;  16x16 px
	sta veradat
	rts

; This is the Susan Kare mouse pointer
mouse_sprite_col:
.byte %11000000,%00000000
.byte %10100000,%00000000
.byte %10010000,%00000000
.byte %10001000,%00000000
.byte %10000100,%00000000
.byte %10000010,%00000000
.byte %10000001,%00000000
.byte %10000000,%10000000
.byte %10000000,%01000000
.byte %10000011,%11100000
.byte %10010010,%00000000
.byte %10101001,%00000000
.byte %11001001,%00000000
.byte %10000100,%10000000
.byte %00000100,%10000000
.byte %00000011,%10000000
mouse_sprite_mask:
.byte %11000000,%00000000
.byte %11100000,%00000000
.byte %11110000,%00000000
.byte %11111000,%00000000
.byte %11111100,%00000000
.byte %11111110,%00000000
.byte %11111111,%00000000
.byte %11111111,%10000000
.byte %11111111,%11000000
.byte %11111111,%11100000
.byte %11111110,%00000000
.byte %11101111,%00000000
.byte %11001111,%00000000
.byte %10000111,%10000000
.byte %00000111,%10000000
.byte %00000011,%10000000

tab_extended:
	;         end      lf hom
	.byte $00,$00,$00,$9d,$00,$00,$00,$00 ; @$68 (HOME is special cased)
	;     ins del  dn      rt  up
	.byte $94,$14,$11,$00,$1d,$91,$00,$00 ; @$70
	;             pgd         pgu brk
	.byte $00,$00,$00,$00,$00,$00,$03,$00 ; @$78

; rsr 12/08/81 modify for vic-40
; rsr  2/18/82 modify for 6526 input pad sense
; rsr  3/11/82 fix keyboard debounce, repair file
; rsr  3/11/82 modify for commodore 64
