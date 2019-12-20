;***********************************
;* save                            *
;*                                 *
;* saves to cassette 1 or 2, or    *
;* ieee devices 4>=n>=31 as select-*
;* ed by variable fa.              *
;*                                 *
;*start of save is indirect at .a  *
;*end of save is .x,.y             *
;***********************************

savesp	stx eal
	sty eah
	tax             ;set up start
	lda $00,x
	sta stal
	lda $01,x
	sta stah
;
save	jmp (isave)
nsave	lda fa          ;***monitor entry
	bne sv20
;
sv10	jmp error9      ;bad device #
;
sv20	cmp #3
	beq sv10
	bcc sv10
	lda #$61
	sta sa
	ldy fnlen
	bne sv25
;
	jmp error8      ;missing file name
;
sv25	jsr openi
	jsr saving
	lda fa
	jsr listn
	lda sa
	jsr secnd
	ldy #0
	jsr rd300
	lda sal
	jsr ciout
	lda sah
	jsr ciout
sv30	jsr cmpste      ;compare start to end
	bcs sv50        ;have reached end
	lda (sal),y
	jsr ciout
	jsr stop
	bne sv40
;
break	jsr clsei
	lda #0
	sec
	rts
;
sv40	jsr incsal      ;increment current addr.
	bne sv30
sv50	jsr unlsn

clsei	bit sa
	bmi clsei2
xmon2	lda fa
	jsr listn
	lda sa
	and #$ef
	ora #$e0
	jsr secnd
;
cunlsn	jsr unlsn       ;entry for openi
;
clsei2	clc
sv115	rts

;subroutine to output:
;'saving <file name>'
;
saving	lda msgflg
	bpl sv115       ;no print
;
	ldy #ms11-ms1   ;'saving'
	jsr msg
	jmp outfn       ;<file name>

