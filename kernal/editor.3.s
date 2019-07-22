mode1
; $00-$0f
.byte $00,$00,$00,135,134,133,137,$00,$00,$00,140,139,$00,$00,$00,$00
; $10-$1f
.byte $00,$00,$00,$00,$00,'Q','1',$00,$00,$00,'Z','S','A','W','2',$00
; $20-$2f
.byte $00,'C','X','D','E','4','3',$00,$00,' ','V','F','T','R','5',$00
; $30-$3f
.byte $00,'N','B','H','G','Y','6',$00,$00,$00,'M','J','U','7','8',$00
; $40-$4f
.byte $00,',','K','I','O','0','9',$00,$00,'.','/','L',';','P','-',$00
; $50-$5f
.byte $00,$00,$27,$00,'[','=',$00,$00,$00,$00,$0d,']',$00,'\',$00,$00
; $60-$6f
.byte $00,$00,$00,$00,$00,$00,$14,$00,$00,$00,$00,$00,$00,$00,$00,$00
; $70-$7f
.byte $00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00
; $80-$8f
.byte $00,$00,$00,136,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
;                 ^___this is F7! - all other F keys are in the first row!

mode2	;shift
; $00-$0f
.byte $00,$00,$00,135,134,133,137,$00,$00,$00,140,139,$00,$00,$00,$00
; $10-$1f
.byte $00,$00,$00,$00,$00,'Q'+$80,'!',$00,$00,$00,'Z'+$80,'S'+$80,'A'+$80,'W'+$80,'@',$00
; $20-$2f
.byte $00,'C'+$80,'X'+$80,'D'+$80,'E'+$80,'$','#',$00,$00,' ','V'+$80,'F'+$80,'T'+$80,'R'+$80,'%',$00
; $30-$3f
.byte $00,'N'+$80,'B'+$80,'H'+$80,'G'+$80,'Y'+$80,'^',$00,$00,$00,'M'+$80,'J'+$80,'U'+$80,'&','*',$00
; $40-$4f
.byte $00,',','K'+$80,'I'+$80,'O'+$80,')','(',$00,$00,'.','?','L'+$80,':','P'+$80,'_',$00
; $50-$5f
.byte $00,$00,'"',$00,'{','+',$00,$00,$00,$00,$8d,'}',$00,'|',$00,$00
; $60-$6f
.byte $00,$00,$00,$00,$00,$00,$94,$00,$00,$00,$00,$00,$00,$00,$00,$00
; $70-$7f
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; $80-$8f
.byte $00,$00,$00,136,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

mode3	;left window grahpics
; $00-$0f
.byte $00,$00,$00,135,134,133,137,$00,$00,$00,140,139,$00,$00,$00,$00
; $10-$1f
.byte $00,$00,$00,$00,$00,171,129,$00,$00,$00,173,174,176,179,149,$00
; $20-$2f
.byte $00,188,189,172,177,151,150,$00,$00,160,190,187,163,178,152,$00
; $30-$3f
.byte $00,170,191,180,165,183,153,$00,$00,$00,167,181,184,154,155,$00
; $40-$4f
.byte $00, 60,161,162,185, 48, 41,$00,$00, 62, 63,182, 93,175,220,$00
; $50-$5f
.byte $00,$00, 55,$00, 58, 61,$00,$00,$00,$00,141, 59,$00,222,$00,$00
; $60-$6f
.byte $00,$00,$00,$00,$00,$00,148,$00,$00,$00,$00,$00,$00,$00,$00,$00
; $70-$7f
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; $80-$8f
.byte $00,$00,$00,136,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

contrl
; $00-$0f
.byte $00,$00,$00,135,134,133,137,$00,$00,$00,140,139,$00,$00,$00,$00
; $10-$1f
.byte $00,$00,$00,$00,$00,'Q'-$40,144,$00,$00,$00,'Z'-$40,'S'-$40,'A'-$40,'W'-$40,  5,$00
; $20-$2f
.byte $00,'C'-$40,'X'-$40,'D'-$40,'E'-$40,159, 28,$00,$00,' ','V'-$40,'F'-$40,'T'-$40,'R'-$40,156,$00
; $30-$3f
.byte $00,'N'-$40,'B'-$40,'H'-$40,'G'-$40,'Y'-$40, 30,$00,$00,$00,'M'-$40,'J'-$40,'U'-$40, 31,158,$00
; $40-$4f
.byte $00,',','K'-$40,'I'-$40,'O'-$40,146, 18,$00,$00,'.','/','L'-$40, 29,'P'-$40,'-',$00
; $50-$5f
.byte $00,$00, 31,$00, 27, 31,$00,$00,$00,$00,$0d,']',$00, 30,$00,$00
; $60-$6f
.byte $00,$00,$00,$00,$00,$00,$14,$00,$00,$00,$00,$00,$00,$00,$00,$00
; $70-$7f
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; $80-$8f
.byte $00,$00,$00,136,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

