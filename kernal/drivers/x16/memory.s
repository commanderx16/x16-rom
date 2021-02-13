;----------------------------------------------------------------------
; Commander X16 Memory Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.include "banks.inc"
.include "io.inc"

.import __KERNRAM_LOAD__, __KERNRAM_RUN__, __KERNRAM_SIZE__
.import __KERNRAM2_LOAD__, __KERNRAM2_RUN__, __KERNRAM2_SIZE__
.import __KVARSB0_LOAD__, __KVARSB0_RUN__, __KVARSB0_SIZE__
.import memtop
.import membot

.import ieeeswitch_init

.export ramtas
.export enter_basic
.export monitor

.export fetch
.export fetvec
.export indfet
.export stash
.export stavec
.export cmpare

.export jsrfar

mmbot	=$0800
mmtop   =$9f00

.segment "MEMDRV"

;---------------------------------------------------------------
; Measure and initialize RAM
;
; Function:  This routine
;            * clears kernal variables
;            * copies banking code into RAM
;            * detects RAM size, calling
;              - MEMTOP
;              - MEMBOT
;---------------------------------------------------------------
ramtas:
;
; set up banking
;
	lda #$ff
	sta d1ddra
	sta d1ddrb

;
; clear kernal variables
;
	ldx #0          ;zero low memory
:	stz $0000,x     ;zero page
	stz $0200,x     ;user buffers and vars
	stz $0300,x     ;system space and user space
	inx
	bne :-

;
; clear bank 0 kernal variables
;
.assert __KVARSB0_SIZE__ < 256, error, "KVARSB0 overflow!"
	ldx #<__KVARSB0_SIZE__
:	stz __KVARSB0_LOAD__,x
	dex
	bne :-

;
; copy banking code into RAM
;
	ldx #<__KERNRAM_SIZE__
:	lda __KERNRAM_LOAD__-1,x
	sta __KERNRAM_RUN__-1,x
	dex
	bne :-

	ldx #<__KERNRAM2_SIZE__
:	lda __KERNRAM2_LOAD__-1,x
	sta __KERNRAM2_RUN__-1,x
	dex
	bne :-

;
; detect number of RAM banks
;
	stz d1pra
	ldx $a000
	inx
	lda #1
:	sta d1pra
	ldy $a000
	stx $a000
	stz d1pra
	cpx $a000
	sta d1pra
	sty $a000
	beq :+
	asl
	bne :-
:	tay
	stz d1pra
	dex
	stx $a000
	
	tya ; number of RAM banks
;
; set bottom and top of memory
;
	ldx #<mmtop
	ldy #>mmtop
	clc
	jsr memtop
	ldx #<mmbot
	ldy #>mmbot
	clc
	jsr membot

;
; activate bank #1 as default
;
	lda #1
	sta d1pra ; RAM bank

;
; initialize CBDOS
;
; This is not the perfect spot for this, but we cannot do this
; any earlier, since it relies on jsrfar.
;
	jmp ieeeswitch_init


jsrfar:
.include "jsrfar.inc"

;/////////////////////   K E R N A L   R A M   C O D E  \\\\\\\\\\\\\\\\\\\\\\\

.segment "KERNRAM"
.export jmpfr
.assert * = jsrfar3, error, "jsrfar3 must be at specific address"
;jsrfar3:
	sta d1prb       ;set ROM bank
	pla
	plp
	jsr jmpfr
	php
	pha
	phx
	tsx
	lda $0104,x
	sta d1prb       ;restore ROM bank
	lda $0103,x     ;overwrite reserved byte...
	sta $0104,x     ;...with copy of .p
	plx
	pla
	plp
	plp
	rts
.assert * = jmpfr, error, "jmpfr must be at specific address"
;jmpfr:
	jmp $ffff


.segment "KERNRAM2"

.assert * = banked_irq, error, "banked_irq must be at specific address"
;banked_irq:
	pha
	phx
	lda d1prb       ;save ROM bank
	pha
	lda #BANK_KERNAL
	sta d1prb
	lda #>@l1       ;put RTI-style
	pha             ;return-address
	lda #<@l1       ;onto the
	pha             ;stack
	tsx
	lda $0106,x     ;fetch status
	pha             ;put it on the stack at the right location
	jmp ($fffe)     ;execute other bank's IRQ handler
@l1:	pla
	sta d1prb       ;restore ROM bank
	plx
	pla
	rti

.segment "MEMDRV"

; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
indfet:
	sta fetvec      ; LDA (fetvec),Y  utility

;  FETCH                ( LDA (fetch_vector),Y  from any bank )
;
;  enter with 'fetvec' pointing to indirect adr & .y= index
;             .x= memory configuration
;
;  exits with .a= data byte & status flags valid
;             .x altered

fetch:	lda d1pra       ;save current config (RAM)
	pha
	lda d1prb       ;save current config (ROM)
	pha
	txa
	sta d1pra       ;set RAM bank
	plx             ;original ROM bank
	and #$07
	php
	sei
	jsr fetch2
	plp
	plx
	stx d1pra       ;restore RAM bank
	ora #0          ;set flags
	rts
.segment "KERNRAM2" ; *** RAM code ***
fetch2:	sta d1prb       ;set new ROM bank
fetvec	=*+1
	lda ($ff),y     ;get the byte ($ff here is a dummy address, 'FETVEC')
	stx d1prb       ;restore ROM bank
	rts

.segment "MEMDRV"

;  STASH  ram code      ( STA (stash_vector),Y  to any bank )
;
;  enter with 'stavec' pointing to indirect adr & .y= index
;             .a= data byte to store
;             .x= memory configuration (RAM bank)
;
;  exits with .x & status altered

; XXX this needs to be in RAM in order to work!

stash:	sta stash1
	lda d1pra       ;save current config (RAM)
	pha
	stx d1pra       ;set RAM bank
	jmp stash0
.segment "KERNRAM2" ; *** RAM code ***
stash0:
stash1	=*+1
	lda #$ff
_stavec	=*+1
.assert stavec = _stavec, error, "stavec must be at specific address"
	sta ($ff),y     ;put the byte ($ff here is a dummy address, 'STAVEC')
	plx
	stx d1pra
	rts

.segment "MEMDRV"


;  CMPARE  ram code      ( CMP (cmpare_vector),Y  to any bank )
;
;  enter with 'cmpvec' pointing to indirect adr & .y= index
;             .a= data byte to compare to memory
;             .x= memory configuration
;
;  exits with .a= data byte & status flags valid, .x is altered

; XXX this needs to be in RAM in order to work!

cmpare:
	pha
	lda d1pra       ;save current config (RAM)
	pha
	txa
	sta d1pra       ;set RAM bank
	and #$07
	ldx d1prb       ;save current config (ROM)
	jmp cmpare0
.segment "KERNRAM2" ; *** RAM code ***
cmpare0:
	sta d1prb       ;set ROM bank
	pla
cmpvec	=*+1
	cmp ($ff),y     ;compare bytes ($ff here is a dummy address, 'CMPVEC')
	php
	stx d1prb       ;restore previous memory configuration
	jmp cmpare1
.segment "MEMDRV"
cmpare1:
	pla
	tax
	pla
	sta d1pra
	txa
	pha
	plp
	rts

enter_basic:
	bcc :+
; cold
	jsr jsrfar
	.word $c000
	.byte BANK_BASIC
	;not reached

; warm
:	jsr jsrfar
	.word $c000 + 3
	.byte BANK_BASIC
	;not reached

monitor:
	jsr jsrfar
	.word $c000
	.byte BANK_MONITOR
	;not reached
