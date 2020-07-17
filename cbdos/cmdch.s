.export ciout_cmdch, execute_command, set_status, acptr_status

; zeropage.s
.importzp krn_ptr1

; sdcard.s
.import sdcard_init

MAX_CMD_LEN = 40
MAX_STATUS_LEN = 40

.segment "cbdos_data"

cmdbuffer:
	.res MAX_CMD_LEN, 0
statusbuffer:
	.res MAX_STATUS_LEN, 0

cmdbuffer_len:
	.byte 0

status_r:
	.byte 0
status_w:
	.byte 0

.segment "cbdos"

ciout_cmdch:
	ldx cmdbuffer_len
	cpx #MAX_CMD_LEN
	bcs :+ ; ignore characters on overflow
	sta cmdbuffer,x
	inc cmdbuffer_len
:	rts

execute_command:
	lda cmdbuffer_len
	beq @rts ; empty

	lda cmdbuffer
	ldx #0
:	cmp cmds,x
	beq @found
	inx
	cpx #cmds_end - cmds
	bne :-
	jmp set_status_synerr

@found:
	txa
	asl
	tax
	lda cmdptrs + 1,x
	pha
	lda cmdptrs,x
	pha

	stz cmdbuffer_len
@rts:	rts

cmds:
	.byte "IVNRSCU"
cmds_end:

cmdptrs:
	.word cmd_i - 1
	.word cmd_v - 1
	.word cmd_n - 1
	.word cmd_r - 1
	.word cmd_s - 1
	.word cmd_c - 1
	.word cmd_u - 1

cmd_i:
	jsr sdcard_init
	; also check fartitioning, FAT32 header etc.
	jmp set_status_ok ; XXX error handling

cmd_v:
	jmp set_status_writeprot

cmd_n:
	jmp set_status_writeprot

cmd_r:
	jmp set_status_writeprot

cmd_s:
	jmp set_status_writeprot

cmd_c:
	jmp set_status_writeprot

cmd_u:
	lda #$73
	jmp set_status



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
	sta statusbuffer + 1,x
	sta statusbuffer + 2,x
	lda #','
	sta statusbuffer + 3,x
	lda #'0'
	sta statusbuffer + 4,x
	sta statusbuffer + 5,x

	txa
	clc
	adc #6
	sta status_w
	stz status_r
	rts

stcodes:
	.byte $00, $26, $31, $62, $73, $74
stcodes_end:

ststrs:
	.word status_00
	.word status_26
	.word status_31
	.word status_62
	.word status_73
	.word status_74

status_00:
	.byte "OK", 0
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
