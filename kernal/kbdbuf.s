;----------------------------------------------------------------------
; Keyboard Buffer
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "../banks.inc"
.include "../io.inc"
.include "../mac.inc"

.export kbdbuf_clear
.export kbdbuf_put
.export kbdbuf_get
.export kbdbuf_get_stop
.export kbdbuf_get_modifiers
.export shflag

KBDBUF_SIZE = 10

.segment "KVARSB0"

keyd:	.res KBDBUF_SIZE ;    keyboard buffer
ndx:	.res 1           ;$C6 index to keyboard q
stkey:	.res 1           ;$91 stop key flag: $ff = stop down
shflag:	.res 1           ;    shift flag byte

.segment "KBDBUF"

kbdbuf_clear:
	KVARS_START
	lda #0
	sta ndx
	KVARS_END
	rts

kbdbuf_get:
	KVARS_START
	lda ndx         ;queue index
	beq @1          ;nobody there...exit
	php
	sei
	ldy keyd
	ldx #0
:	lda keyd+1,x
	sta keyd,x
	inx
	cpx ndx
	bne :-
	dec ndx
	plp
	tya
@1:	clc             ;good return
	KVARS_END
	rts

; XXX make API
kbdbuf_put:
	KVARS_START
	stx stkey
	ldx ndx    ; length of keyboard buffer
	cpx #KBDBUF_SIZE
	bcs :+     ; full, ignore
	sta keyd,x ; store
	inc ndx
:	ldx stkey
	pha
	cmp #3 ; stop
	bne @1
	lda #$ff
	bra @2
@1:	lda #0
@2:	sta stkey
	pla
	KVARS_END
	rts

kbdbuf_get_stop:
	KVARS_START
	lda stkey
	eor #$ff        ;set z if stkey is true
	KVARS_END
	rts

; XXX make API
kbdbuf_get_modifiers:
	KVARS_START
	lda shflag
	KVARS_END
	rts
