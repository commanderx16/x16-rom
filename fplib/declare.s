rdbas	=$fff3   ; KERNAL [XXX see comment where used]
addprc	=1
fbuffr	=$100    ; buffer for "fout".
                 ; on page 1 so that string is not copied

; XXX Dependencies on BASIC:
; XXX FPLIB should not jump to the BASIC error handler.
; XXX Instead, FP functions should return an error code,
; XXX and BASIC jumps to the error handler.
.import error, fcerr    ; code
.importzp errdvo, errov ; constants

.segment "ZPFPLIB" : zeropage

;                      C64 location
;                         VVV
index1	.res 2           ;$22 indexes
index	=index1          ;$22
index2	.res 2           ;$24

resho	.res 1           ;$26 result of multiplier and divider
resmoh	.res 1           ;$27
resmo	.res 1           ;$28
reslo	.res 1           ;$29
	.res 1           ;$2A fifth byte for res

fdecpt	.res 2           ;$47 pointer into power of tens of "fout"

tempf3	.res 5           ;$4E a third fac temporary

tempf1	.res 5           ;$57 5 bytes temp fac

tempf2	.res 5           ;$5C 5 bytes temp fac
deccnt	=tempf2+1        ;$5D number of places before decimal point
tenexp	=tempf2+2        ;$5E has a dpt been input?

; --- the floating accumulator ---:
fac                      ;$61
facexp	.res 1           ;$61
facho	.res 1           ;$62 most significant byte of mantissa
facmoh	.res 1           ;$63 one more
facmo	.res 1           ;$64 middle order of mantissa
faclo	.res 1           ;$65 least sig byte of mantissa
facsgn	.res 1           ;$66 sign of fac (0 or -1) when unpacked

degree	.res 1           ;$67 a count used by polynomials

; --- the floating argument (unpacked) ---:
argexp	.res 1           ;$69
argho	.res 1           ;$6A
argmoh	.res 1           ;$6B
argmo	.res 1           ;$6C
arglo	.res 1           ;$6D
argsgn	.res 1           ;$6E
arisgn	.res 1           ;$6F a sign reflecting the result
facov	.res 1           ;$70 overflow byte of the fac

polypt	.res 2           ;$71 pointer into polynomial coefficients.
fbufpt	=polypt          ;$71 pointer into fbuffr used by fout

.segment "FPVARS"

integr	.res 1           ;$07 a one-byte integer from "qint"
tansgn	.res 1           ;$12 used in determining sign of tangent
oldov	.res 1           ;$56 the old overflow
bits	.res 1           ;$68 something for "shiftr" to use
rndx	.res 5           ;$8B
