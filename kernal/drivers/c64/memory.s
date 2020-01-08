;----------------------------------------------------------------------
; Commodore 64 Memory Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.import memtop, membot

.export ramtas, jsrfar, indfet, cmpare, stash
.export enter_basic

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
	txa
:	sta a:$0002,x   ;zero page, excluding CPU I/O port
	sta $0200,x     ;user buffers and vars
	sta $0300,x     ;system space and user space
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

enter_basic:
	bcc :+
	jmp ($a000) ; cold
:	jmp ($a003) ; warm
