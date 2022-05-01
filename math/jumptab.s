;----------------------------------------------------------------------
; Floating Point Library for 6502
;----------------------------------------------------------------------

; FBLIB Jump Table
;
; This jump table aims for compatibility with the C128/C65 one.
;
; *** C128 difference: faddt, fmultt, fdivt, fpwrt:
; The original functions require further setup that is not documented
; in [-mapping-] or the C128/C65 Math library reference (sign
; comparison, setting the flags according to the FAC exponent).
; The extra work can only be done with access to internals of the
; library, and without it, these functions are useless. That's why
; replacement functions have been added, with the same names (and
; marked as "FIXED VERSION") which do the extra setup. BASIC still
; calls into the original versions, so these are exposed in this jump table as well, with "b" prepended to their names.
; ("fsubt" doesn't need the fix: It is the only one that does the
; extra setup!)
; More info: https://www.c64-wiki.de/wiki/FADDT

; Routines marked with "[-mapping-]" have been added because they
; are documented in "Mapping the Commodore 64" and therefore likely
; useful or even used by existing C64 code.
; The following routines documented by [-mapping-] were omitted,
; because they don't seem useful:
; * fadd3 at $B8A7 (documented incorrectly as fadd4)
; * mulshf at $B983
; * muldiv at $BAB7
; * mldvex at $BAD4
; * mov2f  at $BBC7

; Sources:
; http://www.zimmers.net/anonftp/pub/cbm/schematics/computers/c128/servicemanuals/C128_Developers_Package_for_Commodore_6502_Development_(1987_Oct).pdf
; http://www.zimmers.net/anonftp/pub/cbm/manuals/c65/c65manualupdated.txt
; https://codebase64.org/doku.php?id=base:asm_include_file_for_basic_routines
; https://codebase64.org/doku.php?id=base:kernal_floating_point_mathematics
; https://www.pagetable.com/c64ref/c64disasm/
; http://unusedino.de/ec64/technical/project64/mapping_c64.html "[-mapping-]"
; ERRATA:
;  * fmult at $BA28 adds mem to FAC, not ARG to FAC
;  * fmultt at $BA2B (add ARG to FAC) is not documented
;  * normal at $B8D7 is incorrectly documented as being at $B8FE

.segment "FPJMP"

