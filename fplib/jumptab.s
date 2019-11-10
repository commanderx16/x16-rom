; FBLIB Jump Table at $FC00

; http://unusedino.de/ec64/technical/project64/mapping_c64.html "-mapping-"
; ERRATA:
;  * faddt, tmultt and fdivt require further setup that is not documented
;  * fmult at $BA28 adds mem to FAC, not ARG to FAC
;  * fmultt at $BA2B (add ARG to FAC) is not documented


; https://codebase64.org/doku.php?id=base:asm_include_file_for_basic_routines
; https://codebase64.org/doku.php?id=base:kernal_floating_point_mathematics
; https://www.pagetable.com/c64disasm/

.segment "FPJMP"

	; facmo+1:facmo = (s16)FAC
	jmp ayint  ; $B1BF (moved from BASIC)

	; FAC = (s16).A:.Y
	; [destroys ARG]
	jmp givayf2; $B391 (variant of BASIC givayf2)

	; .A:.Y = (u16)FAC
	jmp getadr2; $B7F7 (variant of BASIC getadr)

	; FAC += .5
	jmp faddh  ; $B849 -mapping-

	; FAC -= mem(.Y:.A)
	jmp fsub   ; $B850 -mapping-

	; FAC -= ARG
	jmp fsubt  ; $B853

	; FAC += mem(.Y/.A)
	jmp fadd   ; $B867

	; FAC += ARG
	; [VARIANT OF FPLIB "faddt": This version already
	; does the sign comparicon and sets the flags according
	; to the FAC exponent before executing the original
	; "faddt" code.]
	jmp faddt2  ; $B86A

.if 0 ; useless?
	; Make the Result Negative If a Borrow Was Done
	jmp fadd3  ; $B8A7 -mapping-
.endif

	; FAC = 0
	jmp zerofc ; $B8F7

	; Normalize FAC
	jmp normal; $B8D7 [wrong address in -mappping-]

	; FAC = -FAC
	jmp negfac ; $B947 -mapping-

.if 0
	; Print Overflow Error Message
	; XXX move to BASIC?
	jmp overr  ; $B97E
.endif

	; XXX SHIFT Routine
	jmp mulshf ; $B983 -mapping-

	; FAC = log(FAC)
	jmp log    ; $B9EA

	; FAC *= mem(.Y:.A)
	jmp fmult  ; $BA28 -mapping-

	; FAC *= ARG
	; [VARIANT OF FPLIB "fmultt": This version already
	; does the sign comparicon and sets the flags according
	; to the FAC exponent before executing the original
	; "fmultt" code.]
	jmp fmultt2 ; $BA2B

	; FAC += .A * ARG
	jmp mltply ; $BA59 -mapping-

	; ARG = mem(.Y:.A) (5 bytes)
	jmp conupk ; $BA8C -mapping-

	; Add Exponent of FAC1 to Exponent of FAC2
	jmp muldiv ; $BAB7 -mapping-

	; Handle Underflow or Overflow
	jmp mldvex ; $BAD4 -mapping-

	; FAC *= 10
	jmp mul10  ; $BAE2

	; ???
	jmp finml6 ; $BAED

	; FAC /= 10
	; "Note: This routine treats FAC1 as positive even if it is not."
	jmp div10  ; $BAFE

	; FAC = mem(.Y:.A) / FAC
	jmp fdiv   ; $BB0F -mapping-

	; FAC /= ARG
	; [VARIANT OF FPLIB "fdivt": This version already
	; does the sign comparicon and sets the flags according
	; to the FAC exponent before executing the original
	; "fdivt" code.]
	jmp fdivt2 ; $BB12

	; FAC = mem(.Y:.A) (5 bytes)
	jmp movfm  ; $BBA2

	; Move a Floating Point Number from FAC1 to Memory
	jmp mov2f  ; $BBC7 -mapping-

	; mem(.Y:.X) = round(FAC) (5 bytes)
	jmp movmf  ; $BBD4

	; FAC = ARG
	jmp movfa  ; $BBFC

	; ARG = round(FAC)
	jmp movaf  ; $BC0C

	; ARG = FAC
	jmp movef  ; $BC0F -mapping-

	; Round Accumulator #1 by Adjusting the Rounding Byte
	jmp round  ; $BC1B

	; .A = sgn(FAC)
	jmp sign   ; $BC2B

	; FAC = sgn(FAC)
	jmp sgn    ; $BC39

	; FAC = (u8).A
	; [destroys ARG]
	jmp float  ; $BC3C

	; FAC = (s16)facho+1:facho
	; [destroys ARG]
	jmp floats ; $BC44

	; ...
	jmp floatc ; $BC49

	; ...
	jmp floatb ; $BC4F

	; FAC = abs(FAC)
	jmp abs    ; $BC58

	; .A = FAC == mem(.Y:.A)
	jmp fcomp  ; $BC5B

	; ...
	jmp fcompn ; $BC5D

	; Convert FAC1 into Integer Within FAC1
	jmp qint   ; $BC9B

	; FAC = int(FAC)
	jmp int    ; $BCCC

	; fin ($BCF3) was removed because of
	; the dependency on CHRGET

	; Add Signed Integer to FAC1
	jmp finlog ; $BD7E

	; Convert FAC to ASCIIZ string at fbuffr
	jmp fout   ; $BDDD

	; Convert FAC to ASCIIZ string at fbuffr - 1 + .Y
	; [used by BASIC]
	jmp foutc  ; $BDDF

	; convert TI to TI$
	; [used by BASIC]
	jmp foutim ; $BE68

	; FAC = sqr(FAC)
	jmp sqr    ; $BF71

	; FAC = ARG^FAC
	jmp fpwrt  ; $BF7B

	; Perform NOT and >
	jmp negop  ; $BFB4

	; FAC = e^FAC
	jmp exp    ; $BFED

	; Polynomial Evaluation 1 (SIN/COS/ATN/LOG)
	jmp polyx  ; $E043 -mapping-

	; Polynomial Evaluation 2 (EXP)
	jmp poly   ; $E059 -mapping-

	; FAC = rnd(FAC)
	jmp rnd    ; $E097

	; FAC = cos(FAC)
	; [destroys ARG]
	jmp cos    ; $E264

	; FAC = sin(FAC)
	; [destroys ARG]
	jmp sin    ; $E26B

	; FAC = tan(FAC)
	; [destroys ARG]
	jmp tan    ; $E2B4

	; FAC = atn(FAC)
	; [destroys ARG]
	jmp atn    ; $E30E

