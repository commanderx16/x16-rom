;----------------------------------------------------------------------
; Commodore 64 Memory Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.import memtop, membot

.export ramtas, jsrfar, indfet, cmpare, stash
.export restore_basic

mmbot	=$0800
mmtop   =$8000

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
; clear kernal variables
;
	ldx #0          ;zero low memory
:	stz $0002,x     ;zero page
	stz $0200,x     ;user buffers and vars
	stz $0300,x     ;system space and user space
	inx
	bne :-

;
; set bottom and top of memory
;
	lda #0          ;number of banks
	ldx #<mmtop
	ldy #>mmtop
	clc
	jsr memtop
	ldx #<mmbot
	ldy #>mmbot
	clc
	jmp membot

; banking not supported
jsrfar:
indfet:
cmpare:
stash:
	brk

restore_basic:
	brk

