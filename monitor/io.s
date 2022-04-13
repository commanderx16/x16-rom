;status	:= $1111  ; kernal I/O status
fnlen	:= $1111  ; length of current file name
la	:= $1111  ; logical file number
sa	:= $1111  ; secondary address
fa	:= $1111  ; device number
fnadr	:= ($11)  ; file name

xmon2 = $1111 ; XXX
loop4 = $1111 ; XXX
insrt = $1111 ; XXX

.include "kernal.i"

.import LBC4C
.import basin_cmp_cr
.import basin_if_more
.import basin_skip_spaces_cmp_cr
.import basin_skip_spaces_if_more
.import command_index
.importzp command_index_l
.importzp command_index_s
.import get_hex_byte
.import get_hex_byte2
.import get_hex_word3
.import input_loop
.import input_loop2
.import load_byte
.import print_cr
.import print_cr_then_input_loop
.import set_irq_vector
.import store_byte
.import swap_zp1_and_zp2
.import syntax_error
.import tmp16
.importzp zp1
.importzp zp2
.importzp zp3

.import mjsrfar

.export cmd_p
.export cmd_asterisk
.export cmd_at
.export cmd_ls

.segment "monitor"

listen_command_channel:
	lda #$6F
	jsr init_and_listen
	lda status
	bmi LB3A6
	rts

; ----------------------------------------------------------------
; "L"/"S" - load/save file
; ----------------------------------------------------------------
cmd_ls:
	ldy #>tmp16
	sty fnadr + 1
	dey
	sty sa  ; = 1
	dey
	sty fnlen  ; = 1
	lda #8
	sta fa
	lda #<tmp16
	sta fnadr
	jsr basin_skip_spaces_cmp_cr
	bne LB3B6
LB388:	lda command_index
	cmp #<command_index_l
	bne syn_err4
LB38F:
	jsr set_irq_vector
	ldx zp1
	ldy zp1 + 1
	jsr LB42D
	php
	jsr set_irq_vector
	plp
LB3A4:	bcc LB3B3
LB3A6:	ldx #0
LB3A8:	lda LF0BD,x ; "I/O ERROR"
	jsr bsout
	inx
	cpx #10
	bne LB3A8
LB3B3:	jmp input_loop

LB3B6:	cmp #'"'
	bne syn_err4
LB3BA:	jsr basin_cmp_cr
	beq LB388
	cmp #'"'
	beq LB3CF
	sta (fnadr),y
	inc fnlen
	iny
	cpy #$10
	bne LB3BA
syn_err4:
	jmp syntax_error

LB3CF:	jsr basin_cmp_cr
	beq LB388
	cmp #','
LB3D6:	bne syn_err4
	jsr get_hex_byte
	and #$0F
	beq syn_err4
	cmp #1 ; tape
	beq LB3E7
	cmp #4
	bcc syn_err4 ; illegal device number
LB3E7:	sta fa
	jsr basin_cmp_cr
	beq LB388
	cmp #','
LB3F0:	bne LB3D6
	jsr get_hex_word3
	jsr swap_zp1_and_zp2
	jsr basin_cmp_cr
	bne LB408
	lda command_index
	cmp #<command_index_l
	bne LB3F0
	dec sa
	beq LB38F
LB408:	cmp #','
LB40A:	bne LB3F0
	jsr get_hex_word3
	jsr basin_skip_spaces_cmp_cr
	bne LB40A
	ldx zp2
	ldy zp2 + 1
	lda command_index
	cmp #<command_index_s
	bne LB40A
	dec sa
	jsr LB438
	jmp LB3A4

LB42D:
	lda #0
	jmp load

LB438:
	lda #zp1 ; pointer to ZP location with address
	jmp save

; ----------------------------------------------------------------
; "@" - send drive command
;	without arguments, this reads the drive status
;	$ shows the directory
;	F does a fast format
; ----------------------------------------------------------------
cmd_at:
	jsr listen_command_channel
	jsr basin_cmp_cr
	beq print_drive_status
	cmp #'$'
	beq LB475
LB458:	jsr iecout
	jsr basin_cmp_cr
	bne LB458
	jsr unlstn
	jmp print_cr_then_input_loop

; just print drive status
print_drive_status:
	jsr print_cr
	jsr unlstn
	jsr talk_cmd_channel
	jsr cat_line_iec
	jmp input_loop

; show directory
LB475:	jsr unlstn
	jsr print_cr
	lda #$F0 ; sec address
	jsr init_and_listen
	lda #'$'
	jsr iecout
	jsr unlstn
	jsr directory
	jmp input_loop

