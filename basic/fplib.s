.feature labels_without_colons, pc_assignment

rdbas	=$fff3

; BVARS
.import tansgn   ; used by trig.s; BASIC: synonym of 'domask'
.import bits     ; used by code18.s, code21.s; BASIC: init.s
.import integr   ; used by code21.s, code23.s, code25.s;
                 ; BASIC: code10.s; synonym of 'charac'
.import oldov    ; used by code18.s; code25.s
.import rndx     ; used by code25.s; BASIC: init.s

; CODE
.import error    ; "... ERROR"
                 ; used by code18.s, code19.s
.import fcerr    ; "ILLEGAL QUANTITY"
                 ; used by code19.s

; STRTMP
.importzp fbuffr ; used by code22.s, code23.s

; constant
.importzp errdvo ; code19.s
.importzp errov  ; code18.s
.importzp addprc

.importzp forpnt ; ZPBASIC

.segment "ZPBASIC" : zeropage ; FPLIB

index1	.res 2           ;$22 [FP] indexes
index	=index1          ;$22 [FP]
index2	.res 2           ;$24 [FP]

resho	.res 1           ;$26 [FP] result of multiplier and divider
resmoh	.res 1           ;$27 [FP]
resmo	.res 1           ;$28 [FP]
reslo	.res 1           ;$29 [FP]
	.res 1           ;$2A [FP] fifth byte for res

fdecpt	.res 2           ;$47 [FP] pointer into power of tens of "fout"

tempf3	.res 5           ;$4E [FP] a third fac temporary

tempf1	.res 5           ;$57 [FP] 5 bytes temp fac

tempf2	.res 5           ;$5C [FP] 5 bytes temp fac
deccnt	=tempf2+1        ;$5D [FP] number of places before decimal point
tenexp	=tempf2+2        ;$5E [FP] has a dpt been input?

fac                      ;$61 [FP]
facexp	.res 1           ;$61 [FP]
facho	.res 1           ;$62 [FP] most significant byte of mantissa
facmoh	.res 1           ;$63 [FP] one more
facmo	.res 1           ;$64 [FP] middle order of mantissa
faclo	.res 1           ;$65 [FP] least sig byte of mantissa
facsgn	.res 1           ;$66 [FP] sign of fac (0 or -1) when unpacked

degree	.res 1           ;$67 [FP] a count used by polynomials

argexp	.res 1           ;$69 [FP]
argho	.res 1           ;$6A [FP]
argmoh	.res 1           ;$6B [FP]
argmo	.res 1           ;$6C [FP]
arglo	.res 1           ;$6D [FP]
argsgn	.res 1           ;$6E [FP]
arisgn	.res 1           ;$6F [FP] a sign reflecting the result
facov	.res 1           ;$70 [FP] overflow byte of the fac

polypt	.res 2           ;$71 [FP] pointer into polynomial coefficients.
fbufpt	=polypt          ;$71 [FP] pointer into fbuffr used by fout


.global zerofc, foutc, movmf, floats, fcomp, movfa, float, floatb, foutim, foutbl, fdcend, overr, fin, fcompn, fadd, finh, fout, qint, finml6, movaf, mul10, zero, movvf, round, sign, movfm, fone, negop, fpwrt, fdivt, fmultt, fsubt, faddt, atn, tan, sin, cos, exp, log, rnd, sqr, abs, int, sgn, div10, finlog, floatc

.global degree, polypt, fbufpt, tempf3, fdecpt, tenexp, deccnt, index2, forpnt, tempf1, tempf2, index, index1, resho, resmoh, resmo, reslo, argexp, argho, argmoh, argmo, arglo, argsgn, arisgn, fac, facexp, facho, facmoh, facmo, faclo, facsgn, facov

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
