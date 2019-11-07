.feature labels_without_colons, pc_assignment

.include "../banks.inc"

.import zerofc, foutc, movmf, floats, fcomp, movfa, float, floatb, foutim, foutbl, fdcend, overr, fcompn, fadd, fout, qint, finml6, movaf, mul10, zero, movvf, round, sign, movfm, fone, negop, fpwrt, fdivt, fmultt, fsubt, faddt, atn, tan, sin, cos, exp, log, rnd, sqr, abs, int, sgn, div10, finlog, floatc

.importzp tenexp, facov, deccnt, argsgn, arglo, argmo, argmoh, argho, argexp, facmoh, fbufpt, faclo, facexp, facho, facsgn, index2, index1, lindex, olpolypt, olarisgn, oldegree, olfacmo, olfac, oltempf2, oltempf1, oltempf3, olfdecpt, lresmo, index, polypt, arisgn, degree, facmo, fac, tempf2, tempf1, tempf3, fdecpt, resmo

.global errdvo, errov, addprc

.global forpnt

.global tansgn   ; used by trig.s; BASIC: synonym of 'domask'
.global bits     ; used by code18.s, code21.s; BASIC: init.s
.global integr   ; used by code21.s, code23.s, code25.s;
                 ; BASIC: code10.s; synonym of 'charac'
.global oldov    ; used by code18.s; code25.s
.global rndx     ; used by code25.s; BASIC: init.s
.global error    ; "... ERROR"
                 ; used by code18.s, code19.s
.global fcerr    ; "ILLEGAL QUANTITY"
                 ; used by code19.s
.global fbuffr ; used by code22.s, code23.s


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