syn_err7:
	jmp  syntax_error

; ----------------------------------------------------------------
; "*R"/"*W" - read/write sector
; ----------------------------------------------------------------
cmd_asterisk:
	jsr listen_command_channel
	jsr unlstn
	jsr basin
	cmp #'W'
	beq LBAA0
	cmp #'R'
	bne syn_err7
LBAA0:	sta zp2 ; save 'R'/'W' mode
	jsr basin_skip_spaces_if_more
	jsr get_hex_byte2
	bcc syn_err7
	sta zp1
	jsr basin_if_more
	jsr get_hex_byte
	bcc syn_err7
	sta zp1 + 1
	jsr basin_cmp_cr
	bne LBAC1
	lda #>$CF00 ; default address
	sta zp2 + 1
	bne LBACD
LBAC1:	jsr get_hex_byte
	bcc syn_err7
	sta zp2 + 1
	jsr basin_cmp_cr
	bne syn_err7
LBACD:	jsr LBB48
	jsr swap_zp1_and_zp2
	lda zp1
	cmp #'W'
	beq LBB25
	lda #'1' ; U1: read
	jsr read_write_block
	jsr talk_cmd_channel
	jsr iecin
	cmp #'0'
	beq LBB00 ; no error
	pha
	jsr print_cr
	pla
LBAED:	jsr LE716 ; KERNAL: output character to screen
	jsr iecin
	cmp #CR ; print drive status until CR (XXX redundant?)
	bne LBAED
	jsr untalk
	jsr close_2
	jmp input_loop

LBB00:	jsr iecin
	cmp #CR ; receive all bytes (XXX not necessary?)
	bne LBB00
	jsr untalk
	jsr send_bp
	ldx #2
	jsr chkin
	ldy #0
	sty zp1
LBB16:	jsr iecin
	jsr store_byte ; receive block
	iny
	bne LBB16
	jsr clrch
	jmp LBB42 ; close 2 and print drive status

LBB25:	jsr send_bp
	ldx #2
	jsr ckout
	ldy #0
	sty zp1
LBB31:	jsr load_byte
	jsr iecout ; send block
	iny
	bne LBB31
	jsr clrch
	lda #'2' ; U2: write
	jsr read_write_block
LBB42:	jsr close_2
	jmp print_drive_status

LBB48:	lda #2
	tay
	ldx fa
	jsr setlfs
	lda #1
	ldx #<s_hash
	ldy #>s_hash
	jsr setnam
	jmp open

close_2:
	lda #2
	jmp close

to_dec:
	ldx #'0'
	sec
LBB64:	sbc #10
	bcc LBB6B
	inx
	bcs LBB64
LBB6B:	adc #'9' + 1
	rts

read_write_block:
	pha
	ldx #0
LBB71:	lda s_u1,x
	sta BUF,x
	inx
	cpx #s_u1_end - s_u1
	bne LBB71
	pla
	sta BUF + 1
	lda zp2 ; track
	jsr to_dec
	stx BUF + s_u1_end - s_u1 + 0
	sta BUF + s_u1_end - s_u1 + 1
	lda #' '
	sta BUF + s_u1_end - s_u1 + 2
	lda zp2 + 1 ; sector
	jsr to_dec
	stx BUF + s_u1_end - s_u1 + 3
	sta BUF + s_u1_end - s_u1 + 4
	jsr listen_command_channel
	ldx #0
LBBA0:	lda BUF,x
	jsr iecout
	inx
	cpx #s_u1_end - s_u1 + 5
	bne LBBA0
	jmp unlstn

send_bp:
	jsr listen_command_channel
	ldx #0
LBBB3:	lda s_bp,x
	jsr iecout
	inx
	cpx #s_bp_end - s_bp
	bne LBBB3
	jmp unlstn

s_u1:
	.byte "U1:2 0 "
s_u1_end:
s_bp:
	.byte "B-P 2 0"
s_bp_end:

s_hash:
	.byte "#"

send_m_dash2:
	pha
	lda #$6F
	jsr init_and_listen
	lda #'M'
	jsr iecout
	lda #'-'
	jsr iecout
	pla
	jmp iecout

iec_send_zp1_plus_y:
	tya
	clc
	adc zp1
	php
	jsr iecout
	plp
	lda zp1 + 1
	adc #0
	jmp iecout

syn_err8:
	jmp syntax_error

