; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Font drawing: Bit shifting

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.import Font_9
.import FntShJump
.import FontTVar4

.global FontSH5
.global base
.ifdef bsw128
.global noop
.endif

.global b0, b1, b2, b3, b4, b5, b6, b7
.global c0, c1, c2, c3, c4, c5, c6, c7
.global d0, d1, d2, d3, d4, d5, d6, d7
.global e0, e1, e2, e3, e4, e5, e6, e7
.global f0, f1, f2, f3, f4, f5, f6, f7
.global g0, g1, g2, g3, g4, g5, g6, g7

.segment "fonts3"

base:

c7:	lsr
c6:	lsr
c5:	lsr
c4:	lsr
c3:	lsr
c2:	lsr
c1:	lsr
c0:	jmp FntShJump

.ifdef bsw128
f7:
	lsr a
	ror fontTemp1+1
f6:
	lsr a
	ror fontTemp1+1
f5:
	lsr a
	ror fontTemp1+1
f4:
	lsr a
	ror fontTemp1+1
f3:
	lsr a
	ror fontTemp1+1
f2:
	lsr a
	ror fontTemp1+1
f1:
	lsr a
	ror fontTemp1+1
f0:
	jmp FntShJump
.endif

e7:	lsr
	ror fontTemp1+1
	ror fontTemp1+2
e6:	lsr
	ror fontTemp1+1
	ror fontTemp1+2
e5:	lsr
	ror fontTemp1+1
	ror fontTemp1+2
e4:	lsr
	ror fontTemp1+1
	ror fontTemp1+2
e3:	lsr
	ror fontTemp1+1
	ror fontTemp1+2
e2:	lsr
	ror fontTemp1+1
	ror fontTemp1+2
e1:	lsr
	ror fontTemp1+1
	ror fontTemp1+2
e0:	jmp FntShJump

b7:	asl
b6:	asl
b5:	asl
b4:	asl
b3:	asl
b2:	asl
b1:	asl
	jmp FntShJump

.ifdef bsw128
g7:
	asl fontTemp1+1
	rol a
g6:
	asl fontTemp1+1
	rol a
g5:
	asl fontTemp1+1
	rol a
g4:
	asl fontTemp1+1
	rol a
g3:
	asl fontTemp1+1
	rol a
g2:
	asl fontTemp1+1
	rol a
g1:
	asl fontTemp1+1
	rol a
g0:
	jmp FntShJump
.endif

d7:	asl fontTemp1+2
	rol fontTemp1+1
	rol
d6:	asl fontTemp1+2
	rol fontTemp1+1
	rol
d5:	asl fontTemp1+2
	rol fontTemp1+1
	rol
d4:	asl fontTemp1+2
	rol fontTemp1+1
	rol
d3:	asl fontTemp1+2
	rol fontTemp1+1
	rol
d2:	asl fontTemp1+2
	rol fontTemp1+1
	rol
d1:	asl fontTemp1+2
	rol fontTemp1+1
	rol
	jmp FntShJump

.assert * - base < 256, error, "Font shift code must be < 256 bytes"

FontSH5:
	sta fontTemp1
	lda r7L
	sub FontTVar4
	beq @2
	bcc @3
	tay
@1:
	jsr Font_9
	dey
	bne @1
@2:
	lda fontTemp1
	jmp FntShJump
@3:
	lda FontTVar4
	sub r7L
	tay
@4:
	asl fontTemp1+7
	rol fontTemp1+6
	rol fontTemp1+5
	rol fontTemp1+4
	rol fontTemp1+3
	rol fontTemp1+2
	rol fontTemp1+1
	rol fontTemp1
	dey
	bne @4
	lda fontTemp1
.ifdef bsw128
	jmp FntShJump
noop:	rts
.else
.assert * = FntShJump, error, "Code must run into FntShJump"
.endif

