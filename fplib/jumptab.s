; FBLIB Jump Table at $FD00

; see
; * -mapping-
; * https://codebase64.org/doku.php?id=base:asm_include_file_for_basic_routines

.segment "FPJMP"

	jmp ayint  ; $B1BF (moved from BASIC)
	jmp givayf2; $B391 (variant of BASIC givayf2)
	jmp getadr2; $B7F7 (variant of BASIC getadr)

	; Add .5 to FAC1
	jmp faddh  ; $B849 -mapping-

	; Subtract FAC1 from a Number in Memory
	jmp fsub   ; $B850 -mapping-

	; Subtracts the contents of FAC2 from FAC1
	jmp fsubt  ; $B853

	; Add FAC1 to a Number in Memory
	jmp fadd   ; $B867

	; FAC = FAC + ARG
	jmp faddt  ; $B86A

	; FAC = 0
	jmp zerofc ; $B8F7

	; Normalize FAC [bug in -mappping-]
	jmp normal; $B8D7

	; Replace FAC1 with Its 2's Complement
	jmp negfac ; $B947 -mapping-

.if 0
	; Print Overflow Error Message
	; XXX move to BASIC?
	jmp overr  ; $B97E
.endif

	; SHIFT Routine
	jmp mulshf ; $B983 -mapping-

	; Perform LOG to Base E
	jmp log    ; $B9EA

	; Multiply FAC1 with FAC2
	jmp fmult  ; $BA28 -mapping-

	; * operator
	jmp fmultt ; $BA2B

	; Multiply a Byte Subroutine
	jmp mltply ; $BA59 -mapping-

	; Move a Floating Point Number from Memory into FAC2
	jmp conupk ; $BA8C -mapping-

	; Add Exponent of FAC1 to Exponent of FAC2
	jmp muldiv ; $BAB7 -mapping-

	; Handle Underflow or Overflow
	jmp mldvex ; $BAD4 -mapping-

	; Multiply FAC1 by 10
	jmp mul10  ; $BAE2

	; ???
	jmp finml6 ; $BAED

	; Divide FAC1 by 10
	jmp div10  ; $BAFE

	; Divide a Number in Memory by FAC1
	jmp fdiv   ; $BB0F -mapping-

	; Divide FAC2 by FAC1
	jmp fdivt  ; $BB12

	; Move a Floating Point Number from Memory to FAC1
	jmp movfm  ; $BBA2

	; Move a Floating Point Number from FAC1 to Memory
	jmp mov2f  ; $BBC7 -mapping-

	; pack FAC1 into (XY)
	jmp movmf  ; $BBD4

	; Move a Floating Point Number from FAC2 to FAC1
	jmp movfa  ; $BBFC

	; Round and Move a Floating Point Number from FAC1 to FAC2
	jmp movaf  ; $BC0C

	; Copy FAC1 to FAC2 Without Rounding
	jmp movef  ; $BC0F -mapping-

	; Round Accumulator #1 by Adjusting the Rounding Byte
	jmp round  ; $BC1B

	; Put the Sign of Accumulator #1 into .A Register
	jmp sign   ; $BC2B

	; Perform SGN
	jmp sgn    ; $BC39

	; ...
	jmp float  ; $BC3C

	; ...
	jmp floats ; $BC44

	; ...
	jmp floatc ; $BC49

	; ...
	jmp floatb ; $BC4F

	; Perform ABS
	jmp abs    ; $BC58

	; Compare FAC1 to Memory
	jmp fcomp  ; $BC5B

	; ...
	jmp fcompn ; $BC5D

	; Convert FAC1 into Integer Within FAC1
	jmp qint   ; $BC9B

	; Perform INT
	jmp int    ; $BCCC

	; XXX fin was removed because of
	; XXX dependencies

	; Add Signed Integer to FAC1
	jmp finlog ; $BD7E

	; XXX INPRT and LINPRT were removed because of
	; XXX dependencies

	; Convert Contents of FAC1 to ASCII String
	jmp fout   ; $BDDD

	; ...
	jmp foutc  ; $BDDF

	; ...
	jmp foutim ; $BE68

	; Perform SQR
	jmp sqr    ; $BF71

	; Performs Exponentation (Power Calculation Called for by UPARROW)
	jmp fpwrt  ; $BF7B

	; Perform NOT and >
	jmp negop  ; $BFB4

	; Perform EXP
	jmp exp    ; $BFED

	; Function Series Evaluation Subroutine 1
	; XXX
	jmp polyx  ; $E043 -mapping-

	; Function Series Evaluation Subroutine 2
	; XXX
	jmp poly   ; $E059 -mapping-

	; Perform RND
	jmp rnd    ; $E097

	; Perform COS
	jmp cos    ; $E264

	; Perform SIN
	jmp sin    ; $E26B

	; Perform TAN
	jmp tan    ; $E2B4

	; Perform ATN
	jmp atn    ; $E30E