; ----------------------------------------------------------------
; "P" - set output to printer
; ----------------------------------------------------------------
cmd_p:
	ldx #$FF
	lda fa
	cmp #4
	beq LBC11 ; printer
	jsr basin_cmp_cr
	beq LBC16 ; no argument
	cmp #','
	bne syn_err8
	jsr get_hex_byte
	tax
LBC11:	jsr basin_cmp_cr
	bne syn_err8
LBC16:
	jsr kbdbuf_put
	lda #4
	cmp fa
	beq LBC39 ; printer
	stx sa
	sta fa ; set device 4
	sta la
	ldx #0
	stx fnlen
	jsr close
	jsr open
	ldx la
	jsr ckout
	jmp input_loop2

LBC39:	lda la
	jsr close
	jsr clrch
	lda #8
	sta fa
	jsr kbdbuf_clear
	jmp input_loop

kbdbuf_clear:
	jsr getin
	bne kbdbuf_clear
	rts

init_and_listen:
	pha
	jsr init_drive
	jsr listen
	pla
	jmp second

talk_cmd_channel:
	lda #$6F
init_and_talk:
	pha
	jsr init_drive
	jsr talk
	pla
	jmp tksa

cat_line_iec:
	jsr iecin
	jsr LE716 ; KERNAL: output character to screen
	cmp #CR
	bne cat_line_iec
	jmp untalk

directory:
	lda #$60
	sta sa
	jsr init_and_talk
	jsr iecin
	jsr iecin ; skip load address
LBCDF:	jsr iecin
	jsr iecin ; skip link word
	jsr iecin
	tax
	jsr iecin ; line number (=blocks)
	ldy status
	bne LBD2F ; error
	jsr LBC4C ; print A/X decimal
	lda #' '
	jsr LE716 ; KERNAL: output character to screen
	ldx #$18
LBCFA:	jsr iecin
LBCFD:	ldy status
	bne LBD2F ; error
	cmp #CR
	beq LBD09 ; convert $0D to $1F
	cmp #$8D
	bne LBD0B ; also convert $8D to $1F
LBD09:	lda #$1F ; ???BLUE
LBD0B:	jsr LE716 ; KERNAL: output character to screen
	inc insrt
	jsr getin
	cmp #KEY_STOP
	beq LBD2F
	cmp #' '
	bne LBD20
LBD1B:	jsr getin
	beq LBD1B ; space pauses until the next key press
LBD20:	dex
	bpl LBCFA
	jsr iecin
	bne LBCFD
	lda #CR
	jsr LE716 ; KERNAL: output character to screen
LBD2D:	bne LBCDF ; next line
LBD2F:	jmp LF646 ; CLOSE

init_drive:
	lda #0
	sta status ; clear status
	lda #8
	cmp fa ; drive 8 and above ok
	bcc LBD3F
LBD3C:	sta fa ; otherwise set drive 8
LBD3E:	rts

LBD3F:	lda #9
	cmp fa
	bcs LBD3E
	lda #8
LBD47:
	bne LBD3C
	lda zp3 ; XXX ???
LBD4B:	ldy status
	bne LBD7D
	cmp #CR
	beq LBD57
	cmp #$8D
	bne LBD59
LBD57:	lda #$1F
LBD59:	jsr LE716 ; KERNAL: output character to screen
	inc insrt
	jsr getin
	cmp #KEY_STOP
	beq LBD7D
	cmp #$20
	bne LBD6E
LBD69:	jsr getin
	beq LBD69
LBD6E:	dex
	bpl LBD47 + 1 ; ??? XXX
	jsr iecin
	bne LBD4B
	lda #CR
	jsr LE716 ; KERNAL: output character to screen
	bne LBD2D
LBD7D:	jmp LF646 ; CLOSE

	lda #0
	sta status
	lda #8
	cmp fa
	bcc LBD8D
LBD8A:	sta fa
LBD8C:	rts

LBD8D:	lda #9
	cmp fa
	bcs LBD8C
	lda #8
	bne LBD8A ; always

; XXX unused
LAF2B:	lda #'E' ; send M-E to drive
	jsr send_m_dash2
	lda zp2
	jsr iecout
	lda zp2 + 1
	jsr iecout
	jsr unlstn
	jmp print_cr_then_input_loop

LF646:
	jsr mjsrfar
	.word xmon2 ; IEC close
	.byte BANK_KERNAL
	rts

LE716:
	jsr mjsrfar
	.word loop4 ; screen CHROUT
	.byte BANK_KERNAL
	rts

LF0BD:
	.byte "I/O ERROR"
