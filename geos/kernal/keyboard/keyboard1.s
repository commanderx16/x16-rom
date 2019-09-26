; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; C64/C128 keyboard driver

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.import KbdTab2
.import KbdTab1
.import KbdScanHelp6
.import KbdDecodeTab1
.import KbdDecodeTab2
.import KbdDMltTab
.import KbdDBncTab
.import KbdTestTab
.import KbdScanHelp5
.import KbdScanHelp2
.import KbdNextKey
.import KbdQueFlag
.import BitMaskPow2

.global _DoKeyboardScan

.segment "keyboard1"

.if 0
_DoKeyboardScan:
.ifdef wheels_screensaver
.import ScreenSaver1
	jsr     ScreenSaver1
	bcs @5
.endif
.ifdef bsw128
	PushB clkreg
	LoadB clkreg, 0
.endif
	lda KbdQueFlag
	bne @1
	lda KbdNextKey
	jsr KbdScanHelp2
.ifdef wheels
	sec
	lda keyRptCount
	sbc keyAccel
	bcc @X
	cmp minKeyRepeat
	bcc @X
	asl keyAccel
	bcc @Y
@X:	lda minKeyRepeat
@Y:	sta KbdQueFlag
.else
	LoadB KbdQueFlag, 15
.endif
@1:	LoadB r1H, 0
.ifdef wheels
        ldy     #$FF
        sty     cia1base+2
        iny
        sty     cia1base+3
.endif
	jsr KbdScanRow
	bne @5
	jsr KbdScanHelp5
.ifdef bsw128
	ldy #10
.else
	ldy #7
.endif
@2:	jsr KbdScanRow
	bne @5
.ifdef bsw128
	cpy #8
	bcc @X
	lda KbdTestTab-8,y
	sta keyreg
	bne @Z
@X:
.endif
	lda KbdTestTab,y
	sta cia1base+0
@Z:	lda cia1base+1
	cmp KbdDBncTab,y
	sta KbdDBncTab,y
	bne @4
	cmp KbdDMltTab,y
	beq @4
	pha
	eor KbdDMltTab,y
	beq @3
	jsr KbdScanHelp1
@3:	pla
	sta KbdDMltTab,y
@4:	dey
	bpl @2
@5:
.ifdef bsw128
	PopB clkreg
.endif
	rts

.ifdef wheels_screensaver
.global KbdScanAll
KbdScanAll:
	lda #$00
	.byte $2c
.endif
KbdScanRow:
	LoadB cia1base+0, $ff
.ifdef bsw128
	LoadB $D02F, $ff
.endif
	CmpBI cia1base+1, $ff
	rts

KbdScanHelp1:
	sta r0L
	LoadB r1L, 7
@1:	lda r0L
	ldx r1L
	and BitMaskPow2,x
.if .defined(bsw128) || .defined(wheels)
	beq @X
	jsr @Y
@X:	dec r1L
	bpl @1
	rts
.else
	beq @A	; really dirty trick...
.endif
@Y:	tya
	asl
	asl
	asl
	adc r1L
	tax
	bbrf 7, r1H, @2
	lda KbdDecodeTab2,x
	bra @3
@2:	lda KbdDecodeTab1,x
@3:	sta r0H
.ifdef bsw128
	lda CPU_DATA
	and #%01000000
	bne @XX
	lda r0H
	jsr KbdScanHelp6
	sta r0H
@XX:	lda r1H
	and #$20
	beq @4
.else
	bbrf 5, r1H, @4
.endif
	lda r0H
	jsr KbdScanHelp6
	cmp #'A'
	bcc @4
	cmp #'Z'+1
	bcs @4
	subv $40
	sta r0H
@4:	bbrf 6, r1H, @5
	smbf_ 7, r0H
@5:	lda r0H
	sty r0H
	ldy #8
@6:	cmp KbdTab1,y
	beq @7
	dey
	bpl @6
	bmi @8
@7:	lda KbdTab2,y
@8:	ldy r0H
	sta r0H
	and #%01111111
	cmp #%00011111
	beq @9
	ldx r1L
	lda r0L
	and BitMaskPow2,x
	and KbdDMltTab,y
.ifdef wheels
	beq @9
	lda keyRptCount
	sta KbdQueFlag
	lda keyAccFlag
	sta keyAccel
	lda r0H
	sta keyScanChar
	jmp KbdScanHelp2
@9:	lda #$FF
	sta KbdQueFlag
	lda #0
	sta keyScanChar
	rts
.else
	beq @9
	LoadB KbdQueFlag, 15
	MoveB r0H, KbdNextKey
.ifdef bsw128
	jmp KbdScanHelp2
.else
	jsr KbdScanHelp2
	bra @A
.endif
@9:	LoadB KbdQueFlag, $ff
	LoadB KbdNextKey, 0
.ifndef bsw128
@A:	dec r1L
	bmi @B
	jmp @1
@B:
.endif
	rts
.endif

.else ; X16
_DoKeyboardScan:
.if 1
	rts
.else
mhz = 8

; ****** general keyboard scan ******
;
via2	=$9f70                  ;VIA 6522 #2
d2pra	=via2+1
d2ddra	=via2+3

port_ddr  =d2ddra
port_data   =d2pra
bit_data=1              ; 6522 IO port data bit mask  (PA0)
bit_clk =2              ; 6522 IO port clock bit mask (PA1)

