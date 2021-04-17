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
;	= $fe30	; [removed]
conupk	= $fe33	; ARG = mem(.Y:.A) (5 bytes)
mul10	= $fe36	; FAC *= 10
;	= $fe39	; [removed]
div10	= $fe3c	; FAC /= 10
fdiv	= $fe3f	; FAC = mem(.Y:.A) / FAC
fdivt2	= $fe42	; FAC /= ARG
fdivt	= $fe45 ; BASIC ONLY, DO NOT USE
movfm	= $fe48	; FAC = mem(.Y:.A) (5 bytes)
movmf	= $fe4b	; mem(.Y:.X) = round(FAC) (5 bytes)
movfa	= $fe4e	; FAC = ARG
movaf	= $fe51	; ARG = round(FAC)
movef	= $fe54	; ARG = FAC
round	= $fe57	; Round FAC using rounding byte
sign	= $fe5a	; .A = sgn(FAC)
sgn	= $fe5d	; FAC = sgn(FAC)
float	= $fe60	; FAC = (u8).A
floats	= $fe63	; FAC = (s16)facho+1:facho
floatc	= $fe66 ; BASIC ONLY, DO NOT USE
floatb	= $fe69 ; BASIC ONLY, DO NOT USE
abs	= $fe6c	; FAC = abs(FAC)
fcomp	= $fe6f	; .A = FAC == mem(.Y:.A)
fcompn	= $fe72 ; BASIC ONLY, DO NOT USE
qint	= $fe75	; facho:facho+1:facho+2:facho+2 = u32(FAC)
int	= $fe78	; FAC = int(FAC)
;fin	= $fe7b ; XXX TODO
finlog	= $fe7e	; FAC += (s8).A
fout	= $fe81	; Convert FAC to ASCIIZ string at fbuffr
foutc	= $fe84	; Convert FAC to ASCIIZ string at fbuffr - 1 + .Y
;	= $fe87	; [removed]
sqr	= $fe8a	; FAC = sqr(FAC)
fpwrt2	= $fe8d	; FAC = ARG^FAC
fpwrt	= $fe90 ; BASIC ONLY, DO NOT USE
negop	= $fe93	; FAC = -FAC - 1
exp	= $fe96	; FAC = e^FAC
polyx	= $fe99	; Polynomial Evaluation 1 (SIN/COS/ATN/LOG)
poly	= $fe9c	; Polynomial Evaluation 2 (EXP)
rnd2	= $fe9f	; FAC = rnd(A)
rnd	= $fea2	; FAC = rnd(FAC)
cos	= $fea5	; FAC = cos(FAC)
sin	= $fea8	; FAC = sin(FAC)
tan	= $feab	; FAC = tan(FAC)
atn	= $feae	; FAC = atn(FAC)
