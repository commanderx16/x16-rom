;----------------------------------------------------------------------
; Channel: CLALL/CLRCH
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

;***************************************
;* clall -- close all logical files  *
;*      deletes all table entries and*
;* restores default i/o channels     *
;* and clears ieee port devices      *
;*************************************
;
nclall	lda #0
	sta ldtnd       ;forget all files

;********************************************
;* clrch -- clear channels                  *
;*   unlisten or untalk ieee devices, but   *
;* leave others alone.  default channels    *
;* are restored.                            *
;********************************************
;
nclrch	ldx #3
	cpx dflto       ;is output channel ieee?
	bcs jx750       ;no...
;
	jsr unlsn       ;yes...unlisten it
;
jx750	cpx dfltn       ;is input channel ieee?
	bcs clall2      ;no...
;
	jsr untlk       ;yes...untalk it
;
;restore default values
;
;
clall2	stx dflto       ;output chan=3=screen
	lda #0
	sta dfltn       ;input chan=0=keyboard
	rts

