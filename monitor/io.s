fnlen	:= $1111  ; length of current file name
;sa	:= $1111  ; secondary address
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
	jsr basin_cmp_cr
	beq print_drive_status
	cmp #'$'
print_drive_status:
	jmp print_cr_then_input_loop
LF0BD:
	.byte "I/O ERROR"
