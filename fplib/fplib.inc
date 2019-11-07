; FPLIB: code
.import zerofc, foutc, movmf, floats, fcomp, movfa, float, floatb, foutim, foutbl, fdcend, overr, fcompn, fadd, fout, qint, finml6, movaf, mul10, zero, round, sign, movfm, fone, negop, fpwrt, fdivt, fmultt, fsubt, faddt, atn, tan, sin, cos, exp, log, rnd, sqr, abs, int, sgn, div10, finlog, floatc

; FPLIB: zero page
.importzp tenexp, facov, deccnt, argsgn, arglo, argmo, argmoh, argho, argexp, facmoh, fbufpt, faclo, facexp, facho, facsgn, index2, index1, lindex, olpolypt, olarisgn, oldegree, olfacmo, olfac, oltempf2, oltempf1, oltempf3, olfdecpt, lresmo, index, polypt, arisgn, degree, facmo, fac, tempf2, tempf1, tempf3, fdecpt, resmo

; FPLIB: constants
.importzp addprc

; FPLIB: vars
.import bits, rndx, tansgn, integr

