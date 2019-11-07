.feature labels_without_colons, pc_assignment

.include "../banks.inc"

; FPLIB: code
.import zerofc, foutc, movmf, floats, fcomp, movfa, float, floatb, foutim, foutbl, fdcend, overr, fcompn, fadd, fout, qint, finml6, movaf, mul10, zero, movvf, round, sign, movfm, fone, negop, fpwrt, fdivt, fmultt, fsubt, faddt, atn, tan, sin, cos, exp, log, rnd, sqr, abs, int, sgn, div10, finlog, floatc

; FPLIB: zero page
.importzp tenexp, facov, deccnt, argsgn, arglo, argmo, argmoh, argho, argexp, facmoh, fbufpt, faclo, facexp, facho, facsgn, index2, index1, lindex, olpolypt, olarisgn, oldegree, olfacmo, olfac, oltempf2, oltempf1, oltempf3, olfdecpt, lresmo, index, polypt, arisgn, degree, facmo, fac, tempf2, tempf1, tempf3, fdecpt, resmo

; FPLIB: vars
.import bits, rndx, tansgn, integr

; constants for FPLIB
.global errdvo, errov, addprc

; zero page for FPLIB
.global forpnt

; code for FPLIB
.global error, fcerr

.include "declare.s"
.include "tokens.s"
.include "token2.s"
.include "code1.s"
.include "code2.s"
.include "code3.s"
.include "code4.s"
.include "code5.s"
.include "code6.s"
.include "code7.s"
.include "code8.s"
.include "code9.s"
.include "code10.s"
.include "code11.s"
.include "code12.s"
.include "code13.s"
.include "code14.s"
.include "code15.s"
.include "code16.s"
.include "code17.s"
.include "code26.s"
.include "init.s"
.include "x16additions.s"
.include "geos.s"

