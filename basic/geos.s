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
.if 1
	jmp tests
.else
	jsr bjsrfar
	.word _ResetHandle
	.byte BANK_GEOS
.endif

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
	jsr GRAPH_start_direct
	pla
	jmp GRAPH_set_pixel

;***************
line	jsr get_points_col
	lda #0 ; set
	jmp GRAPH_draw_line

;***************
frame	jsr get_points_col
	jsr normalize_rect
	jmp GRAPH_draw_frame

;***************
rect	jsr get_points_col
	jsr normalize_rect
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

normalize_rect:
; make sure y2 >= y1
	lda y2L
	cmp y1L
	bcs @1
	ldx y1L
	stx y2L
	sta y1L
; make sure x2 >= x1
@1:	lda x2L
	sec
	sbc x1L
	lda x2H
	sbc x1H
	bcs @2
	lda x1L
	ldx x2L
	stx x1L
	sta x2L
	lda x1H
	ldx x2H
	stx x1H
	sta x2H
@2:	rts


GRAPH_set_window     = $FF1B ; TODO
GRAPH_set_options    = $FF1E ; TODO
GRAPH_set_colors     = $FF21
GRAPH_start_direct   = $FF24
GRAPH_set_pixel      = $FF27
GRAPH_get_pixel      = $FF2A
GRAPH_filter_pixels  = $FF2D
GRAPH_draw_line      = $FF30
GRAPH_draw_frame     = $FF33
GRAPH_draw_rect      = $FF36
GRAPH_move_rect      = $FF39
GRAPH_set_font       = $FF3C
GRAPH_get_char_size  = $FF3F
GRAPH_put_char       = $FF42

tests:
	lda #$80
	sec
	jsr scrmod

	jsr test1_hline
	jsr test2_vline
	jsr test3_bresenham
	jsr test4_set_get_pixels
	jsr test5_filter_pixels
	jsr test6_frame
	jsr test7_rect
	rts
	
test1_hline:
	; horizontal line
	lda #0
	jsr GRAPH_set_colors
	LoadW r0, 1
	LoadW r1, 2
	LoadW r2, 318
	LoadW r3, 2
	lda #0 ; set
	jsr GRAPH_draw_line

	; horizontal line - reversed
	lda #2
	jsr GRAPH_set_colors
	LoadW r0, 318
	LoadW r1, 4
	LoadW r2, 1
	LoadW r3, 4
	lda #0 ; set
	jsr GRAPH_draw_line

test2_vline:
	; vertical line
	lda #3
	jsr GRAPH_set_colors
	LoadW r0, 1
	LoadW r1, 6
	LoadW r2, 1
	LoadW r3, 198
	lda #0 ; set
	jsr GRAPH_draw_line

	; vertical line - reversed
	lda #4
	jsr GRAPH_set_colors
	LoadW r0, 3
	LoadW r1, 198
	LoadW r2, 3
	LoadW r3, 6
	lda #0 ; set
	jmp GRAPH_draw_line

test3_bresenham:
	; Bresenham line TL->BR
	lda #5
	jsr GRAPH_set_colors
	LoadW r0, 5
	LoadW r1, 7
	LoadW r2, 10
	LoadW r3, 9
	lda #0 ; set
	jsr GRAPH_draw_line

	; Bresenham line BL->TR
	lda #6
	jsr GRAPH_set_colors
	LoadW r0, 5
	LoadW r1, 13
	LoadW r2, 10
	LoadW r3, 11
	lda #0 ; set
	jsr GRAPH_draw_line

	; Bresenham line BR->TL
	lda #7
	jsr GRAPH_set_colors
	LoadW r0, 10
	LoadW r1, 17
	LoadW r2, 5
	LoadW r3, 15
	lda #0 ; set
	jsr GRAPH_draw_line

	; Bresenham line TR->BL
	lda #8
	jsr GRAPH_set_colors
	LoadW r0, 10
	LoadW r1, 19
	LoadW r2, 5
	LoadW r3, 21
	lda #0 ; set
	jsr GRAPH_draw_line

test4_set_get_pixels:
	; set direct pixels
	LoadW r0, 5
	LoadW r1, 23
	jsr GRAPH_start_direct
	ldx #0
