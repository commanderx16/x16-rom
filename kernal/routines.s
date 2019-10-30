.export jsrfar, banked_irq
.export fetvec, fetch

; from GEOS
.import geos_init_graphics

.include "../geos/inc/geosmac.inc"
.include "../geos/inc/geossym.inc"
.include "../geos/inc/const.inc"
.include "../geos/inc/jumptab.inc"

	.segment "ROUTINES"

;//////////////////   J U M P   T A B L E   R O U T I N E S   \\\\\\\\\\\\\\\\\

;  look up secondary address:
;
;       enter with sa sought in y.  routine looks for match in tables.
;       exits with .c=1 if not found, else .c=0 & .a=la, .x=fa, .y=sa

lkupsa
	tya
	ldx ldtnd       ;get lat, fat, sat table index

:       dex
	bmi lkupng      ;...branch if end of table (not found)
	cmp sat,x
	bne :-          ;...keep looking

lkupok	jsr getlfs      ;set up la, fa, sa   (** lkupla enters here **)
	tax
	lda la
	ldy sa
	clc             ;flag 'we found it'
	rts

lkupng	sec             ;flag 'not found'
	rts

;  **********************************************
;  *	close_all   - closes all files on a	*
;  *		      given device.		*
;  *						*
;  *	 > search tables for given fa & do a	*
;  *	   proper close for all matches.	*
;  *						*
;  *	 > IF one of the closed entries is the	*
;  *	   current I/O channel THEN the default	*
;  *	   channel will be restored.		*
;  *						*
;  *	entry:  .a = device (fa) to close	*
;  *						*
;  **********************************************

close_all
	sta fa		;save device to shut down
	cmp dflto
	bne @10		;...branch if not current output device
	lda #3
	sta dflto	;restore screen output
	.byte $2c

@10	cmp dfltn
	bne @20		;...branch if not current input device
	lda #0
	sta dfltn	;restore keyboard input

@20	lda fa
	ldx ldtnd	;lat, fat, sat table index
@30	dex
	bmi @40		;...branch if end of table
	cmp fat,x
	bne @30		;...loop until match

	lda lat,x	;a match- extract logical channel data
	jsr close	;close it via indirect
	bcc @20		;always

@40	rts

;  look up logical file address:
;
;       enter with la sought in a.  routine looks for match in tables.
;       exits with .c=1 if not found, else .c=0 & .a=la, .x=fa, .y=sa

lkupla
	tax
	jsr lookup      ;search lat table
	beq lkupok      ;...branch if found
	bne lkupng      ;else return with .c=1

getlfs
	lda lat,x	;routine to fetch table entries
	sta la
	lda sat,x
	sta sa
	lda fat,x
	sta fa		; (return with .p status of fa!)
	rts


; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
indfet
	sta fetvec      ; LDA (fetvec),Y  utility
	jmp fetch


; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;     *** print immediate ***
;  a jsr to this routine is followed by an immediate ascii string,
;  terminated by a $00. the immediate string must not be longer
;  than 255 characters including the terminator.

primm
	pha             ;save registers
	txa
	pha
	tya
	pha
	ldy #0

@1	tsx             ;increment return address on stack
	inc $104,x      ;and make imparm = return address
	bne @2
	inc $105,x
@2	lda $104,x
	sta imparm
	lda $105,x
	sta imparm+1

	lda (imparm),y  ;fetch character to print (*** always system bank ***)
	beq @3          ;null= eol
	jsr bsout       ;print the character
	bcc @1

@3	pla             ;restore registers
	tay
	pla
	tax
	pla
	rts             ;return


; modes:
; $00: 40x30
; $01: 80x30 ; XXX currently unsupported
; $02: 80x60
; $80: 320x240@256c + 40x30 text
;     (320x200@256c + 40x25 text, currently)
; $81: 640x400@16c ; XXX currently unsupported
; $ff: toggle between $00 and $02

scrmod	bcs scrnmd0
	lda cscrmd
	rts
scrnmd0	cmp #$ff
	bne scrmd1
; toggle between 40x30 and  80x60
	lda #2
	cmp cscrmd
	bne scrmd1
	lda #0
scrmd1	sta cscrmd
	cmp #0 ; 40x30
	beq swpp30
	cmp #1 ; 80x30 currently unsupported
	bne scrmd2
scrmd3	sec
	rts
scrmd2	cmp #2 ; 80x60
	beq swpp60
	cmp #$80 ; 320x240@256c + 40x30 text
	beq swpp25
	cmp #$81 ; 640x400@16c
	beq scrmd3 ; currently unsupported
	bra scrmd3 ; otherwise: illegal mode

swpp60	ldx #80
	ldy #60
	lda #128 ; scale = 1.0
	clc
	bne swpp2 ; always
swpp25	jsr grphon
	ldy #25
	sec
	bra swpp3
swpp30	clc
	ldy #30
swpp3	ldx #40
	lda #64 ; scale = 2.0
swpp2	pha
	bcs swppp4
	jsr grphoff
swppp4	lda #$01
	sta veralo
	lda #$00
	sta veramid
	lda #$1F
	sta verahi
	pla
	sta veradat ; reg $F0001: hscale
	sta veradat ; reg $F0002: vscale
	cpy #25
	bne swpp1
	lda #<400
	.byte $2c
