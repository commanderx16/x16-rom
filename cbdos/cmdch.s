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
	cmp #0   ; OK
	bne :+
	tax ; has X and Y = 0
	tay
:	cmp #1   ; FILES SCRATCHED
	bne :+
	ldy #0 ; has Y = 0
:

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
	lda #'0'
	sta statusbuffer + 1,x ; XXX X
	sta statusbuffer + 2,x
	lda #','
	sta statusbuffer + 3,x
	lda #'0'
	sta statusbuffer + 4,x ; XXX Y
	sta statusbuffer + 5,x

	txa
	clc
	adc #6
	sta status_w
	stz status_r
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
