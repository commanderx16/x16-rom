
test:
	lda #$80
	sec
	jsr screen_set_mode
	jsr test1_hline
	jsr test2_vline
	jsr test3_bresenham
	jsr test4_set_get_pixels
	jsr test5_filter_pixels
	jsr test6_frame
	jsr test7_rect
	jsr test8_varlen_hline
	jsr test9_varlen_vline
	jsr test10_put_char
	jsr test11_char_size
	jsr test12_char_styles
	jsr test13_move_rect
	jsr test14_image
	jsr checksum_framebuffer
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
	jsr FB_cursor_position
	ldx #0
:	phx
	txa
	jsr FB_set_pixel
	plx
	inx
	bne :-

	; get direct pixels
	LoadW r0, 5
	LoadW r1, 23
	jsr FB_cursor_position
	LoadB r1H, 1; "OK"
	ldx #0
:	phx
	jsr FB_get_pixel
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
	jsr FB_cursor_position
	ldx #0
:	phx
	txa
	jsr FB_set_pixel
	plx
	inx
	bne :-

	; filter pixels
	LoadW r0, 5
	LoadW r1, 25
	jsr FB_cursor_position
	LoadW $70, $49 ; EOR #
	LoadW $71, $55 ;      $55
	LoadW $72, $60 ; RTS
	LoadW r0, 256
	LoadW r1, $70
	jsr FB_filter_pixels

	; check filter result using direct read
	LoadW r0, 5
	LoadW r1, 25
	jsr FB_cursor_position
	LoadB r1H, 1; "OK"
	ldx #0
:	phx
	jsr FB_get_pixel
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
	; frame frame
	lda #11
	jsr GRAPH_set_colors
	LoadW r0, 100
	LoadW r1, 20
	LoadW r2, 10
	LoadW r3, 10
	clc
	jmp GRAPH_draw_rect

test7_rect:
	; rectangle frame
	lda #11
	ldx #5
	jsr GRAPH_set_colors
	LoadW r0, 111
	LoadW r1, 20
	LoadW r2, 10
	LoadW r3, 10
	sec
	jmp GRAPH_draw_rect

test8_varlen_hline:
	lda #15
	jsr GRAPH_set_colors
	LoadW r0, 5
	LoadW r1, 41
	LoadW r2, 5
	LoadW r3, 41
:	lda #0 ; set
	jsr GRAPH_draw_line
	IncW r1 ; y++
	IncW r3 ; y++
	lda r2L
	clc
	adc #11
	sta r2L
	lda r2H
	adc #0
	sta r2H
	cmp #>318
	bcc :-
	lda r2L
	cmp #<318
	bcc :-
	rts

test9_varlen_vline:
	lda #0
	jsr GRAPH_set_colors
	LoadW r0, 5
	LoadW r1, 71
	LoadW r2, 5
	LoadW r3, 71
:	lda #0 ; set
	jsr GRAPH_draw_line
	IncW r0 ; x++
	IncW r2 ; x++
	lda r3L
	clc
	adc #11
	sta r3L
	lda r3H
	adc #0
	sta r3H
	cmp #>198
	bcc :-
	lda r3L
	cmp #<198
	bcc :-
	rts
	
test10_put_char:
	lda #2
	jsr GRAPH_set_colors

	LoadW r0, 25
	LoadW r1, 80
	LoadW r2, 255
	LoadW r3, 15
	jsr GRAPH_set_window
	clc
	jsr GRAPH_draw_rect

	AddVW 5, r1 ; add baseline -2
	
	lda #$20
:	jsr GRAPH_set_colors
	pha
	jsr GRAPH_put_char
	pla
	bcc @1
	pha
	lda #10 ; LF
	jsr GRAPH_put_char
	pla
	dec
@1:	inc
	cmp #$7f
	bne :-
	rts

test11_char_size:
	LoadW r0, 25
	LoadW r1, 100
	LoadW r2, 255
	LoadW r3, 20
	jsr GRAPH_set_window
	clc
	jsr GRAPH_draw_rect

	AddVW 7, r1 ; add baseline

	lda #$20
:	tax
	jsr GRAPH_set_colors

	; draw bounding box
	pha
	tax
	PushW r0
	PushW r1
	txa
	ldx #0; mode
	jsr GRAPH_get_char_size
	sta 0 ; baseline
	PopW r1
	PopW r0

	PushW r1
	; y -= baseline
	lda r1L
	sec
	sbc 0; baseline
	sta r1L
	lda r1H
	sbc #0
	sta r1H

	stx r2L
	stz r2H

	sty r3L
	stz r3H

	sec
	jsr GRAPH_draw_rect
	PopW r1

	lda #0
	jsr GRAPH_set_colors

	pla
	pha
	jsr GRAPH_put_char
	pla
	bcc @1
	pha
	lda #10 ; LF
	jsr GRAPH_put_char
	pla
	dec
@1:	inc
	cmp #$7f
	beq :+
	jmp :-
:	rts

test12_char_styles:
	lda #0
	ldx #4
	jsr GRAPH_set_colors

	LoadW r0, 20
	LoadW r1, 125
	LoadW r2, 295
	LoadW r3, 74
	jsr GRAPH_set_window
	clc
	jsr GRAPH_draw_rect

	AddVW 7, r1 ; add baseline

	ldy #0
	
@loop:	phy
	lda #$92 ; attributes off
	jsr GRAPH_put_char
	ply
	phy
	tya
	ldx #0
@2:	lsr
	bcc @1
	pha
	lda style_codes,x
	phx
	jsr GRAPH_put_char
	plx
	pla
