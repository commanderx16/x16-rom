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

; ZPBASIC
.importzp degree ; code25.s; synonym of 'sgnflg': code21.s
.importzp polypt ; code25.s; BASIC: synonym of 'bufptr', 'strng2', ...
.importzp fbufpt ; code22.s; BASIC: used, synonym of 'bufptr', 'strng2', ...
.importzp tempf3 ; code23.s, trig.s; BASIC: synonym of 'defpnt'
.importzp fdecpt ; code22.s; BASIC: synonym of 'varpnt'
.importzp tenexp ; code21.s, code22.s
.importzp deccnt ; code22.s; BASIC: used
.importzp index2 ; code22.s; BASIC: used
.importzp forpnt ; code20.s; BASIC: *owned*
.importzp tempf1 ; code20.s, code25.s, trig.s
.importzp tempf2 ; code20.s, code25.s
.importzp index  ; code19.s, code20.s; BASIC: used
.importzp index1 ; code19.s, code20.s, code25.s, code26.s; BASIC: used
.importzp resho  ; code18.s, code19.s, code20.s
.importzp resmoh ; code19.s, code20.s
.importzp resmo  ; code19.s; code20.s; BASIC: synonym of 'addend'
.importzp reslo  ; code19.s; code20.s; BASIC: synonym of 'addend'+1
.importzp argexp ; ...; BASIC: used
.importzp argho  ; code18.s; code18.s; BASIC: used
.importzp argmoh ; code18.s; code18.s; BASIC: used
.importzp argmo  ; code18.s; code18.s; BASIC: used
.importzp arglo  ; code18.s; code18.s; BASIC: used
.importzp argsgn ; code18.s; code18.s, ...; BASIC: used
.importzp arisgn ; code18.s; code18.s, ...; BASIC: used; synonym of 'strng1'
.importzp fac    ; ...; BASIC: used
.importzp facexp ; ...; BASIC: used
.importzp facho  ; ...; BASIC: used
.importzp facmoh ; ...; BASIC: used
.importzp facmo  ; ...; BASIC: used
.importzp faclo  ; ...; BASIC: used
.importzp facsgn ; ...; BASIC: used
.importzp facov  ; ...; BASIC: used

; constant
.importzp errdvo ; code19.s
.importzp errov  ; code18.s
.importzp addprc

.global zerofc, foutc, movmf, floats, fcomp, movfa, float, floatb, foutim, foutbl, fdcend, overr, fin, fcompn, fadd, finh, fout, qint, finml6, movaf, mul10, zero, movvf, round, sign, movfm, fone, negop, fpwrt, fdivt, fmultt, fsubt, faddt, atn, tan, sin, cos, exp, log, rnd, sqr, abs, int, sgn, div10, finlog, floatc

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
