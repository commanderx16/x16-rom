; Commander X16 KERNAL
;
; Font library: control characters

.import GRAPH_clear

.export GRAPH_put_char 

set_color:
	sta col1
	clc ; C=0: OK
	rts

;---------------------------------------------------------------
; GRAPH_put_char
;
; Pass:      a   ASCII character
;            r0  x position
;            r1  y position
; Return:    r0  x position (updated)
;            r1  y position (updated)
;            c   1: character outside of bounds, not printed
;---------------------------------------------------------------
GRAPH_put_char:
	; XXX change put_char code so that moving the x/y position
	; XXX around is no longer necessary
	tax
	PushW r2
	PushW r6
	PushW r7
	PushW r11
	PushB r1H
	; move x/y position into correct register
	MoveW r0, r11
	MoveB r1L, r1H
	txa
	jsr put_char
	; copy updated position
	MoveW r11, r0
	MoveB r1H, r1L

	PopB r1H
	PopW r11
	PopW r7
	PopW r6
	PopW r2
	rts
		
put_char:
	cmp #$20
	bcs @1
	asl
	tay
	lda PutCharTab00,y
	ldx PutCharTab00+1,y
	beq set_color
	jsr @callroutine
	clc ; C=0: OK
	rts
@1:	cmp #$80
	bcc @1a
	cmp #$a0
	bcs @1a
	asl
	tay
	lda PutCharTab80,y
	ldx PutCharTab80+1,y
	beq set_color
	jsr @callroutine
	clc ; C=0: OK
	rts

; convert code $FF to $80 (GEOS compat. "logo" char)
@1a:	cmp #$ff
	bne @1b
	lda #$80

@1b:	pha
	ldy r11H
	sty r13H
	ldy r11L
	sty r13L
	ldx currentMode
	jsr get_char_size
	dey
	tya
	add r13L
	sta r13L
	bcc @2
	inc r13H
@2:	CmpW rightMargin, r13
	bcc @5
	CmpW leftMargin, r11
	beq @3
	bcs @4
@3:	pla
	subv $20
	jsr FontPutChar
	clc ; C=0: OK
	rts

; string fault
@4:	lda r13L
	addv 1
	sta r11L
	lda r13H
	adc #0
	sta r11H
@5:	pla
	sec ; C=1: string fault!
	rts

@callroutine:
	sta r13L
	stx r13H
	jmp (r13)

PutCharTab00:
	.word control_nop       ; $00  | NULL
	.word control_swap_col  ; $01  | **SWAP COLORS**
	.word control_nop       ; $02  | -
	.word control_nop       ; $03  | STOP
	.word control_underline ; $04  | **ATTRIBUTES: UNDERLINE**
	.word 1                 ; $05  | COLOR: WHITE
	.word control_bold      ; $06  | **ATTRIBUTES: BOLD**
	.word control_nop       ; $07  | **BELL**
	.word control_backspace ; $08  | **BACKSPACE**
	.word control_tab       ; $09  | **TAB**
	.word control_return2   ; $0A  | **LF**
	.word control_italics   ; $0B  | **ATTRIBUTES: ITALICS**
	.word control_outline   ; $0C  | **ATTRIBUTES: OUTLINE**
	.word control_return    ; $0D  | RETURN
	.word control_nop       ; $0E  | CHARSET: LOWER
	.word control_nop       ; $0F  | **CHARSET: ISO ON/OFF**
	.word control_nop       ; $10  | **F9**
	.word control_down      ; $11  | CURSOR: DOWN
	.word control_reverse   ; $12  | ATTRIBUTES: REVERSE
	.word control_home      ; $13  | HOME
	.word control_backspace ; $14  | DEL/INSERT
	.word control_nop       ; $15  | **F10**
	.word control_nop       ; $16  | **F11**
	.word control_nop       ; $17  | **F12**
	.word control_nop       ; $18  | **SHIFT+TAB**
	.word control_nop       ; $19  | -
	.word control_nop       ; $1A  | -
	.word control_nop       ; $1B  | -
	.word 2                 ; $1C  | COLOR: RED
	.word control_right     ; $1D  | CURSOR: RIGHT
	.word 5                 ; $1E  | COLOR: GREEN
	.word 6                 ; $1F  | COLOR: BLUE

PutCharTab80:
	.word control_nop       ; $80 -
	.word 8                 ; $81 COLOR: ORANGE
	.word control_nop       ; $82 -
	.word control_nop       ; $83 STOP/RUN
	.word control_nop       ; $84 **HELP**
	.word control_nop       ; $85 F1
	.word control_nop       ; $86 F3
	.word control_nop       ; $87 F5
	.word control_nop       ; $88 F7
	.word control_nop       ; $89 F2
	.word control_nop       ; $8A F4
	.word control_nop       ; $8B F6
	.word control_nop       ; $8C F8
	.word control_return    ; $8D REGULAR/SHIFTED RETURN
	.word control_nop       ; $8E CHARSET: LOWER/UPPER CASE
	.word control_nop       ; $8F **CHARSET: ISO ON/OFF**
	.word 0                 ; $90 COLOR: BLACK
	.word control_up        ; $91 CURSOR: DOWN/UP
	.word control_attrclr   ; $92 ATTRIBUTES: CLEAR ALL
	.word control_clear     ; $93 HOME/CLEAR
	.word control_nop       ; $94 DEL/INSERT
	.word 9                 ; $95 COLOR: BROWN
	.word 10                ; $96 COLOR: LIGHT RED
	.word 11                ; $97 COLOR: DARK GRAY
	.word 12                ; $98 COLOR: MIDDLE GRAY
	.word 13                ; $99 COLOR: LIGHT GREEN
	.word 14                ; $9A COLOR: LIGHT BLUE
	.word 15                ; $9B COLOR: LIGHT GRAY
	.word 4                 ; $9C COLOR: PURPLE
	.word control_backspace ; $9D CURSOR: LEFT
	.word 7                 ; $9E COLOR: YELLOW
	.word 3                 ; $9F COLOR: CYAN

control_nop:
	rts

control_swap_col:
	lda col1
	ldx col2
	stx col1
	sta col2
	rts

control_underline:
	smbf UNDERLINE_BIT, currentMode
	rts
	
control_bold:
	smbf BOLD_BIT, currentMode
	rts

control_backspace:
	SubB PrvCharWidth, r11L
	bcs @1
	dec r11H
@1:	PushW r11
	lda #$7f ; = DEL
	jsr FontPutChar
	PopW r11
	rts

control_tab:
	; XXX what should TAB do?
	rts

control_italics:
	smbf ITALIC_BIT, currentMode
	rts

control_outline:
	smbf OUTLINE_BIT, currentMode
	rts

control_return:
	LoadB currentMode, 0 ; clear attributes (like KERNAL)
control_return2:
	MoveW leftMargin, r11
; fallthrough
control_down:
	lda r1H
	sec
	adc curHeight
	sta r1H
	rts

control_reverse:
	smbf REVERSE_BIT, currentMode
	rts

control_clear:
	jsr GRAPH_clear
; fallthrough
control_home:
	MoveW leftMargin, r11
	lda windowTop
	add curHeight
	sta r1H
	rts

control_right:
	lda #' '
	jmp put_char

control_up:
	SubB curHeight, r1H
	rts

control_attrclr:
	LoadB currentMode, 0
	rts