:	phx
	txa
	jsr GRAPH_set_pixel
	plx
	inx
	bne :-

	; get direct pixels
	LoadW r0, 5
	LoadW r1, 23
	jsr GRAPH_start_direct
	LoadB r1H, 1; "OK"
	ldx #0
:	phx
	jsr GRAPH_get_pixel
	plx
	sta r0L
	cpx r0L
	beq @1
	stz r1H ; "BAD"
@1:	inx
	bne :-

	; print result of comparison
	lda r1H
	bne @2
	LoadW 0, str_BAD
	bra @3
@2:	LoadW 0, str_OK
@3:	lda #9
	jsr GRAPH_set_colors
	LoadW r0, 263
	LoadW r1, 22
	jmp print_string

test5_filter_pixels:
	; set direct pixels
	LoadW r0, 5
	LoadW r1, 25
	jsr GRAPH_start_direct
	ldx #0
:	phx
	txa
	jsr GRAPH_set_pixel
	plx
	inx
	bne :-

	; filter pixels
	LoadW r0, 5
	LoadW r1, 25
	jsr GRAPH_start_direct
	LoadW $70, $49 ; EOR #
	LoadW $71, $55 ;      $55
	LoadW $72, $60 ; RTS
	LoadW r0, 256
	LoadW r1, $70
	jsr GRAPH_filter_pixels

	; check filter result using direct read
	LoadW r0, 5
	LoadW r1, 25
	jsr GRAPH_start_direct
	LoadB r1H, 1; "OK"
	ldx #0
:	phx
	jsr GRAPH_get_pixel
	plx
	eor #$55
	sta r0L
	cpx r0L
	beq @4
	stz r1H ; "BAD"
@4:	inx
	bne :-

	; print result of comparison
	lda r1H
	bne @2a
	LoadW 0, str_BAD
	bra @3a
@2a:	LoadW 0, str_OK
@3a:	lda #10
	jsr GRAPH_set_colors
	LoadW r0, 263
	LoadW r1, 32
	jmp print_string

test6_frame:
	; frame frame TL->BR
	lda #11
	jsr GRAPH_set_colors
	LoadW r0, 5
	LoadW r1, 27
	LoadW r2, 10
	LoadW r3, 32
	jsr GRAPH_draw_frame

	; frame frame BL->TR
	lda #12
	jsr GRAPH_set_colors
	LoadW r0, 12
	LoadW r1, 32
	LoadW r2, 17
	LoadW r3, 27
	jsr GRAPH_draw_frame

	; frame frame BR->TL
	lda #13
	jsr GRAPH_set_colors
	LoadW r0, 24
	LoadW r1, 32
	LoadW r2, 19
	LoadW r3, 27
	jsr GRAPH_draw_frame

	; frame frame TR->BL
	lda #14
	jsr GRAPH_set_colors
	LoadW r0, 31
	LoadW r1, 27
	LoadW r2, 26
	LoadW r3, 32
	jmp GRAPH_draw_frame

test7_rect:
	; rectangle frame TL->BR
	lda #11
	jsr GRAPH_set_colors
	LoadW r0, 5
	LoadW r1, 34
	LoadW r2, 10
	LoadW r3, 39
	jsr GRAPH_draw_rect

	; rectangle frame BL->TR
	lda #12
	jsr GRAPH_set_colors
	LoadW r0, 12
	LoadW r1, 39
	LoadW r2, 17
	LoadW r3, 34
	jsr GRAPH_draw_rect

	; rectangle frame BR->TL
	lda #13
	jsr GRAPH_set_colors
	LoadW r0, 24
	LoadW r1, 39
	LoadW r2, 19
	LoadW r3, 34
	jsr GRAPH_draw_rect

	; rectangle frame TR->BL
	lda #14
	jsr GRAPH_set_colors
	LoadW r0, 31
	LoadW r1, 34
	LoadW r2, 26
	LoadW r3, 39
	jmp GRAPH_draw_rect



print_string:
	ldy #0
:	lda (0),y
	beq :+
	phy
	jsr GRAPH_put_char
	ply
	iny
	bne :-
:	rts

str_OK:
	.byte "OK", 0
str_BAD:
	.byte "BAD", 0
