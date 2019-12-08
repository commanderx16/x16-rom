.include "../geos/inc/geosmac.inc"
.include "../geos/inc/geossym.inc"
.include "../geos/inc/const.inc"
.include "../geos/inc/jumptab.inc"

.setcpu "65c02"

; from GEOS
.import _ResetHandle

x1L	=r0L
x1H	=r0H
y1L	=r1L
y1H	=r1H
x2L	=r2L
x2H	=r2H
y2L	=r3L
y2H	=r3H

scrmod	=$FF5F

;***************
geos
	jsr bjsrfar
	.word _ResetHandle
	.byte BANK_GEOS

;***************
cscreen
	jsr getbyt
	txa
	sec
	jsr scrmod
	bcc :+
	jmp fcerr
:	rts

;***************
pset:	jsr get_point
	jsr get_col
	pha
	jsr GRAPH_LL_start_direct
	pla
	jmp GRAPH_LL_set_pixel

;***************
line	jsr get_points_col
	lda #0 ; set
	jmp GRAPH_draw_line

;***************
frame	jsr get_points_col
	jmp GRAPH_draw_frame

;***************
rect	jsr get_points_col
	jmp GRAPH_draw_rect

;***************
char	jsr get_point

	jsr chkcom
	jsr getbyt
	txa
	jsr set_col

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
	sbc #<200
	lda poker+1
	sta y1H
	sbc #>200
	bcs linfc
	rts

get_col:
	ldy #0
	lda (txtptr),y
	bne @1
	lda #0
	rts
@1:	jsr chkcom
	jsr getbyt
	txa
	rts

set_col:
	ldx #15 ; secondary color:  light gray
	ldy #1  ; background color: white
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
	sbc #<200
	lda poker+1
	sta y2H
	sbc #>200
	bcs linfc

	jsr get_col
	jmp set_col

@2	jmp snerr
