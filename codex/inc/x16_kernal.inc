;;;
;;; Kernal linkages for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

	.ifndef __X16_KERNEL__
	__X16_KERNEL__=1

   .ifndef BANK_KERNAL
      .include "banks.inc"   ; X16 defs
   .endif

	.include "bank.inc"
	.include "regs.inc"
	.include "mac.inc"
	          
	;; Registers used within a module
	M1L=r12L
	M1H=r12H
	M1=r12

	M2L=r13L
	M2H=r13H
	M2=r13

	TMP1L=r14L
	TMP1H=r14H
	TMP1=r14

	TMP2L=r15L
	TMP2H=r15H
	TMP2=r15L

	LAST_ZP_REGISTER = r15H

	SCR_ROW=$22    ; same as x16L
	SCR_COL=$23    ; same as x16H

	ERR_MSG=$24    ; same as x17
	ERR_MSG_L=$24  ; same as x17L
	ERR_MSG_H=$25  ; same as x17H

										  ; Some constants
	CLS=147
	LF=10
	CR=13
	DEL=$14
	SPACE=$20
	
	SUCCESS=0
	FAIL=1
	
	CHR_SPACE=32
	SCR_LPAREN=40
	SCR_RPAREN=41
	SCR_DOLLAR=$24
	SCR_A=1
	SCR_R='R' - 'A' + 1
	SCR_BULLET=$71
	SCR_ZERO=$30
	SCR_ONE=$31
	SCR_SPACE=' '
	
										  ; Function keys
	KEY_STOP = $03
	F1=$85
	F2=$89
	F3=$86
	F4=$8a
	F5=$87
	F6=$8b
	F7=$88
	F8=$8c
	F9=$8d
	
	CUR_UP=$91
	CUR_DN=$11
	CUR_LEFT=$9D
	CUR_RIGHT=$1D
	
   FB_GET_PIXELS      = $F002
   FB_CURSOR_POSITION = $FEFF
   FB_NEXT_LINE       = $FF02
	ENTER_BASIC        = $FF47
	OPEN    = $FFC0
	SCRMOD  = $FF5f
	FETCH   = $FF74
	STASH   = $FF77
	MEMTOP  = $FF99
	READST  = $FFB7
	SETLFS  = $FFBA
	SETNAME = $FFBD
	CLOSE   = $FFC3
	CLALL   = $FFE7
	CHKIN   = $FFC6
	CHKOUT  = $FFC9
	CLRCHN  = $FFCC
	BASIN   = $FFCF
	CHROUT  = $ffd2   ; use kernal for doing a clear
	LOAD    = $FFD5
	SAVE    = $FFD8
	;;      !addr  CHRIN=$FFCF
	GETIN   = $FFE4
	SCREEN  = $FFED
	PLOT    = $FFF0
	MEMCOPY = $FEE7
	MEMFILL = $FEE4
	
	;; RAM variabls, should extract from a SYM file produced by the kernal
	BRK_VECTOR    = $0316
	FETCH_VECTOR  = $03AF
	STASH_VECTOR  = $03B2

	;;
	
	JSRFAR_VECTOR = $FF6E
	
	MODE_80_60   = $00
	MODE_80_30   = $01
	MODE_40_60   = $02
	MODE_40_30   = $03
	MODE_40_15   = $04
	MODE_20_30   = $05
	MODE_20_15   = $06
	MODE_320_240 = $80
	MODE_640_400 = $81
	MODE_SWAP    = $ff
	
   .macro ExchW dst
   plx
   ply
   lda dst
   pha
   lda dst+1
   pha
   stx dst+1
   sty dst
   .endmacro
   
	.macro ifEq16 r1,r2,dst
	lda    r1
	cmp    r2
	bne    :+
	lda    r1+1
	cmp    r2+1
	beq    dst
	:  
	.endmacro
	
	.macro ifNe16 r1,r2,dst
	lda    r1
	cmp    r2
	bne    dst
	lda    r1+1
	cmp    r2+1
	bne    dst
	.endmacro
	
										  ; http://www.6502.org/tutorials/compare_beyond.html
										  ; 16 bit unsigned compare
	.macro ifLT   v1,v2,then
	lda v1+1  ; compare high bytes
	cmp v2+1
	bcc then  ; if NUM1H < NUM2H then NUM1 < NUM2
	bne :+    ; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
	lda v1    ; compare low bytes
	cmp v2
	bcc then  ; if NUM1L < NUM2L then NUM1 < NUM2
	:  
	.endmacro
	
										  ; 16 bit unsigned compare
	.macro ifGE   v1,v2,then
	lda v1+1   ; compare high bytes
	cmp v2+1
	bcc :+     ; if NUM1H < NUM2H then NUM1 < NUM2
	bne then   ; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
	lda v1     ; compare low bytes
	CMP v2
	bcs then   ; if NUM1L >= NUM2L then NUM1 >= NUM2
	:  
	.endmacro
	
										  ; 16 bit unsigned compare
	.macro ifVGE   v1,v2,then
	lda #>v1   ; compare high bytes
	cmp v2+1
	bcc :+     ; if NUM1H < NUM2H then NUM1 < NUM2
	bne then   ; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
	lda #<v1   ; compare low bytes
	CMP v2
	bcs then   ; if NUM1L >= NUM2L then NUM1 >= NUM2
	:  
	.endmacro
	
	.macro debugger
	.byte $db   ; Debugger code for emulator R38
	.endmacro
	
	;;
	;; Call routine with r1 argument
	;;
	.macro callR1 routine, arg 
	LoadW  r1,arg
	jsr    routine
	.endmacro
	
	;;
	;; Call routine with r1 & r2 arguments
	;;
	.macro callR1R2 routine, arg,arg2
	LoadW  r1,arg
	LoadW  r2,arg2
	jsr    routine
	.endmacro
	
	;;
	;; Call routine with r1, r2, & r3 arguments
	;;
	.macro callR1R2R3 routine, arg,arg2,arg3
	LoadW  r1,arg
	LoadW  r2,arg2
	LoadW  r3,arg3
	jsr    routine
	.endmacro
	
	.macro jsrfar bank,addr
	jsr    JSRFAR_VECTOR
	.word  addr
	.byte  bank
	.endmacro
	
	.macro kerjsr addr
	jsr    JSRFAR_VECTOR
	.word  addr
	.byte  BANK_KERNAL
	.endmacro
	
	.macro aejsr addr
	jsr    JSRFAR_VECTOR
	.word  addr
	.byte  BANK_CODEX
	.endmacro
	
	.endif
	