swpp1	lda #<480
	pha
	lda #7 ; vstop_lo
	sta veralo
	pla
	sta veradat
	jsr scnsiz
	clc
	rts


grphon	lda #$0e ; light blue
	sta color

; TODO go through GEOS init
	LoadW dispBufferOn, ST_WR_FORE
	LoadB windowTop, 0
	LoadB windowBottom, SC_PIX_HEIGHT-1
	LoadW leftMargin, 0
	LoadW rightMargin, SC_PIX_WIDTH-1
	LoadB pressFlag, 0

	sei
	jsr jsrfar
	.word geos_init_graphics
	.byte BANK_GEOS
	cli
	rts

grphoff	lda #$00        ; layer0
	sta veralo
	lda #$20
	sta veramid
	lda #$1F
	sta verahi
	lda #0          ; off
	sta veradat
	rts

;/////////////////////   K E R N A L   R A M   C O D E  \\\\\\\\\\\\\\\\\\\\\\\

.segment "KERNRAM"

;  FETCH  ram code      ( LDA (fetch_vector),Y  from any bank )
;
;  enter with 'fetvec' pointing to indirect adr & .y= index
;             .x= memory configuration
;
;  exits with .a= data byte & status flags valid
;             .x altered

fetch	lda d1pra       ;save current config (RAM)
	pha
	lda d1prb       ;save current config (ROM)
	pha
	txa
	sta d1pra       ;set RAM bank
	and #$07
	sta d1prb       ;set ROM bank
fetvec	=*+1
	lda ($ff),y     ;get the byte ($ff here is a dummy address, 'FETVEC')
	tax
	pla
	sta d1prb       ;restore previous memory configuration
	pla
	sta d1pra
	txa
	rts



;  STASH  ram code      ( STA (stash_vector),Y  to any bank )
;
;  enter with 'stavec' pointing to indirect adr & .y= index
;             .a= data byte to store
;             .x= memory configuration
;
;  exits with .x & status altered

stash	sta stash1
	lda d1pra       ;save current config (RAM)
	pha
	txa
	sta d1pra       ;set RAM bank
	and #$07
	ldx d1prb       ;save current config (ROM)
	sta d1prb       ;set ROM bank
stash1	=*+1
	lda #$ff
stavec	=*+1
	sta ($ff),y     ;put the byte ($ff here is a dummy address, 'STAVEC')
	stx d1prb       ;restore previous memory configuration
	pla
	sta d1pra
	rts



;  CMPARE  ram code      ( CMP (cmpare_vector),Y  to any bank )
;
;  enter with 'cmpvec' pointing to indirect adr & .y= index
;             .a= data byte to compare to memory
;             .x= memory configuration
;
;  exits with .a= data byte & status flags valid, .x is altered

cmpare
	pha
	lda d1pra       ;save current config (RAM)
	pha
	txa
	sta d1pra       ;set RAM bank
	and #$07
	ldx d1prb       ;save current config (ROM)
	sta d1prb       ;set ROM bank
	pla
cmpvec	=*+1
	cmp ($ff),y     ;compare bytes ($ff here is a dummy address, 'CMPVEC')
	php
	stx d1prb       ;restore previous memory configuration
	pla
	tax
	pla
	sta d1pra
	txa
	pha
	plp
	rts

; LONG CALL  utility
;
; jsr jsrfar
; .word address
; .byte bank

jsrfar	pha             ;reserve 1 byte on the stack
	php             ;save registers & status
	pha
	phx
	phy

        tsx
	lda $106,x      ;return address lo
	sta imparm
	clc
	adc #3
	sta $106,x      ;and write back with 3 added
	lda $107,x      ;return address hi
	sta imparm+1
	adc #0
	sta $107,x

	ldy #1
	lda (imparm),y  ;target address lo
	sta jmpfr+1
	iny
	lda (imparm),y  ;target address hi
	sta jmpfr+2
	cmp #$c0
	bcs @1          ;target is in ROM
; target is in RAM
	lda d1pra
	sta $0105,x     ;save original bank into reserved byte
	iny
	lda (imparm),y  ;target address bank
	sta d1pra       ;set RAM bank
	ply             ;restore registers
	plx
	pla
	plp
	jsr jmpfr
	php
	pha
	phx
	tsx
	lda $0104,x
	sta d1pra       ;restore RAM bank
	jmp @2

@1	lda d1prb
	sta $0105,x     ;save original bank into reserved byte
	iny
	lda (imparm),y  ;target address bank
	and #$07
	sta d1prb       ;set ROM bank
	ply             ;restore registers
	plx
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
@2	plx
	pla
	plp
	plp
	rts

jmpfr	jmp $ffff


banked_irq
	pha
	phx
	lda d1prb
	pha
	lda #BANK_KERNAL
	sta d1prb
	lda #>@l1
	pha
	lda #<@l1
	pha
	tsx
	lda $0106,x
	pha
	jmp ($fffe)
@l1	pla
	sta d1prb
	plx
	pla
	rti


	; this should not live in the vector area, but it's ok for now
restore_basic:
	jsr jsrfar
	.word $c000 + 3
	.byte BANK_BASIC
	;not reached
