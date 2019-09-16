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
.ifdef PS2
	lda shflag
	and #4
	beq mlp42
.else
	lda #$7f        ;check for control key
	sta colm        ;drop line 2 on port b
	lda rows
	cmp #$fb        ;slow scroll key?(control)
	php             ;save status. restore port b
	lda #$7f        ;for stop key check
	sta colm
	plp
	bne mlp42
.endif
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

key	jsr $ffea       ;update jiffy clock
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
.if 0
	eor #$80        ;blink it
.else
	cmp #$9f
	bne :+
	lda gdbln
	.byte $2c
:	lda #$9f
.endif
	jsr dspp2       ;display it
;
key4
	jsr scnkey      ;scan keyboard
;
kprend
.ifdef C64
	lda d1icr       ;clear interupt flags
.else
.if 0 ; VIA#2 timer IRQ for 60 Hz
	lda d1t1l       ;clear interupt flags
.else
	lda #1
	sta veraisr
.endif
.endif
	pla             ;restore registers
	tay
	pla
	tax
	pla
	rti             ;exit from irq routines

; ****** general keyboard scan ******
;
.ifdef PS2
.ifdef C64
port_ddr = 0  ; 6510 data direction register
port_data = 1  ; 6510 data register
;
               ; TAPE PIN A (GND)   <---> PS/2 PIN 3 (GND)  [AT PIN 4]
               ; TAPE PIN B (VCC)   <---> PS/2 PIN 4 (VCC)  [AT PIN 5]
bit_clk  = $08 ; TAPE PIN E (write) <---> PS/2 PIN 5 (CLK)  [AT PIN 1]
bit_data = $10 ; TAPE PIN F (sense) <---> PS/2 PIN 1 (DATA) [AT PIN 2]
.else
port_ddr  =d2ddra
port_data   =d2pra
bit_data=1              ; 6522 IO port data bit mask  (PA0)
bit_clk =2              ; 6522 IO port clock bit mask (PA1)
.endif

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
	lda kbdtab,x
	sta ckbtab
	lda kbdtab + 1,x
	sta ckbtab + 1
	ldx d1prb
	lda #3
	sta d1prb
	lda (ckbtab),y
	stx d1prb
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
	pha
	lda ndx ; length of keyboard buffer
	cmp #10
	bcs add2 ; full, ignore
	inc ndx
	tax
	pla
	sta keyd,x ; store
	cmp #3 ; stop
	bne add1
	lda #$7f
	.byte $2c
add1:	lda #$ff
	sta $91
	rts
add2:	pla
	rts

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
	jsr scancode_to_joystick
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
	bne nmd_alt
xxxx:	cpx #$e0 ; right alt
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

.ifdef C64
tables:
	.word tab_shift-13, tab_alt-13, tab_ctrl-13, tab_alt-13, tab_unshifted

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

tab_alt:
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

tab_ctrl:
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
.endif ; C64

tab_extended:
	;         end      lf hom
	.byte $00,$00,$00,$9d,$00,$00,$00,$00 ; @$68 (HOME is special cased)
	;     ins del  dn      rt  up
	.byte $94,$14,$11,$00,$1d,$91,$00,$00 ; @$70
	;             pgd         pgu brk
	.byte $00,$00,$00,$00,$00,$00,$03,$00 ; @$78

.else
scnkey	lda #$00
	sta shflag
	ldy #64         ;last key index
	sty sfdx        ;null key found
	sta colm        ;raise all lines
	ldx rows        ;check for a key down
	cpx #$ff        ;no keys down?
	beq scnout      ;branch if none
	tay             ;.a=0 ldy #0
	lda #<mode1
	sta keytab
	lda #>mode1
	sta keytab+1
	lda #$fe        ;start with 1st column
	sta colm
scn20	ldx #8          ;8 row keyboard
	pha             ;save column output info
scn22	lda rows
	cmp rows        ;debounce keyboard
	bne scn22
scn30	lsr a           ;look for key down
	bcs ckit        ;none
	pha
	lda (keytab),y  ;get char code
	cmp #$05
	bcs spck2       ;if not special key go on
	cmp #$03        ;could it be a stop key?
	beq spck2       ;branch if so
	ora shflag
	sta shflag      ;put shift bit in flag byte
	bpl ckut
spck2
	sty sfdx        ;save key number
ckut	pla
ckit	iny
	cpy #65
	bcs ckit1       ;branch if finished
	dex
	bne scn30
	sec
	pla             ;reload column info
	rol a
	sta colm        ;next column on keyboard
	bne scn20       ;always branch
ckit1	pla             ;dump column output...all done
	jmp (keylog)    ;evaluate shift functions
rekey	ldy sfdx        ;get key index
	lda (keytab),y   ;get char code
	tax             ;save the char
	cpy lstx        ;same as prev char index?
	beq rpt10       ;yes
	ldy #$10        ;no - reset delay before repeat
	sty delay
	bne ckit2       ;always
rpt10	and #$7f        ;unshift it
	bit rptflg      ;check for repeat disable
	bmi rpt20       ;yes
	bvs scnrts
	cmp #$7f        ;no keys ?
scnout	beq ckit2       ;yes - get out
	cmp #$14        ;an inst/del key ?
	beq rpt20       ;yes - repeat it
	cmp #$20        ;a space key ?
	beq rpt20       ;yes
	cmp #$1d        ;a crsr left/right ?
	beq rpt20       ;yes
	cmp #$11        ;a crsr up/dwn ?
	bne scnrts      ;no - exit
rpt20	ldy delay       ;time to repeat ?
	beq rpt40       ;yes
	dec delay
	bne scnrts
rpt40	dec kount       ;time for next repeat ?
	bne scnrts      ;no
	ldy #4          ;yes - reset ctr
	sty kount
	ldy ndx         ;no repeat if queue full
	dey
	bpl scnrts
ckit2
	ldy sfdx        ;get index of key
	sty lstx        ;save this index to key found
	ldy shflag      ;update shift status
	sty lstshf
ckit3	cpx #$ff        ;a null key or no key ?
	beq scnrts      ;branch if so
	txa             ;need x as index so...
	ldx ndx         ;get # of chars in key queue
	cpx xmax        ;irq buffer full ?
	bcs scnrts      ;yes - no more insert
	sta keyd,x      ;put raw data here
	inx
	stx ndx         ;update key queue count
scnrts	lda #$7f        ;setup pb7 for stop key sense
	sta colm
	rts
;
; shift logic
;
shflog
	lda shflag
	cmp #$03        ;commodore shift combination?
	bne keylg2      ;branch if not
	cmp lstshf      ;did i do this already
	beq scnrts      ;branch if so
	lda mode
	bmi shfout      ;dont shift if its minus

switch
	; XXX TODO: switch upper/lower case character set
	jmp shfout

;
keylg2
	asl a
	cmp #$08        ;was it a control key
	bcc nctrl       ;branch if not
	lda #6          ;else use table #4
;
nctrl
notkat
	tax
	lda keycod,x
	sta keytab
	lda keycod+1,x
	sta keytab+1
shfout
	jmp rekey
.endif

; rsr 12/08/81 modify for vic-40
; rsr  2/18/82 modify for 6526 input pad sense
; rsr  3/11/82 fix keyboard debounce, repair file
; rsr  3/11/82 modify for commodore 64
