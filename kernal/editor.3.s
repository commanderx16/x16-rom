.ifndef PS2
keycod	;keyboard mode 'dispatch'
	.word mode1
	.word mode2
	.word mode3
	.word contrl    ;control keys

mode1
;del,3,5,7,9,+,yen sign,1
	.byt $14,$0d,$1d,$88,$85,$86,$87,$11
;return,w,r,y,i,p,*,left arrow
	.byt $33,$57,$41,$34,$5a,$53,$45,$01
;rt crsr,a,d,g,j,l,;,ctrl
	.byt $35,$52,$44,$36,$43,$46,$54,$58
;f4,4,6,8,0,-,home,2
	.byt $37,$59,$47,$38,$42,$48,$55,$56
;f1,z,c,b,m,.,r.shiftt,space
	.byt $39,$49,$4a,$30,$4d,$4b,$4f,$4e
;f2,s,f,h,k,:,=,com.key
	.byt $2b,$50,$4c,$2d,$2e,$3a,$40,$2c
;f3,e,t,u,o,@,exp,q
	.byt $5c,$2a,$3b,$13,$01,$3d,$5e,$2f
;crsr dwn,l.shift,x,v,n,,,/,stop
	.byt $31,$5f,$04,$32,$20,$02,$51,$03
	.byt $ff        ;end of table null

mode2	;shift
;ins,%,',),+,yen,!
	.byt $94,$8d,$9d,$8c,$89,$8a,$8b,$91
;sreturn,w,r,y,i,p,*,sleft arrow
	.byt $23,$d7,$c1,$24,$da,$d3,$c5,$01
;lf.crsr,a,d,g,j,l,;,ctrl
	.byt $25,$d2,$c4,$26,$c3,$c6,$d4,$d8
;,$,&,(,      ,"
	.byt $27,$d9,$c7,$28,$c2,$c8,$d5,$d6
;f5,z,c,b,m,.,r.shift,sspace
	.byt $29,$c9,$ca,$30,$cd,$cb,$cf,$ce
;f6,s,f,h,k,:,=,scom.key
	.byt $db,$d0,$cc,$dd,$3e,$5b,$ba,$3c
;f7,e,t,u,o,@,pi,g
	.byt $a9,$c0,$5d,$93,$01,$3d,$de,$3f
;crsr dwn,l.shift,x,v,n,,,/,run
	.byt $21,$5f,$04,$22,$a0,$02,$d1,$83
	.byt $ff        ;end of table null
;
mode3	;left window grahpics
;ins,c10,c12,c14,9,+,pound sign,c8
	.byt $94,$8d,$9d,$8c,$89,$8a,$8b,$91
;return,w,r,y,i,p,*,lft.arrow
	.byt $96,$b3,$b0,$97,$ad,$ae,$b1,$01
;lf.crsr,a,d,g,j,l,;,ctrl
	.byt $98,$b2,$ac,$99,$bc,$bb,$a3,$bd
;f8,c11,c13,c15,0,-,home,c9
	.byt $9a,$b7,$a5,$9b,$bf,$b4,$b8,$be
;f2,z,c,b,m,.,r.shift,space
	.byt $29,$a2,$b5,$30,$a7,$a1,$b9,$aa
;f4,s,f,h,k,:,=,com.key
	.byt $a6,$af,$b6,$dc,$3e,$5b,$a4,$3c
;f6,e,t,u,o,@,pi,q
	.byt $a8,$df,$5d,$93,$01,$3d,$de,$3f
;crsr.up,l.shift,x,v,n,,,/,stop
	.byt $81,$5f,$04,$95,$a0,$02,$ab,$83
	.byt $ff        ;end of table null
.endif

lower
	cmp #$0e        ;does he want lower case?
	bne upper       ;branch if not
	jsr lowup
	lda veradat
	ora #8 >> 2
	bne ulset

upper
	cmp #$8e        ;does he want upper case
	bne lock        ;branch if not
	jsr lowup
	lda veradat
	and #$ff-(8 >> 2)
ulset	sta veradat
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

; access VERA register TILE_BASE_HI
lowup	lda #$04        ;$40000: layer 1 registers
	sta verahi
	lda #0
	sta veramid
	lda #5          ;reg 5: TILE_BASE_HI
	sta veralo
	rts

.ifndef PS2
contrl
;null,red,purple,blue,rvs ,null,null,black
	.byt $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
;null, w  ,reverse, y  , i  , p  ,null,music
	.byt $1c,$17,$01,$9f,$1a,$13,$05,$ff
	.byt $9c,$12,$04,$1e,$03,$06,$14,$18
;null,cyan,green,yellow,rvs off,null,null,white
	.byt $1f,$19,$07,$9e,$02,$08,$15,$16
	.byt $12,$09,$0a,$92,$0d,$0b,$0f,$0e
	.byt $ff,$10,$0c,$ff,$ff,$1b,$00,$ff
	.byt $1c,$ff,$1d,$ff,$ff,$1f,$1e,$ff
	.byt $90,$06,$ff,$05,$ff,$ff,$11,$ff
	.byt $ff        ;end of table null
.endif

;
runtb	.byt "LOAD",$d,"RUN",$d
;
fkeytb	.byt $8D, "LIST:", 13, 0
	.byt $8D, "S", 'Y' + $80, "65280:", 13, 0
	.byt $8D, "RUN:", 13, 0
	.byt $93, "S", 'Y' + $80, "65375:?", $22, $93, 13, 0
	.byt "LOAD", 13, 0
	.byt "SAVE", '"', 0
	.byt $8D, $93, "DOS",'"', "$",13, 0
	.byt "DOS", '"', 0
;

; rsr 12/08/81 modify for vic-40 keyscan
; rsr  2/17/81 modify for the stinking 6526r2 chip
; rsr  3/11/82 modify for commodore 64
; rsr  3/28/82 modify for new pla
