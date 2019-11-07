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
.import strout   ; PRINT THE STRING POINTED TO BY [Y,A] WHICH ENDS WITH A ZERO.
                 ; used by code22.s
.import error    ; "... ERROR"
                 ; used by code18.s, code19.s
.import fcerr    ; "ILLEGAL QUANTITY"
                 ; used by code19.s
.import frmevl   ; FORMULA EVALUATOR
                 ; used by code21.s; X16 addition for $/% support

; STRTMP
.importzp fbuffr ; used by code22.s, code23.s

; ZPBASIC
.importzp degree ; code25.s; synonym of 'sgnflg': code21.s
.importzp polypt ; code25.s
.importzp tempf3 ; code23.s, trig.s; BASIC: synonym of 'defpnt'
.importzp fdecpt ; code22.s; BASIC: synonym of 'varpnt'
.importzp fbufpt ; code22.s; BASIC: synonym of 'bufptr', 'strng2', ...
.importzp txtptr ; code21.s; BASIC: owned
.importzp dptflg ; code21.s; BASIC: synonym of 'lowtr'
.importzp expsgn ; code21.s; BASIC: synonym of 'lowtr'
.importzp tenexp ; code21.s, code22.s
.importzp plustk
.importzp minutk
.importzp chrget
.importzp sgnflg
.importzp deccnt
.importzp index2
.importzp forpnt
.importzp tempf1
.importzp tempf2
.importzp errdvo
.importzp index
.importzp index1
.importzp reslo
.importzp resmo
.importzp resmoh
.importzp resho
.importzp errov
.importzp argho
.importzp argmoh
.importzp argmo
.importzp arglo
.importzp facho
.importzp facmoh
.importzp facmo
.importzp faclo
.importzp addprc
.importzp fac
.importzp argexp
.importzp facov
.importzp facexp
.importzp arisgn
.importzp argsgn
.importzp facsgn

.global zerofc, foutc, movmf, floats, fcomp, movfa, float, floatb, foutim, foutbl, fdcend, overr, fin, fcompn, fadd, finh, fout, qint, finml6, movaf, mul10, zero, movvf, round, sign, movfm, fone, linprt, negop, fpwrt, fdivt, fmultt, fsubt, faddt, atn, tan, sin, cos, exp, log, rnd, sqr, abs, int, sgn, div10, finlog

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
