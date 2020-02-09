;----------------------------------------------------------------------
; C64 Keyboard Driver
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

.import kbdbuf_put, shflag
.export kbd_config, kbd_scan

cia1	=$dc00                  ;device1 6526 (page1 irq)
d1pra	=cia1+0
d1prb	=cia1+1
d1ddra	=cia1+2
d1ddrb	=cia1+3
colm	=d1pra                  ;keyboard matrix
rows	=d1prb                  ;keyboard matrix

.segment "ZPKERNAL" : zp

keytab	.res 2           ;keyscan table indirect

.segment "KVAR"

lstshf	.res 1           ;last shift pattern
kount	.res 1
rptflg	.res 1           ;key repeat flag
delay	.res 1
lstx	.res 1           ;key scan index
keylog	.res 2           ;indirect for keyboard table setup
sfdx	.res 1           ;shift mode on print

.segment "PS2KBD" ; XXX rename

kbd_config:
	ldx #$00        ;set up keyboard inputs
	stx d1ddrb      ;keyboard inputs
	dex
	stx d1ddra      ;keyboard outputs

	lda #<shflog    ;set shift logic indirects
	sta keylog
	lda #>shflog
	sta keylog+1
	lda #10
	sta delay
	lda #4
	sta kount       ;delay between key repeats
	rts

kbd_scan:
	lda #$00
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
	lda (keytab),y  ;get char code
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
ckit2
	ldy sfdx        ;get index of key
	sty lstx        ;save this index to key found
	ldy shflag      ;update shift status
	sty lstshf
ckit3	cpx #$ff        ;a null key or no key ?
	beq scnrts      ;branch if so
	txa             ;need x as index so...
	jsr kbdbuf_put
scnrts	lda #$7f        ;setup pb7 for stop key sense
	sta colm
	rts

;
; shift logic
;
shflog	lda shflag
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

keycod	;keyboard mode 'dispatch'
	.word mode1
	.word mode2
	.word mode3
	.word contrl    ;control keys

mode1
	.byt $14,$0d,$1d,$88,$85,$86,$87,$11
	.byt $33,$57,$41,$34,$5a,$53,$45,$01
	.byt $35,$52,$44,$36,$43,$46,$54,$58
	.byt $37,$59,$47,$38,$42,$48,$55,$56
	.byt $39,$49,$4a,$30,$4d,$4b,$4f,$4e
	.byt $2b,$50,$4c,$2d,$2e,$3a,$40,$2c
	.byt $5c,$2a,$3b,$13,$01,$3d,$5e,$2f
	.byt $31,$5f,$04,$32,$20,$02,$51,$03
	.byt $ff        ;end of table null

mode2	;shift
	.byt $94,$8d,$9d,$8c,$89,$8a,$8b,$91
	.byt $23,$d7,$c1,$24,$da,$d3,$c5,$01
	.byt $25,$d2,$c4,$26,$c3,$c6,$d4,$d8
	.byt $27,$d9,$c7,$28,$c2,$c8,$d5,$d6
	.byt $29,$c9,$ca,$30,$cd,$cb,$cf,$ce
	.byt $db,$d0,$cc,$dd,$3e,$5b,$ba,$3c
	.byt $a9,$c0,$5d,$93,$01,$3d,$de,$3f
	.byt $21,$5f,$04,$22,$a0,$02,$d1,$83
	.byt $ff        ;end of table null

mode3	;left window grahpics
	.byt $94,$8d,$9d,$8c,$89,$8a,$8b,$91
	.byt $96,$b3,$b0,$97,$ad,$ae,$b1,$01
	.byt $98,$b2,$ac,$99,$bc,$bb,$a3,$bd
	.byt $9a,$b7,$a5,$9b,$bf,$b4,$b8,$be
	.byt $29,$a2,$b5,$30,$a7,$a1,$b9,$aa
	.byt $a6,$af,$b6,$dc,$3e,$5b,$a4,$3c
	.byt $a8,$df,$5d,$93,$01,$3d,$de,$3f
	.byt $81,$5f,$04,$95,$a0,$02,$ab,$83
	.byt $ff        ;end of table null

contrl
	.byt $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byt $1c,$17,$01,$9f,$1a,$13,$05,$ff
	.byt $9c,$12,$04,$1e,$03,$06,$14,$18
	.byt $1f,$19,$07,$9e,$02,$08,$15,$16
	.byt $12,$09,$0a,$92,$0d,$0b,$0f,$0e
	.byt $ff,$10,$0c,$ff,$ff,$1b,$00,$ff
	.byt $1c,$ff,$1d,$ff,$ff,$1f,$1e,$ff
	.byt $90,$06,$ff,$05,$ff,$ff,$11,$ff
	.byt $ff        ;end of table null
