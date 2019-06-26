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
;
	jsr cln232      ;clean up rs232 for close
;
; deallocate buffers
;
	jsr gettop      ;get memsiz
	lda ribuf+1     ;check input allocation
	beq cls010      ;not...allocated
	iny
cls010	lda robuf+1     ;check output allocation
	beq cls020
	iny
cls020	lda #00         ;deallocate
	sta ribuf+1
	sta robuf+1
; flag top of memory change
	jmp memtcf      ;go set new top

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

; rsr  5/12/82 - modify for cln232
