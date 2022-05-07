.include "mac.inc"
.include "regs.inc"

.setcpu "65c02"

x1L	=r0L
x1H	=r0H
y1L	=r1L
y1H	=r1H
x2L	=r2L
x2H	=r2H
y2L	=r3L
y2H	=r3H

;***************
cscreen
	jsr getbytneg
	cpx #$ff
	bne @set
	; Toggle between 40x30 and 80x60
	sec
	jsr screen_mode
	ldx #3
	cmp #3
	bne @set
	ldx #0
@set:	txa
	clc
	jsr screen_mode
	bcc :+
	jmp fcerr
:	rts

;***************
pset:	jsr get_point
	jsr get_col
	pha
	jsr FB_cursor_position
	pla
	jmp FB_set_pixel

;***************
line	jsr get_points_col
	lda #0 ; set
	jmp GRAPH_draw_line

;***************
frame	jsr get_points_col
	jsr convert_point_size
	clc
	jmp GRAPH_draw_rect

;***************
rect	jsr get_points_col
	jsr convert_point_size
	sec
	jmp GRAPH_draw_rect

;***************
char	jsr get_point

	jsr chkcom
	jsr getbyt
	txa
	ldx #15 ; secondary color:  light gray
	ldy #1  ; background color: white
	jsr GRAPH_set_colors

	jsr chkcom
	jsr frmevl
	jsr chkstr

	ldy #0
	lda (facmo),y
	sta r14L ; length
	iny
	lda (facmo),y
	sta r15L ; pointer lo
	iny
	lda (facmo),y
	sta r15H ; pointer hi

	lda #$92 ; Ctrl+0: clear attributes
	jsr GRAPH_put_char

	ldy #0
:	lda (r15),y
	phy
	jsr GRAPH_put_char
	ply
	iny
	cpy r14L
	bne :-

	jmp frefac

linfc	jmp fcerr

get_point:
	jsr frmadr
	lda poker
	sta x1L
	sec
	sbc #<320
	lda poker+1
	sta x1H
	sbc #>320
	bcs linfc
	jsr chkcom
	jsr frmadr
	lda poker
	sta y1L
	sec
	sbc #<240
	lda poker+1
	sta y1H
	sbc #>240
	bcs linfc
	rts

get_col:
	jsr chrgot
	bne @1
	lda #0
	rts
@1:	jsr chkcom
	jsr getbyt
	txa
	rts

set_col:
	tax
	jmp GRAPH_set_colors

get_points_col:
; get x1,y1,x2,y2 into r0,r1,r2,r3
	jsr get_point
	jsr chkcom
	jsr frmadr
	lda poker
	sta x2L
	sec
	sbc #<320
	lda poker+1
	sta x2H
	sbc #>320
	bcs linfc
	jsr chkcom
	jsr frmadr
	lda poker
	sta y2L
	sec
	sbc #<240
	lda poker+1
	sta y2H
	sbc #>240
	bcs linfc

	jsr get_col
	jmp set_col

@2	jmp snerr

convert_point_size:
	; sort x1/x2
	CmpW r0, r2
	bcc :+
	PushW r0
	MoveW r2, r0
	PopW r2
:
	; sort y1/y2
	CmpW r1, r3
	bcc :+
	PushW r1
	MoveW r3, r1
	PopW r3
:
	; convert x2/y2 into width/height
	SubW r0, r2
	IncW r2
	SubW r1, r3
	IncW r3
	rts
