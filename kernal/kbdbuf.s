;----------------------------------------------------------------------
; Keyboard Buffer
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "../banks.inc"
.include "../io.inc"

.export kbdbuf_clear
.export kbdbuf_put
.export kbdbuf_get
.export kbdbuf_peek
.export kbdbuf_remove
.export kbdbuf_get_stop
.export kbdbuf_get_modifiers
.export add_to_buf
.export shflag

.segment "KVARSB0"

keyd:	.res 10          ;    irq keyboard buffer
ndx:	.res 1           ;$C6 index to keyboard q
stkey:	.res 1           ;$91 stop key flag: $ff = stop down
shflag:	.res 1           ;    shift flag byte

.segment "KBDBUF"

kbdbuf_clear:
	KVARS_START
	stz ndx
	KVARS_END
	rts

kbdbuf_put:
	KVARS_START
	phx
	jsr add_to_buf
	plx
	KVARS_END
	rts

;****************************************
; ADD CHAR TO KBD BUFFER
;****************************************
add_to_buf:
	stz stkey
	cmp #3 ; stop
	bne :+
	dec stkey
:	ldx ndx ; length of keyboard buffer
	cpx #10 ;maximum type ahead buffer size
	bcs add2 ; full, ignore
	sta keyd,x ; store
	inc ndx
add2:	rts

kbdbuf_get:
	KVARS_START
	jsr _kbdbuf_get
	KVARS_END
	rts

kbdbuf_remove:
	KVARS_START
	jsr _kbdbuf_remove
	KVARS_END
	rts

_kbdbuf_get:
	lda ndx         ;queue index
	beq lp0         ;nobody there...exit
	sei
;
;remove character from queue
;
_kbdbuf_remove:
	ldy keyd
	ldx #0
:	lda keyd+1,x
	sta keyd,x
	inx
	cpx ndx
	bne :-
	dec ndx
	tya
	cli
lp0:	clc             ;good return
	rts

kbdbuf_peek:
	KVARS_START
	lda ndx
	beq :+
	lda keyd
:	KVARS_END
	rts

kbdbuf_get_stop:
	KVARS_START
	lda stkey	;
	eor #$ff        ;set z if stkey is true
	KVARS_END
	rts

kbdbuf_get_modifiers:
	KVARS_START
	lda shflag
	KVARS_END
	rts
