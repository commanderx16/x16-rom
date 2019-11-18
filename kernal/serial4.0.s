	.segment "SERIAL"

sdata = $ffff ; XXX fill for X16

;command serial bus device to talk
;
talk
.ifdef CBDOS
	jsr jsrfar
	.word $c000 + 3 * 7
	.byte BANK_CBDOS
	rts
.endif
	ora #$40        ;make a talk adr
	bra list1       

;command serial bus device to listen
;
listn
.ifdef CBDOS
	jsr jsrfar
	.word $c000 + 3 * 6
	.byte BANK_CBDOS
	rts
.endif
	ora #$20        ;make a listen adr
list1	pha
;
;
	bit c3p0        ;character left in buf?
	bpl list2       ;no...
;
;send buffered character
;
	sec             ;set eoi flag
	ror r2d2
;
	jsr isour       ;send last character
;
	lsr c3p0        ;buffer clear flag
	lsr r2d2        ;clear eoi flag
;
;
list2	pla             ;talk/listen address
	sta bsour
	sei
	jsr datahi
	cmp #$3f        ;clkhi only on unlisten
	bne list5
	jsr clkhi
;
list5	lda sdata       ;assert attention
	ora #$08
	sta sdata
;

isoura	sei
	jsr clklo       ;set clock line low
	jsr datahi
	jsr w1ms        ;delay 1 ms

isour	sei             ;no irq's allowed
	jsr datahi      ;make sure data is released
	jsr debpia      ;data should be low
	bcs nodev
	jsr clkhi       ;clock line high
	bit r2d2        ;eoi flag test
	bpl noeoi
; do the eoi
isr02	jsr debpia      ;wait for data to go high
	bcc isr02
;
isr03	jsr debpia      ;wait for data to go low
	bcs isr03
;
noeoi	jsr debpia      ;wait for data high
	bcc noeoi
	jsr clklo       ;set clock low
;
; set to send data
;
	lda #$08        ;count 8 bits
	sta count
;
isr01
	lda sdata       ;debounce the bus
	cmp sdata
	bne isr01
	asl a           ;set the flags
	bcc frmerr      ;data must be hi
;
	ror bsour       ;next bit into carry
	bcs isrhi
	jsr datalo
	bne isrclk
isrhi	jsr datahi
isrclk	jsr clkhi       ;clock hi
	nop
	nop
	nop
	nop
	lda sdata
	and #$ff-$20    ;data high
	ora #$10        ;clock low
	sta sdata
	dec count
	bne isr01
	lda #$04        ;set timer for 1ms
	sta d1t2h
	lda #timrb      ;trigger timer
	sta d1crb
	lda d1icr       ;clear the timer flags<<<<<<<<<<<<<
isr04	lda d1icr
	and #$02
	bne frmerr
	jsr debpia
	bcs isr04
	cli             ;let irq's continue
	rts
;
nodev	;device not present error
	lda #$80
	bra csberr
frmerr	;framing error
	lda #$03
csberr	jsr udst        ;commodore serial buss error entry
	cli             ;irq's were off...turn on
	clc             ;make sure no kernal error returned
	bcc dlabye      ;turn atn off ,release all lines
;

;send secondary address after listen
;
secnd
.ifdef CBDOS
	jsr jsrfar
	.word $c000 + 3 * 0
	.byte BANK_CBDOS
	rts
.endif
	sta bsour       ;buffer character
	jsr isoura      ;send it

;release attention after listen
;
scatn	lda sdata
	and #$ff-$08
	sta sdata       ;release attention
	rts

;talk second address
;
tksa
.ifdef CBDOS
	jsr jsrfar
	.word $c000 + 3 * 1
	.byte BANK_CBDOS
	rts
.endif
	sta bsour       ;buffer character
	jsr isoura      ;send second addr

tkatn	;shift over to listener
	sei             ;no irq's here
	jsr datalo      ;data line low
	jsr scatn
	jsr clkhi       ;clock line high jsr/rts
tkatn1	jsr debpia      ;wait for clock to go low
	bmi tkatn1
	cli             ;irq's okay now
	rts

;buffered output to serial bus
;
ciout
.ifdef CBDOS
	jsr jsrfar
	.word $c000 + 3 * 3
	.byte BANK_CBDOS
	rts
.endif
	bit c3p0        ;buffered char?
	bmi ci2         ;yes...send last
;
	sec             ;no...
	ror c3p0        ;set buffered char flag
	bne ci4         ;branch always
;
ci2	pha             ;save current char
	jsr isour       ;send last char
	pla             ;restore current char
ci4	sta bsour       ;buffer current char
	clc             ;carry-good exit
	rts

