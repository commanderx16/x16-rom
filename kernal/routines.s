.include "../regs.inc"
.include "../mac.inc"

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
	bra :+

@10	cmp dfltn
:	bne @20		;...branch if not current input device
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


restore_basic:
	jsr jsrfar
	.word $c000 + 3
	.byte BANK_BASIC
	;not reached
