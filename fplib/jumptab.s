; FBLIB Jump Table

.segment "FPJMP"

; Format Conversions
	jmp ayint       ;convert FP -> int
	jmp givayf2     ;convert int -> FP
	jmp fout        ;convert FP -> string
.if 0
	; TODO: This is BASIC code, not FP code and
	;       relies on txtptr
	jmp val_1       ;convert string -> FP
.else
	sec
	rts
	nop
.endif
	jmp getadr2     ;convert FP -> address
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

