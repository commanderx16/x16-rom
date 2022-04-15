readst = $ffb7

fnlen	:= $1111  ; length of current file name
;sa	:= $1111  ; secondary address
fa	:= $1111  ; device number

xmon2 = $1111 ; XXX
loop4 = $1111 ; XXX
insrt = $1111 ; XXX

.feature labels_without_colons

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

LF0BD:	.byte "I/O ERROR"

; ----------------------------------------------------------------
; "@" - send drive command
;	without arguments, this reads the drive status
;	$ shows the directory
; ----------------------------------------------------------------
cmd_at:
	jsr basin_skip_spaces_cmp_cr
	beq ptstat      ;no argument: print status
	ldy #0
:	sta tmp16,y
	iny
	cpy #40
	bne @ok
@err:	jmp syntax_error
@ok:	jsr basin_cmp_cr
	bne :-
@done:	tya
	sta verck       ;save length
	ldx #<tmp16
	ldy #>tmp16
	jsr setnam
	lda tmp16
; dir?
	cmp #'$'
	beq disk_dir
; switch default drive?
	cmp #'8'
	beq dossw
	cmp #'9'
	beq dossw

;***************
; DOS command
	jsr listen_cmd
	ldy #0
:	lda tmp16,y
	jsr iecout
	iny
	cpy verck       ;length?
	bne :-
	jsr unlstn
	jsr crdo
	jmp input_loop

listen_cmd:
	jsr getfa
	jsr listen
	lda #$6f
	jsr second
	jsr readst
	bmi device_not_present
	rts
device_not_present:
	jmp LB3A6


;***************
; print status
ptstat	jsr crdo
	jsr listen_cmd
	jsr unlstn
	jsr getfa
	jsr talk
	lda #$6f
	jsr tksa
dos11	jsr iecin
	jsr bsout
	cmp #13
	bne dos11
	jsr untalk
	jmp input_loop

;***************
; switch default drive
dossw	and #$0f
	sta basic_fa
	rts

getfa:
	lda #8
	cmp basic_fa
	bcs :+
	lda basic_fa
:	rts


;***************
;  read & display the disk directory

LOGADD = 15

disk_dir
	jsr getfa
	tax
	lda #LOGADD     ;la
	ldy #$60        ;sa
	jsr setlfs
	jsr open        ;open directory channel
	jsr readst
	bpl :+
	lda #LOGADD
	jsr close
	jmp device_not_present
:	ldx #LOGADD
	jsr chkin       ;make it an input channel

	jsr crdo

	ldy #4          ;first pass only- trash first four bytes read

@d20
@d25	jsr basin
	jsr readst
	bne disk_done   ;...branch if error
	dey
	bne @d25        ;...loop until done

	jsr basin       ;get # blocks low
	pha
	jsr readst
	tay
	pla
	cpy #0
	bne disk_done   ;...branch if error
	tax
	jsr basin       ;get # blocks high
	pha
	jsr readst
	tay
	pla
	cpy #0
	bne disk_done   ;...branch if error
	jsr linprt      ;print # blocks

	lda #' '
	jsr bsout       ;print space  (to match loaded directory display)

@d30	jsr basin       ;read & print filename & filetype
	beq @d40        ;...branch if eol
	pha
	jsr readst
	tax
	pla
	cpx #0
	bne disk_done   ;...branch if error
	jsr bsout
	bcc @d30        ;...loop always

@d40	jsr crdo        ;start a new line
	jsr stop
	beq disk_done   ;...branch if user hit STOP
	ldy #2
	bne @d20        ;...loop always

disk_done
	jsr clrch
	lda #LOGADD
	sec
	jsr close
	jmp input_loop

crdo:	lda #13
	jmp bsout

linprt:
	rts

basic_fa = $1200
verck = $1202