kbdtmp     = $fa ; and $fb
kbdbyte    = $fc ; zero page
prefix     = $fd
break_flag = $fe
shflag2    = $ff
MODIFIER_SHIFT = 1 ; C64:  Shift
MODIFIER_ALT   = 2 ; C64:  Commodore
MODIFIER_CTRL  = 4 ; C64:  Ctrl
MODIFIER_WIN   = 8 ; C128: Alt
MODIFIER_CAPS  = 16; C128: Caps

	jsr receive_down_scancode_no_modifiers
	beq drv_end

	tay

	cpx #0
	bne down_ext
; *** regular scancodes
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
	ldx #3 * 2
	bne bit_found ; use unshifted table

not_numpad:
	ldx #0
	lda shflag2
find_bit:
	lsr
	bcs bit_found
	inx
	inx
	cpx #3 * 2
	bne find_bit

bit_found:
	lda tables,x
	sta kbdtmp
	lda tables + 1,x
	sta kbdtmp + 1
	lda (kbdtmp),y
drv2:	beq drv_end
	jmp add_to_buf

down_ext:
.if 0 ; disabled to save space
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
.endif
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
	lda #$ea
	jmp KbdScanHelp2

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
	rol break_flag ; set to 1
	bne receive_scancode ; always
rcvsc5:	pha
	lsr break_flag ; break bit into C
	ldx prefix
	lda #0
	sta prefix
	sta break_flag
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
	beq md_alt
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

tables:
	.word tab_shift-13, tab_alt-13, tab_ctrl-13, tab_unshifted

tab_unshifted:
	.byte $00,$00,$88,$87,$86,$85,$89,$00
	.byte $00,$00,$8c,$8b,$8a

	.byte                     $09,'_',$00
	.byte $00,$00,$00,$00,$00,'Q','1',$00
	.byte $00,$00,'Z','S','A','W','2',$00
	.byte $00,'C','X','D','E','4','3',$00
	.byte $00,' ','V','F','T','R','5',$00
	.byte $00,'N','B','H','G','Y','6',$00
	.byte $00,$00,'M','J','U','7','8',$00
	.byte $00,',','K','I','O','0','9',$00
	.byte $00,'.','/','L',';','P','-',$00
	.byte $00,$00,$27,$00,'[','=',$00,$00
	.byte $00,$00,$0d,']',$00,'\',$00,$00
	.byte $00,$00,$00,$00,$00,$00,$14,$00

	.byte $00,'1',$00,'4','7',$00,$00,$00
	.byte '0','.','2','5','6','8',$1b,$00
	.byte $00,'+','3','-','*','9',$00,$00

tab_shift:
.if 0
	.byte                     $18,$7e,$00
	.byte $00,$00,$00,$00,$00,'Q'+$80,'!',$00,$00
	.byte $00,'Z'+$80,'S'+$80,'A'+$80,'W'+$80,'@',$00
	.byte $00,'C'+$80,'X'+$80,'D'+$80,'E'+$80,'$','#',$00
	.byte $00,$a0,'V'+$80,'F'+$80,'T'+$80,'R'+$80,'%',$00
	.byte $00,'N'+$80,'B'+$80,'H'+$80,'G'+$80,'Y'+$80,'^',$00
	.byte $00,$00,'M'+$80,'J'+$80,'U'+$80,'&','*',$00
	.byte $00,'<','K'+$80,'I'+$80,'O'+$80,')','(',$00
	.byte $00,'>','?','L'+$80,':','P'+$80,$DD,$00
	.byte $00,$00,'"',$00,'{','+',$00,$00
	.byte $00,$00,$8d,'}',$00,$a9,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$94,$00
.endif

tab_alt:
.if 0
	.byte                     $18,$7e,$00
	.byte $00,$00,$00,$00,$00,$ab,$81,$00
	.byte $00,$00,$ad,$ae,$b0,$b3,$95,$00
	.byte $00,$bc,$bd,$ac,$b1,$97,$96,$00
	.byte $00,$a0,$be,$bb,$a3,$b2,$98,$00
	.byte $00,$aa,$bf,$b4,$a5,$b7,$99,$00
	.byte $00,$00,$a7,$b5,$b8,$9a,$9b,$00
	.byte $00,$3c,$a1,$a2,$b9,$30,$29,$00
	.byte $00,$3e,$3f,$b6,':',$af,$dc,$00
	.byte $00,$00,'"',$00,$00,$3d,$00,$00
	.byte $00,$00,$8d,$00,$00,$a8,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$94,$00
.endif

tab_ctrl:
.if 0
	.byte                     $18,$06,$00
	.byte $00,$00,$00,$00,$00,$11,$90,$00
	.byte $00,$00,$1a,$13,$01,$17,$05,$00
	.byte $00,$03,$18,$04,$05,$9f,$1c,$00
	.byte $00,$00,$16,$06,$14,$12,$9c,$00
	.byte $00,$0e,$02,$08,$07,$19,$1e,$00
	.byte $00,$00,$0d,$0a,$15,$1f,$9e,$00
	.byte $00,$00,$0b,$09,$0f,$92,$12,$00
	.byte $00,$00,$00,$0c,$1d,$10,$00,$00
	.byte $00,$00,$00,$00,$00,$1f,$00,$00
	.byte $00,$00,$00,$00,$00,$1c,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
.endif

tab_extended:
	;         end      lf hom
	.byte $00,$00,$00,$9d,$00,$00,$00,$00 ; @$68 (HOME is special cased)
	;     ins del  dn      rt  up
	.byte $94,$14,$11,$00,$1d,$91,$00,$00 ; @$70
	;             pgd         pgu brk
	.byte $00,$00,$00,$00,$00,$00,$03,$00 ; @$78


.endif
.endif