;send untalk command on serial bus
;
untlk
.ifdef CBDOS
	jsr jsrfar
	.word $c000 + 3 * 4
	.byte BANK_CBDOS
	rts
.endif
	sei
	jsr clklo
	lda sdata       ;pull atn
	ora #$08
	sta sdata
	lda #$5f        ;untalk command
	bra :+

;send unlisten command on serial bus
;
unlsn
.ifdef CBDOS
	jsr jsrfar
	.word $c000 + 3 * 5
	.byte BANK_CBDOS
	rts
.endif
	lda #$3f        ;unlisten command
:	jsr list1       ;send it
;
; release all lines
dlabye	jsr scatn       ;always release atn
; delay then release clock and data
;
dladlh	txa             ;delay approx 60 us
	ldx #10
dlad00	dex
	bne dlad00
	tax
	jsr clkhi
	jmp datahi

;input a byte from serial bus
;
acptr
.ifdef CBDOS
	jsr jsrfar
	.word $c000 + 3 * 2
	.byte BANK_CBDOS
	rts
.endif
	sei             ;no irq allowed
	lda #$00        ;set eoi/error flag
	sta count
	jsr clkhi       ;make sure clock line is released
acp00a	jsr debpia      ;wait for clock high
	bpl acp00a
;
eoiacp
	lda #$01        ;set timer 2 for 256us
	sta d1t2h
	lda #timrb
	sta d1crb
	jsr datahi      ;data line high (makes timming more like vic-20
	lda d1icr       ;clear the timer flags<<<<<<<<<<<<
acp00	lda d1icr
	and #$02        ;check the timer
	bne acp00b      ;ran out.....
	jsr debpia      ;check the clock line
	bmi acp00       ;no not yet
	bpl acp01       ;yes.....
;
acp00b	lda count       ;check for error (twice thru timeouts)
	beq acp00c
	lda #2
	jmp csberr      ; st = 2 read timeout
;
; timer ran out do an eoi thing
;
acp00c	jsr datalo      ;data line low
	jsr clkhi       ; delay and then set datahi (fix for 40us c64)
	lda #$40
	jsr udst        ;or an eoi bit into status
	inc count       ;go around again for error check on eoi
	bne eoiacp
;
; do the byte transfer
;
acp01	lda #08         ;set up counter
	sta count
;
acp03	lda sdata       ;wait for clock high
	cmp sdata       ;debounce
	bne acp03
	asl a           ;shift data into carry
	bpl acp03       ;clock still low...
	ror bsour1      ;rotate data in
;
acp03a	lda sdata       ;wait for clock low
	cmp sdata       ;debounce
	bne acp03a
	asl a
	bmi acp03a
	dec count
	bne acp03       ;more bits.....
;...exit...
	jsr datalo      ;data low
	bit status      ;check for eoi
	bvc acp04       ;none...
;
	jsr dladlh      ;delay then set data high
;
acp04	lda bsour1
	cli             ;irq is ok
	clc             ;good exit
	rts
;
clkhi	;set clock line high (inverted)
	lda sdata
	and #$ff-$10
	sta sdata
	rts
;
clklo	;set clock line low  (inverted)
	lda sdata
	ora #$10
	sta sdata
	rts
;
;
datahi	;set data line high (inverted)
	lda sdata
	and #$ff-$20
	sta sdata
	rts
;
datalo	;set data line low  (inverted)
	lda sdata
	ora #$20
	sta sdata
	rts
;
debpia	lda sdata       ;debounce the pia
	cmp sdata
	bne debpia
	asl a           ;shift the data bit into the carry...
	rts             ;...and the clock into neg flag
;
w1ms	;delay 1ms using loop
	txa             ;save .x
	ldx #200-16     ;1000us-(1000/500*8=#40us holds)
w1ms1	dex             ;5us loop
	bne w1ms1
	tax             ;restore .x
	rts

;*******************************
;written 8/11/80 bob fairbairn
;test serial0.6 8/12/80  rjf
;change i/o structure 8/21/80 rjf
;more i/o changes 8/24/80 rjf
;final release into kernal 8/26/80 rjf
;some clean up 9/8/80 rsr
;add irq protect on isour and tkatn 9/22/80 rsr
;fix untalk 10/7/80 rsr
;modify for vic-40 i/o system 12/08/81 rsr
;add sei to (untlk,isoura,list2) 12/14/81 rsr
;modify for 6526 flags fix errs 12/31/81 rsr
;modify for commodore 64 i/o  3/11/82 rsr
;change acptr eoi for better response 3/28/82 rsr
;change wait 1 ms routine for less code 4/8/82 rsr
;******************************

