
; FPLIB: zero page
.importzp tenexp, facov, deccnt, argsgn, arglo, argmo, argmoh, argho, argexp, facmoh, fbufpt, faclo, facexp, facho, facsgn, index2, index1, lindex, olpolypt, olarisgn, oldegree, olfacmo, olfac, oltempf2, oltempf1, oltempf3, olfdecpt, lresmo, index, polypt, arisgn, degree, facmo, fac, tempf2, tempf1, tempf3, fdecpt, resmo

; FPLIB: constants
.importzp addprc

; FPLIB: vars
.import bits, rndx, tansgn, integr

; data
; BASIC ONLY, DO NOT USE
.import foutbl, fdcend, zero, fone

; XXX ideally, the FB library should be abstracted
; XXX enough so that none of the symbols above
; XXX need to be exported

; see jumptab.s for the full documentation on these calls
ayint	= $fc00	; facmo+1:facmo = (s16)FAC
givayf2	= $fc03	; FAC = (s16).A:.Y
getadr2	= $fc06	; .A:.Y = (u16)FAC
faddh	= $fc09	; FAC += .5
fsub	= $fc0c	; FAC -= mem(.Y:.A)
fsubt	= $fc0f	; FAC -= ARG
fadd	= $fc12	; FAC += mem(.Y/.A)
faddt2	= $fc15	; FAC += ARG
faddt	= $fc18 ; BASIC ONLY, DO NOT USE
zerofc	= $fc1b	; FAC = 0
normal	= $fc1e	; Normalize FAC
negfac	= $fc21	; FAC = -FAC
log	= $fc24	; FAC = log(FAC)
fmult	= $fc27	; FAC *= mem(.Y:.A)
fmultt2	= $fc2a	; FAC *= ARG
fmultt	= $fc2d ; BASIC ONLY, DO NOT USE
mltply	= $fc30	; FAC += .A * ARG
conupk	= $fc33	; ARG = mem(.Y:.A) (5 bytes)
mul10	= $fc36	; FAC *= 10
finml6	= $fc39	; FAC = 2 * (FAC + ARG)
div10	= $fc3c	; FAC /= 10
fdiv	= $fc3f	; FAC = mem(.Y:.A) / FAC
fdivt2	= $fc42	; FAC /= ARG
fdivt	= $fc45 ; BASIC ONLY, DO NOT USE
movfm	= $fc48	; FAC = mem(.Y:.A) (5 bytes)
movmf	= $fc4b	; mem(.Y:.X) = round(FAC) (5 bytes)
movfa	= $fc4e	; FAC = ARG
movaf	= $fc51	; ARG = round(FAC)
movef	= $fc54	; ARG = FAC
round	= $fc57	; Round FAC using rounding byte
sign	= $fc5a	; .A = sgn(FAC)
sgn	= $fc5d	; FAC = sgn(FAC)
float	= $fc60	; FAC = (u8).A
floats	= $fc63	; FAC = (s16)facho+1:facho
floatc	= $fc66 ; BASIC ONLY, DO NOT USE
floatb	= $fc69 ; BASIC ONLY, DO NOT USE
abs	= $fc6c	; FAC = abs(FAC)
fcomp	= $fc6f	; .A = FAC == mem(.Y:.A)
fcompn	= $fc72 ; BASIC ONLY, DO NOT USE
qint	= $fc75	; facho:facho+1:facho+2:facho+2 = u32(FAC)
int	= $fc78	; FAC = int(FAC)
;fin	= $fc7b ; XXX TODO
finlog	= $fc7e	; FAC += (s8).A
fout	= $fc81	; Convert FAC to ASCIIZ string at fbuffr
foutc	= $fc84	; Convert FAC to ASCIIZ string at fbuffr - 1 + .Y
foutim	= $fc87	; convert TI to TI$
sqr	= $fc8a	; FAC = sqr(FAC)
fpwrt2	= $fc8d	; FAC = ARG^FAC
fpwrt	= $fc90 ; BASIC ONLY, DO NOT USE
negop	= $fc93	; FAC = -FAC - 1
exp	= $fc96	; FAC = e^FAC
polyx	= $fc99	; Polynomial Evaluation 1 (SIN/COS/ATN/LOG)
poly	= $fc9c	; Polynomial Evaluation 2 (EXP)
rnd2	= $fc9f	; FAC = rnd(A)
rnd	= $fca2	; FAC = rnd(FAC)
cos	= $fca5	; FAC = cos(FAC)
sin	= $fca8	; FAC = sin(FAC)
tan	= $fcab	; FAC = tan(FAC)
atn	= $fcae	; FAC = atn(FAC)
