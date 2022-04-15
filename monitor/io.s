fnlen	:= $1111  ; length of current file name
sa	:= $1111  ; secondary address
fa	:= $1111  ; device number

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
.import enable_f_keys
.import disable_f_keys
.import store_byte
.import swap_zp1_and_zp2
.import syntax_error
.import tmp16
.importzp zp1
.importzp zp2
.importzp zp3

.import mjsrfar

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
	stz fnlen

	; default
	lda #':'
	sta tmp16
	lda #'*'
	sta tmp16+1
	ldx #<tmp16
	ldy #>tmp16
	lda #2
	jsr setnam
	lda #1
	ldx #8
	ldy #1
	jsr setlfs
	dey
	jsr basin_skip_spaces_cmp_cr
	bne LB3B6
; empty
LB388:	lda command_index
	cmp #<command_index_l
	bne syn_err4
; do the load
LB38F:
	jsr disable_f_keys
	ldx zp1
	ldy zp1 + 1
	jsr LB42D
	php
	jsr enable_f_keys
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
	bne :+
	jsr setnam2
	bra LB388
:	cmp #'"'
	beq LB3CF
	sta tmp16,y
	inc fnlen
	iny
	cpy #$10
	bne LB3BA
syn_err4:
	jmp syntax_error

LB3CF:
	jsr setnam2
	jsr basin_cmp_cr
	beq LB388
	cmp #','
LB3D6:	bne syn_err4
	jsr get_hex_byte
	and #$0F
	beq syn_err4
	cmp #4
	bcc syn_err4 ; illegal device number
	pha
	jsr basin_cmp_cr
	bne @1
	ldy #1 ; sa
	plx
	lda #1 ; la
	jsr setlfs
	bra LB388
@1:	ldy #0 ; sa
	plx
	pha
	lda #1 ; la
	jsr setlfs
	pla
	cmp #','
LB3F0:	bne LB3D6
	jsr get_hex_word3
	jsr swap_zp1_and_zp2
	jsr basin_cmp_cr
	bne LB408
	lda command_index
	cmp #<command_index_l
	bne LB3F0
	jmp LB38F
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
	jsr LB438
	jmp LB3A4

LB42D:
	lda #0
	jmp load

LB438:
	lda #zp1 ; pointer to ZP location with address
	jmp save

setnam2:
	ldx #<tmp16
	ldy #>tmp16
	lda fnlen
	jmp setnam

; ----------------------------------------------------------------
; "@" - send drive command
;	without arguments, this reads the drive status
;	$ shows the directory
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
