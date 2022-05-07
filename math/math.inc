;----------------------------------------------------------------------
; Floating Point Library for 6502: Include
;----------------------------------------------------------------------

; MATH: zero page
.importzp tenexp, facov, deccnt, argsgn, arglo, argmo, argmoh, argho, argexp, facmoh, fbufpt, faclo, facexp, facho, facsgn, index2, index1, lindex, olpolypt, olarisgn, oldegree, olfacmo, olfac, oltempf2, oltempf1, oltempf3, olfdecpt, lresmo, index, polypt, arisgn, degree, facmo, fac, tempf2, tempf1, tempf3, fdecpt, resmo

; MATH: constants
.importzp addprc

; MATH: vars
.import bits, rndx, tansgn, integr

; data
; BASIC ONLY, DO NOT USE
.import zero, fone
; XXX ideally, the FB library should be abstracted
; XXX enough so that neither of the symbols above
; XXX need to be exported

; see jumptab.s for the full documentation on these calls
; Format Conversions
ayint	= $fe00 ; facmo+1:facmo = (s16)FAC
givayf	= $fe03 ; FAC = (s16).A:.Y
fout	= $fe06 ; Convert FAC to ASCIIZ string at fbuffr
val_1	= $fe09 ;
getadr	= $fe0c ; .A:.Y = (u16)FAC
floatc	= $fe0f ; C128 API, use floats instead
; Math Functions
fsub	= $fe12 ; FAC -= mem(.Y:.A)
fsubt	= $fe15 ; FAC -= ARG
fadd	= $fe18 ; FAC += mem(.Y/.A)
faddt	= $fe1b ; FAC += ARG
fmult	= $fe1e ; FAC *= mem(.Y:.A)
fmultt	= $fe21 ; FAC *= ARG
fdiv	= $fe24 ; FAC = mem(.Y:.A) / FAC
fdivt	= $fe27 ; FAC /= ARG
log	= $fe2a ; FAC = log(FAC)
int	= $fe2d ; FAC = int(FAC)
sqr	= $fe30 ; FAC = sqr(FAC)
negop	= $fe33 ; FAC = -FAC - 1
fpwr	= $fe36 ;
fpwrt	= $fe39 ; FAC = ARG^FAC
exp	= $fe3c ; FAC = e^FAC
cos	= $fe3f ; FAC = cos(FAC)
sin	= $fe42 ; FAC = sin(FAC)
tan	= $fe45 ; FAC = tan(FAC)
atn	= $fe48 ; FAC = atn(FAC)
round	= $fe4b ; Round FAC using rounding byte
abs	= $fe4e ; FAC = abs(FAC)
sign	= $fe51 ; .A = sgn(FAC)
fcomp	= $fe54 ; .A = FAC == mem(.Y:.A)
rnd_0	= $fe57 ; FAC = rnd(FAC)
; Movement
conupk	= $fe5a ; ARG = mem(.Y:.A) (5 bytes)
romupk	= $fe5d ;
movfrm	= $fe60 ;
movfm	= $fe63 ; FAC = mem(.Y:.A) (5 bytes)
movmf	= $fe66 ; mem(.Y:.X) = round(FAC) (5 bytes)
movfa	= $fe69 ; FAC = ARG
movaf	= $fe6c ; ARG = round(FAC)
; X16 additions
faddh	= $fe6f ; FAC += .5
zerofc	= $fe72 ; FAC = 0
normal	= $fe75 ; Normalize FAC
negfac	= $fe78 ; FAC = -FAC
mul10	= $fe7b ; FAC *= 10
div10	= $fe7e ; FAC /= 10
movef	= $fe81 ; ARG = FAC
sgn	= $fe84 ; FAC = sgn(FAC)
float	= $fe87 ; FAC = (u8).A
floats	= $fe8a ; FAC = (s16)facho+1:facho
qint	= $fe8d ; facho:facho+1:facho+2:facho+2 = u32(FAC)
finlog	= $fe90 ; FAC += (s8).A
foutc	= $fe93 ; Convert FAC to ASCIIZ string at fbuffr - 1 + .Y
polyx	= $fe96 ; Polynomial Evaluation 1 (SIN/COS/ATN/LOG)
poly	= $fe99 ; Polynomial Evaluation 2 (EXP)
.if 0 ; XXX see comment in jumptab.s
; X16 additions - BASIC only
bfaddt	= $fe9c ; BASIC ONLY, DO NOT USE
bfmultt	= $fe9f ; BASIC ONLY, DO NOT USE
bfdivt	= $fea2 ; BASIC ONLY, DO NOT USE
bfpwrt	= $fea5 ; BASIC ONLY, DO NOT USE
floatb	= $fea8 ; BASIC ONLY, DO NOT USE
fcompn	= $feab ; BASIC ONLY, DO NOT USE
.else
.import bfaddt
.import bfmultt
.import bfdivt
.import bfpwrt
.import floatb
.import fcompn
.endif
