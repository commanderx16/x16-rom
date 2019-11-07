.feature labels_without_colons, pc_assignment

rdbas	=$fff3

; CODE
.import error    ; "... ERROR"
                 ; used by code18.s, code19.s
.import fcerr    ; "ILLEGAL QUANTITY"
                 ; used by code19.s

fbuffr	=$100    ; buffer for "fout".
                 ; on page 1 so that string is not copied

; constants
.importzp errdvo ; code19.s
.importzp errov  ; code18.s
.importzp addprc

.importzp forpnt ; ZPBASIC

.segment "ZPBASIC" : zeropage ; FPLIB

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

fac                      ;$61
facexp	.res 1           ;$61
facho	.res 1           ;$62 most significant byte of mantissa
facmoh	.res 1           ;$63 one more
facmo	.res 1           ;$64 middle order of mantissa
faclo	.res 1           ;$65 least sig byte of mantissa
facsgn	.res 1           ;$66 sign of fac (0 or -1) when unpacked

degree	.res 1           ;$67 a count used by polynomials

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

.segment "BVARS"

integr	.res 1           ;$07 a one-byte integer from "qint"
tansgn	.res 1           ;$12 used in determining sign of tangent
oldov	.res 1           ;$56 the old overflow
bits	.res 1           ;$68 something for "shiftr" to use
rndx	.res 5           ;$8B

.global zerofc, foutc, movmf, floats, fcomp, movfa, float, floatb, foutim, foutbl, fdcend, overr, fin, fcompn, fadd, finh, fout, qint, finml6, movaf, mul10, zero, movvf, round, sign, movfm, fone, negop, fpwrt, fdivt, fmultt, fsubt, faddt, atn, tan, sin, cos, exp, log, rnd, sqr, abs, int, sgn, div10, finlog, floatc

.global degree, polypt, fbufpt, tempf3, fdecpt, tenexp, deccnt, index2, tempf1, tempf2, index, index1, resho, resmoh, resmo, reslo, argexp, argho, argmoh, argmo, arglo, argsgn, arisgn, fac, facexp, facho, facmoh, facmo, faclo, facsgn, facov

.global bits, rndx, tansgn, integr

.segment "BASIC"

.include "code18.s"
.include "code19.s"
.include "code20.s"
.include "code21.s"
.include "code22.s"
.include "code23.s"
.include "code24.s"
.include "code25.s"
.include "trig.s"