; Format Conversions

	; facmo+1:facmo = (s16)FAC
	; [this routine was moved from BASIC]
	jmp ayint  ; $B1BF

	; FAC = (s16).A:.Y
	; [*** C128 difference: does not set BASIC's
	; "valtyp" variable.]
	; [destroys ARG]
	jmp givayf; $B391

	; Convert FAC to ASCIIZ string at fbuffr
	jmp fout   ; $BDDD

	; XXX VAL_1, a frontend to fin ($BCF3) is missing
	; XXX because of the dependency on CHRGET.
	; XXX We should add it after removing the
	; XXX depencency.
	.byte 0,0,0

	; .A:.Y = (u16)FAC
	; [*** C128 difference: does not store the
	; result in BASIC's "poker" variable.]
	jmp getadr; $B7F7

	; [used by BASIC]
	jmp floatc ; $BC49

; Math Functions

	; FAC -= mem(.Y:.A)
	jmp fsub   ; $B850

	; FAC -= ARG
	jmp fsubt  ; $B853

	; FAC += mem(.Y/.A)
	jmp fadd   ; $B867

	; FAC += ARG
	; [FIXED VERSION of "faddt2"]
	jmp faddt

	; FAC *= mem(.Y:.A)
	jmp fmult  ; $BA28

	; FAC *= ARG
	; [FIXED VERSION of "fmultt2"]
	jmp fmultt

	; FAC = mem(.Y:.A) / FAC
	jmp fdiv   ; $BB0F

	; FAC /= ARG
	; [FIXED VERSION of "fdivt2"]
	jmp fdivt

	; FAC = log(FAC)
	jmp log    ; $B9EA

	; FAC = int(FAC)
	jmp int    ; $BCCC

	; FAC = sqr(FAC)
	jmp sqr    ; $BF71

	; FAC = -FAC - 1
	jmp negop  ; $BFB4

	; C128 API addition
	jmp fpwr

	; FAC = ARG^FAC
	; [FIXED VERSION of "fpwrt2"]
	jmp fpwrt

	; FAC = e^FAC
	jmp exp    ; $BFED

	; FAC = cos(FAC)
	; [destroys ARG]
	jmp cos    ; $E264

	; FAC = sin(FAC)
	; [destroys ARG]
	jmp sin    ; $E26B

	; FAC = tan(FAC)
	; [destroys ARG]
	jmp tan    ; $E2B4

	; FAC = atn(FAC)
	; [destroys ARG]
	jmp atn    ; $E30E

	; Round FAC using rounding byte
	jmp round  ; $BC1B

	; FAC = abs(FAC)
	jmp abs    ; $BC58

	; .A = sgn(FAC)
	jmp sign   ; $BC2B

	; .A = FAC == mem(.Y:.A)
	jmp fcomp  ; $BC5B

	; FAC = rnd(.P)
	; for .Z=1, the entropy in .A/.X/.Y is used
	; [*** C128 difference: for .Z=1, the C128 version
	; reads entropy from the CIA timers instead of taking
	; it from .A/.X/.Y.]
	jmp rnd_0  ; $E097

; Movement

	; ARG = mem(.Y:.A) (5 bytes)
	jmp conupk ; $BA8C

	; [*** C128/C65 has RAM and ROM version, which we don't need]
	jmp conupk ; ROMUPK = CONUPK (=above)

	; [*** C128/C65 has RAM and ROM version, which we don't need]
	jmp movfm ; MOVFRM = MOVFM (=below)

	; FAC = mem(.Y:.A) (5 bytes)
	jmp movfm  ; $BBA2

	; mem(.Y:.X) = round(FAC) (5 bytes)
	jmp movmf  ; $BBD4

	; FAC = ARG
	jmp movfa  ; $BBFC

	; ARG = round(FAC)
	jmp movaf  ; $BC0C

; X16 additions

	; FAC += .5
	jmp faddh  ; $B849 [-mapping-]

	; FAC = 0
	jmp zerofc ; $B8F7

	; Normalize FAC
	jmp normal ; $B8D7 [-mapping-]

	; FAC = -FAC
	jmp negfac ; $B947 [-mapping-]

	; FAC *= 10
	jmp mul10  ; $BAE2

	; FAC /= 10
	; ["Note: This routine treats FAC1 as positive even if it is not."]
	jmp div10  ; $BAFE

	; ARG = FAC
	jmp movef  ; $BC0F [-mapping-]

	; FAC = sgn(FAC)
	jmp sgn    ; $BC39

	; FAC = (u8).A
	; [destroys ARG]
	jmp float  ; $BC3C

	; FAC = (s16)facho+1:facho
	; [destroys ARG]
	jmp floats ; $BC44

	; facho:facho+1:facho+2:facho+3 = u32(FAC)
	jmp qint   ; $BC9B

	; FAC += (s8).A
	jmp finlog ; $BD7E

	; Convert FAC to ASCIIZ string at fbuffr - 1 + .Y
	; [used by BASIC]
	jmp foutc  ; $BDDF

	; Polynomial Evaluation 1 (SIN/COS/ATN/LOG)
	jmp polyx  ; $E043 [-mapping-]

	; Polynomial Evaluation 2 (EXP)
	jmp poly   ; $E059 [-mapping-]

.if 0
; X16 additions - BASIC only
; XXX BASIC links these functions directly instead of
; XXX going through a jump table. This is because the
; XXX space here is tight: The KERNAL jump table grows
; XXX down into this space.
	; FAC += ARG
	; [do not use, used by BASIC]
	jmp bfaddt; $B86A
	; FAC *= ARG
	; [do not use, used by BASIC]
	jmp bfmultt; $BA2B
	; FAC /= ARG
	; [do not use, used by BASIC]
	jmp bfdivt ; $BB12
	; FAC = ARG^FAC
	; [do not use, used by BASIC]
	jmp bfpwrt ; $BF7B
	; [do not use, used by BASIC]
	jmp floatb ; $BC4F
	; [do not use, used by BASIC]
	jmp fcompn ; $BC5D
.else
.export bfaddt
.export bfmultt
.export bfdivt
.export bfpwrt
.export floatb
.export fcompn
.endif