lower
	cmp #$0e        ;does he want lower case?
	bne upper       ;branch if not
	; XXX TODO switch video to lower case
	jmp outhre

upper
	cmp #$8e        ;does he want upper case
	bne lock        ;branch if not
	; XXX TODO switch video to upper/pet set
outhre	jmp loop2

lock
	cmp #8          ;does he want to lock in this mode?
	bne unlock      ;branch if not
	lda #$80        ;else set lock switch on
	ora mode        ;don't hurt anything - just in case
	bmi lexit

unlock
	cmp #9          ;does he want to unlock the keyboard?
	bne outhre      ;branch if not
	lda #$7f        ;clear the lock switch
	and mode        ;dont hurt anything
lexit	sta mode
	jmp loop2       ;get out

;
runtb	.byt "LOAD",$d,"RUN",$d
;
linz0	= vicscn
linz1	= linz0+llen*2
linz2	= linz1+llen*2
linz3	= linz2+llen*2
linz4	= linz3+llen*2
linz5	= linz4+llen*2
linz6	= linz5+llen*2
linz7	= linz6+llen*2
linz8	= linz7+llen*2
linz9	= linz8+llen*2
linz10	= linz9+llen*2
linz11	= linz10+llen*2
linz12	= linz11+llen*2
linz13	= linz12+llen*2
linz14	= linz13+llen*2
linz15	= linz14+llen*2
linz16	= linz15+llen*2
linz17	= linz16+llen*2
linz18	= linz17+llen*2
linz19	= linz18+llen*2
linz20	= linz19+llen*2
linz21	= linz20+llen*2
linz22	= linz21+llen*2
linz23	= linz22+llen*2
linz24	= linz23+llen*2
linz25	= linz24+llen*2
linz26	= linz25+llen*2
linz27	= linz26+llen*2
linz28	= linz27+llen*2
linz29	= linz28+llen*2
linz30	= linz29+llen*2
linz31	= linz30+llen*2
linz32	= linz31+llen*2
linz33	= linz32+llen*2
linz34	= linz33+llen*2
linz35	= linz34+llen*2
linz36	= linz35+llen*2
linz37	= linz36+llen*2
linz38	= linz37+llen*2
linz39	= linz38+llen*2
linz40	= linz39+llen*2
linz41	= linz40+llen*2
linz42	= linz41+llen*2
linz43	= linz42+llen*2
linz44	= linz43+llen*2
linz45	= linz44+llen*2
linz46	= linz45+llen*2
linz47	= linz46+llen*2
linz48	= linz47+llen*2
linz49	= linz48+llen*2
linz50	= linz49+llen*2
linz51	= linz50+llen*2
linz52	= linz51+llen*2
linz53	= linz52+llen*2
linz54	= linz53+llen*2
linz55	= linz54+llen*2
linz56	= linz55+llen*2
linz57	= linz56+llen*2
linz58	= linz57+llen*2
linz59	= linz58+llen*2

;****** screen lines lo byte table ******
;
ldtb2
	.byte <linz0
	.byte <linz1
	.byte <linz2
	.byte <linz3
	.byte <linz4
	.byte <linz5
	.byte <linz6
	.byte <linz7
	.byte <linz8
	.byte <linz9
	.byte <linz10
	.byte <linz11
	.byte <linz12
	.byte <linz13
	.byte <linz14
	.byte <linz15
	.byte <linz16
	.byte <linz17
	.byte <linz18
	.byte <linz19
	.byte <linz20
	.byte <linz21
	.byte <linz22
	.byte <linz23
	.byte <linz24
	.byte <linz25
	.byte <linz26
	.byte <linz27
	.byte <linz28
	.byte <linz29
	.byte <linz30
	.byte <linz31
	.byte <linz32
	.byte <linz33
	.byte <linz34
	.byte <linz35
	.byte <linz36
	.byte <linz37
	.byte <linz38
	.byte <linz39
	.byte <linz40
	.byte <linz41
	.byte <linz42
	.byte <linz43
	.byte <linz44
	.byte <linz45
	.byte <linz46
	.byte <linz47
	.byte <linz48
	.byte <linz49
	.byte <linz50
	.byte <linz51
	.byte <linz52
	.byte <linz53
	.byte <linz54
	.byte <linz55
	.byte <linz56
	.byte <linz57
	.byte <linz58
	.byte <linz59

; rsr 12/08/81 modify for vic-40 keyscan
; rsr  2/17/81 modify for the stinking 6526r2 chip
; rsr  3/11/82 modify for commodore 64
; rsr  3/28/82 modify for new pla
