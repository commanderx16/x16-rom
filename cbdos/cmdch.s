;----------------------------------------------------------------------
; CBDOS Command Channel
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.export ciout_cmdch, set_status, acptr_status

; parse.s
.export buffer, buffer_len

; zeropage.s
.importzp krn_ptr1

; sdcard.s
.import sdcard_init

MAX_CMD_LEN = 40
MAX_STATUS_LEN = 40

.segment "cbdos_data"

buffer:
	.res MAX_CMD_LEN, 0
statusbuffer:
	.res MAX_STATUS_LEN, 0

buffer_len:
	.byte 0

status_r:
	.byte 0
status_w:
	.byte 0

.segment "cbdos"

ciout_cmdch:
	ldx buffer_len
	cpx #MAX_CMD_LEN
	bcs :+ ; ignore characters on overflow
	sta buffer,x
	inc buffer_len
:	rts

;---------------------------------------------------------------
set_status_ok:
	lda #$00
	bra set_status
set_status_writeprot:
	lda #$26
	bra set_status
set_status_synerr:
	lda #$31
	bra set_status
set_status_74:
	lda #$74

set_status:
	cmp #1   ; FILES SCRATCHED
	beq @clr_y

	; TODO: preserve X and Y for certain errors
	; "beq @clr_nothing"

	ldx #0
@clr_y:
	ldy #0
@clr_nothing:
	phy
	phx

	pha
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta statusbuffer
	pla
	and #$0f
	ora #$30
	sta statusbuffer + 1
	lda #','
	sta statusbuffer + 2
	pla
	ldx #0
:	cmp stcodes,x
	beq :+
	inx
	cpx #stcodes_end - stcodes
	bne :-
:	txa
	asl
	tax
	lda ststrs,x
	sta krn_ptr1
	lda ststrs + 1,x
	sta krn_ptr1 + 1
	ldx #3
	ldy #0
:	lda (krn_ptr1),y
	beq :+
	sta statusbuffer,x
	iny
	inx
	bne :-
:	lda #','
	sta statusbuffer + 0,x
	pla ; first arg
	jsr bin_to_bcd
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta statusbuffer + 1,x
	pla
	and #$0f
	ora #$30
	sta statusbuffer + 2,x
	lda #','
	sta statusbuffer + 3,x
	pla ; second arg
	jsr bin_to_bcd
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta statusbuffer + 4,x ; XXX Y
	pla
	and #$0f
	ora #$30
	sta statusbuffer + 5,x

	txa
	clc
	adc #6
	sta status_w
	stz status_r
	rts

bin_to_bcd:
	tay
	lda #0
	sed
@loop:	cpy #0
	beq @end
	clc
	adc #1
	dey
	bra @loop
@end:	cld
	rts

stcodes:
	.byte $00, $01, $26, $31, $62, $73, $74
stcodes_end:

ststrs:
	.word status_00
	.word status_01
	.word status_26
	.word status_31
	.word status_62
	.word status_73
	.word status_74

status_00:
	.byte "OK", 0
status_01:
	.byte " FILES SCRATCHED", 0
status_26:
	.byte "WRITE PROTECT ON", 0
status_31:
	.byte "SYNTAX ERROR" ,0
status_62:
	.byte " FILE NOT FOUND" ,0
status_73:
	.byte "CBDOS V1.0 X16", 0
status_74:
	.byte "DRIVE NOT READY", 0

acptr_status:
	ldy status_r
	cpy status_w
	beq @acptr_status_eoi

	lda statusbuffer,y
	inc status_r
	clc ; !eof
	rts

@acptr_status_eoi:
	jsr set_status_ok
	lda #$0d
	sec ; eof
	rts
