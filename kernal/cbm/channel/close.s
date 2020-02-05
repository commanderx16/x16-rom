;----------------------------------------------------------------------
; Channel: Close
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD


.include "mac.inc"

;***************************************
;* close -- close logical file       *
;*                                   *
;*     the logical file number of the*
;* file to be closed is passed in .a.*
;* keyboard, screen, and files not   *
;* open pass straight through. tape  *
;* files open for write are closed by*
;* dumping the last buffer and       *
;* conditionally writing an end of   *
;* tape block.serial files are closed*
;* by sending a close file command if*
;* a secondary address was specified *
;* in its open command.              *
;***************************************
;
nclose	jsr jltlk       ;look file up
	beq jx050       ;open...
jx115	clc             ;else return
	rts
;
jx050	jsr jz100       ;extract table data
	txa             ;save table index
	pha
;
	lda fa          ;check device number
	beq jx150       ;is keyboard...done
	cmp #3
	beq jx150       ;is screen...done
	bcs jx120       ;is serial...process
	cmp #2          ;rs232?
	bne jx115       ;no...
;
; rs-232 close
;
; remove file from tables
	pla
	jsr jxrmv
	jmp cls232

;
;close an serial file
;
jx120	jsr clsei
;
;entry to remove a give logical file
;from table of logical, primary,
;and secondary addresses
;
jx150	pla             ;get table index off stack
;
; jxrmv - entry to use as an rs-232 subroutine
;
jxrmv	tax
	dec ldtnd
	cpx ldtnd       ;is deleted file at end?
	beq jx170       ;yes...done
;
;delete entry in middle by moving
;last entry to that position.
;
	ldy ldtnd
	lda lat,y
	sta lat,x
	lda fat,y
	sta fat,x
	lda sat,y
	sta sat,x
;
jx170	clc             ;close exit
jx175	rts

;lookup tablized logical file data
;
lookup	lda #0
	sta status
	txa
jltlk	ldx ldtnd
jx600	dex
	bmi jz101
	cmp lat,x
	bne jx600
	rts

;routine to fetch table entries
;
jz100	lda lat,x
	sta la
	lda fat,x
	sta fa
	lda sat,x
	sta sa
jz101	rts

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

; rsr  5/12/82 - modify for cln232
