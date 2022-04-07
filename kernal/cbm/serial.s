;----------------------------------------------------------------------
; Serial Bus
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

.include "io.inc"
.include "mac.inc"

.importzp mhz

.import status
.import udst

.export serial_init
.export serial_secnd
.export serial_tksa
.export serial_acptr
.export serial_ciout
.export serial_untlk
.export serial_unlsn
.export serial_listn
.export serial_talk

.export tkatn; [channel]
.export scatn; [channel]
.export clklo; [machine init]

.segment "KVAR"

c3p0	.res 1           ;$94 ieee buffered char flag
bsour	.res 1           ;$95 char buffer for ieee
r2d2	.res 1           ;$A3 serial bus usage
bsour1	.res 1           ;$A4 temp used by serial routine
count	.res 1           ;$A5 temp used by serial routine

	.segment "SERIAL"

serial_init:
	lda d1prb
	and #%11000111  ;ATN = 0, DATA, CLK = 1
	sta d1prb
	lda d1ddrb
	and #%00111111  ;DATA, CLK in
	ora #%00111000  ;DATA, CLK, ATN out
	sta d1ddrb
	lda #%01000000  ;free running t1 d2
	sta d1acr
	rts

;command serial bus device to talk
;
serial_talk
	ora #$40        ;make a talk adr
	bra list1

;command serial bus device to listen
;
serial_listn
	ora #$20        ;make a listen adr
list1	pha
	lda #2
	jsr serial_delay
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
	lda #2
	jsr serial_delay
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
list5	lda d1prb       ;assert attention
	ora #$08
	sta d1prb
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
	lda #1          ;hold data setup (Ts: 20us min)
	jsr serial_delay
	lda d1prb       ;debounce the bus
	cmp d1prb
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
	lda #1          ;hold data valid (Tv: 20us min)
	jsr serial_delay
	lda d1prb
	and #$ff-$20    ;data high
	ora #$10        ;clock low
	sta d1prb
	dec count
	bne isr01
	lda #$04*mhz    ;set timer for 1ms
	sta d1t2h
isr04	lda d1ifr
	and #$20
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
serial_secnd
	sta bsour       ;buffer character
	jsr isoura      ;send it

;release attention after listen
;
scatn	lda d1prb
	and #$ff-$08
	sta d1prb       ;release attention
	rts

;talk second address
;
serial_tksa
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
serial_ciout
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
serial_untlk
	sei
	jsr clklo
	lda d1prb       ;pull atn
	ora #$08
	sta d1prb
	lda #$5f        ;untalk command
	bra :+

;send unlisten command on serial bus
;
serial_unlsn
	lda #$3f        ;unlisten command
:	jsr list1       ;send it
;
; release all lines
dlabye	jsr scatn       ;always release atn
	jsr dladlh
	lda #16
	jmp serial_delay

; delay then release clock and data
;
dladlh	lda #1
	jsr serial_delay
	jsr clkhi
	jmp datahi

;input a byte from serial bus
;
serial_acptr
	sei             ;no irq allowed
	lda #$00        ;set eoi/error flag
	sta count
	sta status
	jsr clkhi       ;make sure clock line is released
acp00a	jsr debpia      ;wait for clock high
	bpl acp00a
;
eoiacp
	lda #$01*mhz    ;set timer 2 for 256us
	sta d1t2h
	jsr datahi      ;data line high (makes timming more like vic-20
acp00	lda d1ifr
	and #$20        ;check the timer
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
	jsr clkhi
	lda #1          ;(Tei: min 80us)
	jsr serial_delay
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
acp03	lda d1prb       ;wait for clock high
	cmp d1prb       ;debounce
	bne acp03
	asl a           ;shift data into carry
	bpl acp03       ;clock still low...
	ror bsour1      ;rotate data in
;
acp03a	lda d1prb       ;wait for clock low
	cmp d1prb       ;debounce
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
	lda d1prb
	and #$ff-$10
	sta d1prb
	rts
;
clklo	;set clock line low  (inverted)
	lda d1prb
	ora #$10
	sta d1prb
	rts
;
;
datahi	;set data line high (inverted)
	lda d1prb
	and #$ff-$20
	sta d1prb
	rts
;
datalo	;set data line low  (inverted)
	lda d1prb
	ora #$20
	sta d1prb
	rts
;
debpia	lda d1prb       ;debounce the pia
	cmp d1prb
	bne debpia
	asl a           ;shift the data bit into the carry...
	rts             ;...and the clock into neg flag
;
w1ms	                ;delay 1ms using timer 2
	lda #$04*mhz
	sta d1t2h
w1ms1	                ;timer wait loop
	lda d1ifr
	and #$20
	beq w1ms1
	rts

;.a=microseconds/60
serial_delay
	phx
delay0	ldx #12*mhz
delay1	dex
	bne delay1
	dec
	bne delay0
	plx
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
;modify for X16 i/o system 4/7/22 ms
;******************************

