; Commander X16 KERNAL
; based on GEOS by Berkeley Softworks; reversed by Maciej Witkowiak, Michael Steil
;
; Font library: bit shifting

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

