.feature labels_without_colons, pc_assignment

.include "declare.s"
.include "exports.s"

.segment "FPLIB"

; Format Conversions
	jmp ayint       ;convert FP -> int
	jmp givayf2     ;convert int -> FP
	jmp fout        ;convert FP -> string
;XXX	jmp val_1       ;convert string -> FP
;XXX	jmp getadr      ;convert FP -> address
	jmp floatc      ;convert address -> FP

; Movement
	jmp conupk      ;move MEM -> ARG
	jmp movfm       ;move MEM -> FAC
	jmp movmf       ;move FAC -> MEM
	jmp movfa       ;move ARG -> FAC
	jmp movaf       ;move FAC -> ARG

; Math Functions
	jmp fsub        ;MEM - FAC
	jmp fsubt       ;ARG - FAC
	jmp fadd        ;MEM + FAC
;	jmp faddt_c65   ;ARG - FAC
	jmp fmult       ;MEM * FAC
;	jmp fmultt_c65  ;ARG * FAC
	jmp fdiv        ;MEM / FAC
;	jmp fdivt_c65   ;ARG / FAC
	jmp log         ;compute natural log of FAC
	jmp int         ;perform INT() on FAC
	jmp sqr         ;compute square root of FAC
	jmp negop       ;negate FAC
	jmp fpwrt       ;raise ARG to the FAC power
	jmp exp         ;compute EXP of FAC
	jmp cos         ;compute COS of FAC
	jmp sin         ;compute SIN of FAC
	jmp tan         ;compute TAN of FAC
	jmp atn         ;compute ATN of FAC
	jmp round       ;round FAC
	jmp abs         ;absolute value of FAC
	jmp sign        ;test sign of FAC
	jmp fcomp       ;compare FAC with MEM
	jmp rnd_0       ;generate random floating point number

.include "code18.s"
.include "code19.s"
.include "code20.s"
.include "code21.s"
.include "code22.s"
.include "code23.s"
.include "code24.s"
.include "code25.s"
.include "trig.s"
