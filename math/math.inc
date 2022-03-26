;----------------------------------------------------------------------
; Floating Point Library for 6502: Include
;----------------------------------------------------------------------

; FPLIB: zero page
.importzp tenexp, facov, deccnt, argsgn, arglo, argmo, argmoh, argho, argexp, facmoh, fbufpt, faclo, facexp, facho, facsgn, index2, index1, lindex, olpolypt, olarisgn, oldegree, olfacmo, olfac, oltempf2, oltempf1, oltempf3, olfdecpt, lresmo, index, polypt, arisgn, degree, facmo, fac, tempf2, tempf1, tempf3, fdecpt, resmo

; FPLIB: constants
.importzp addprc

; FPLIB: vars
.import bits, rndx, tansgn, integr

; data
; BASIC ONLY, DO NOT USE
.import zero, fone
; XXX ideally, the FB library should be abstracted
; XXX enough so that neither of the symbols above
; XXX need to be exported

; see jumptab.s for the full documentation on these calls
ayint	= $fe00	; facmo+1:facmo = (s16)FAC
givayf2	= $fe03	; FAC = (s16).A:.Y
getadr2	= $fe06	; .A:.Y = (u16)FAC
faddh	= $fe09	; FAC += .5
fsub	= $fe0c	; FAC -= mem(.Y:.A)
fsubt	= $fe0f	; FAC -= ARG
fadd	= $fe12	; FAC += mem(.Y/.A)
faddt2	= $fe15	; FAC += ARG
faddt	= $fe18 ; BASIC ONLY, DO NOT USE
zerofc	= $fe1b	; FAC = 0
normal	= $fe1e	; Normalize FAC
negfac	= $fe21	; FAC = -FAC
log	= $fe24	; FAC = log(FAC)
fmult	= $fe27	; FAC *= mem(.Y:.A)
fmultt2	= $fe2a	; FAC *= ARG
fmultt	= $fe2d ; BASIC ONLY, DO NOT USE
conupk	= $fe30	; ARG = mem(.Y:.A) (5 bytes)
mul10	= $fe33	; FAC *= 10
div10	= $fe36	; FAC /= 10
fdiv	= $fe39	; FAC = mem(.Y:.A) / FAC
fdivt2	= $fe3c	; FAC /= ARG
fdivt	= $fe3f ; BASIC ONLY, DO NOT USE
movfm	= $fe42	; FAC = mem(.Y:.A) (5 bytes)
movmf	= $fe45	; mem(.Y:.X) = round(FAC) (5 bytes)
movfa	= $fe48	; FAC = ARG
movaf	= $fe4b	; ARG = round(FAC)
movef	= $fe4e	; ARG = FAC
round	= $fe51	; Round FAC using rounding byte
sign	= $fe54	; .A = sgn(FAC)
sgn	= $fe57	; FAC = sgn(FAC)
float	= $fe5a	; FAC = (u8).A
floats	= $fe5d	; FAC = (s16)facho+1:facho
floatc	= $fe60 ; BASIC ONLY, DO NOT USE
floatb	= $fe63 ; BASIC ONLY, DO NOT USE
abs	= $fe66	; FAC = abs(FAC)
fcomp	= $fe69	; .A = FAC == mem(.Y:.A)
fcompn	= $fe6c ; BASIC ONLY, DO NOT USE
qint	= $fe6f	; facho:facho+1:facho+2:facho+2 = u32(FAC)
int	= $fe72	; FAC = int(FAC)
;fin	= $fe75 ; XXX TODO
finlog	= $fe78	; FAC += (s8).A
fout	= $fe7b	; Convert FAC to ASCIIZ string at fbuffr
foutc	= $fe7e	; Convert FAC to ASCIIZ string at fbuffr - 1 + .Y
sqr	= $fe81	; FAC = sqr(FAC)
fpwrt2	= $fe84	; FAC = ARG^FAC
fpwrt	= $fe87 ; BASIC ONLY, DO NOT USE
negop	= $fe8a	; FAC = -FAC - 1
exp	= $fe8d	; FAC = e^FAC
polyx	= $fe90	; Polynomial Evaluation 1 (SIN/COS/ATN/LOG)
poly	= $fe93	; Polynomial Evaluation 2 (EXP)
rnd_0	= $fe96	; FAC = rnd(FAC)
cos	= $fe99	; FAC = cos(FAC)
sin	= $fe9c	; FAC = sin(FAC)
tan	= $fe9f	; FAC = tan(FAC)
atn	= $fea2	; FAC = atn(FAC)