@1:	inx
	cpx #5
	bne @2
	LoadW 0, test_string
	jsr print_string
	ply
	iny
	cpy #32
	bne @loop

	lda #$92 ; attributes off
	jmp GRAPH_put_char
	
test_string:
	.byte "abcABC123", 0
	
style_codes:
	.byte $04 ; underline
	.byte $06 ; bold
	.byte $0b ; italics
	.byte $0c ; outline
	.byte $12 ; reverse

test13_move_rect:
	LoadW r0, 100
	LoadW r1, 100
	LoadW r2, 320-40
	LoadW r3, 10
	LoadW r4, 40
	LoadW r5, 50
	jmp GRAPH_move_rect

test14_image:
	ldx #0
:	lda image_data,x
	sta $0400,x
	inx
	bne :-

	LoadW r0, 50
	LoadW r1, 6
	LoadW r2, $0400
	LoadW r3, 16
	LoadW r4, 16
	
	ldx #10
:	phx
	jsr GRAPH_draw_image
	AddVW 20, r0
	plx
	dex
	bne :-
	rts

image_data:
.byte $14,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$91
.byte $cb,$16,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$ca,$e8
.byte $ae,$b1,$af,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$ae,$b0,$af
.byte $91,$b8,$b8,$b6,$91,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$b6,$b8,$b8,$91
.byte $c9,$b7,$b9,$b9,$b8,$91,$c9,$c9,$c9,$c9,$c9,$b7,$b9,$b9,$b8,$c9
.byte $c9,$92,$9d,$9d,$9d,$9c,$ae,$c9,$c9,$b5,$b8,$9d,$9d,$9d,$9b,$c9
.byte $c9,$91,$9c,$95,$9d,$9d,$9d,$ae,$c9,$9c,$9d,$9d,$95,$95,$b6,$c9
.byte $c9,$c9,$91,$ae,$92,$9b,$9c,$9a,$91,$9c,$9b,$9a,$ae,$b5,$c9,$c9
.byte $c9,$c9,$c9,$c9,$c9,$91,$80,$99,$91,$80,$99,$c9,$c9,$c9,$c9,$c9
.byte $c9,$c9,$c9,$c9,$5a,$63,$64,$5a,$91,$64,$63,$3e,$91,$c9,$c9,$c9
.byte $c9,$c9,$3e,$48,$48,$48,$48,$15,$c9,$47,$48,$48,$48,$46,$c9,$c9
.byte $c9,$c9,$47,$49,$49,$48,$14,$c9,$c9,$91,$48,$49,$49,$48,$c9,$c9
.byte $c9,$c9,$08,$50,$08,$15,$c9,$c9,$c9,$c9,$14,$47,$50,$50,$14,$c9
.byte $c9,$e5,$08,$2c,$e5,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$2b,$2d,$22,$c9
.byte $c9,$e5,$2b,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$2a,$2a,$c9
.byte $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9


checksum_framebuffer:
	lda #$ff
	sta crclo
	sta crchi
	
	ldx #0
@loop:	LoadW r0, 0
	stx r1L
	stz r1H
	phx
	jsr FB_cursor_position

	ldx #>320
	ldy #<320
@loop2:	phy
	phx
	jsr FB_get_pixel
	jsr crc16_f
	plx
	ply
	dey
	bne @loop2
	dex
	bpl @loop2
	
	plx
	inx
	cpx #200
	bne @loop

	lda #0
	tax
	jsr GRAPH_set_colors

	LoadW r0, 295
	LoadW r1, 190
	LoadW r2, 24
	LoadW r3, 9
	jsr GRAPH_set_window
	sec
	jsr GRAPH_draw_rect

	AddVW 7, r1 ; add baseline

	lda #1
	jsr GRAPH_set_colors

	lda crchi
	lsr
	lsr
	lsr
	lsr
	tax
	lda hextab,x
	nop
	jsr GRAPH_put_char

	lda crchi
	and #15
	tax
	lda hextab,x
	nop
	jsr GRAPH_put_char

	lda crclo
	lsr
	lsr
	lsr
	lsr
	tax
	lda hextab,x
	nop
	jsr GRAPH_put_char

	lda crclo
	and #15
	tax
	lda hextab,x
	nop
	jsr GRAPH_put_char

	rts

hextab:
	.byte "0123456789ABCDEF"

; http://www.6502.org/source/integers/crc-more.html
crclo	=0              ; current value of CRC
crchi	=1              ; not necessarily contiguous

crc16_f:
	eor crchi       ; A contained the data
	sta crchi       ; XOR it into high byte
	lsr             ; right shift A 4 bits
	lsr             ; to make top of x^12 term
	lsr             ; ($1...)
	lsr
	tax             ; save it
	asl             ; then make top of x^5 term
	eor crclo       ; and XOR that with low byte
	sta crclo       ; and save
	txa             ; restore partial term
	eor crchi       ; and update high byte
	sta crchi       ; and save
	asl             ; left shift three
	asl             ; the rest of the terms
	asl             ; have feedback from x^12
	tax             ; save bottom of x^12
	asl             ; left shift two more
	asl             ; watch the carry flag
	eor crchi       ; bottom of x^5 ($..2.)
	tay             ; save high byte
	txa             ; fetch temp value
	rol             ; bottom of x^12, middle of x^5!
	eor crclo       ; finally update low byte
	sta crchi       ; then swap high and low bytes
	sty crclo
	rts



print_string:
	ldy #0
:	lda (0),y
	beq :+
	phy
	jsr GRAPH_put_char

	bcc @1
	lda #10 ; LF
	jsr GRAPH_put_char
	ply
	bra :-
@1:
	ply
	iny
	bne :-
:	rts

str_OK:
	.byte "OK", 0
str_BAD:
	.byte "BAD", 0

