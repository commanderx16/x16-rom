; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; IRQ/NMI handlers

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "c64.inc"

; keyboard.s
.import _DoKeyboardScan

; var.s
.import KbdQueFlag
.import alarmWarnFlag
.import tempIRQAcc

.import CallRoutine
.import GetRandom

.import _InterruptMain

; used by boot.s
.global _IRQHandler
.global _NMIHandler

.segment "irq"

_IRQHandler:
.ifdef bsw128
	txa
	pha
	tya
	pha
	tsx
	lda $0108,x
	and #%00010000
	beq @1
	jmp (BRKVector)
@1:
.else
	cld
	sta tempIRQAcc
	pla
	pha
	and #%00010000
	beq @1
	pla
	jmp (BRKVector)
@1:	txa
	pha
	tya
	pha
.endif

	; switch VERA
	PushB VERA_CTRL
	PushB VERA_ADDR_L
	PushB VERA_ADDR_M
	PushB VERA_ADDR_H
	stz VERA_CTRL

	lda #1
	sta VERA_ISR

	PushW CallRLo
	PushW returnAddress
	ldx #0
@2:	lda r0,x
	pha
	inx
	cpx #32
	bne @2

	lda dblClickCount
	beq @3
	dec dblClickCount

@3:	ldy KbdQueFlag
	beq @4
	iny
	beq @4
	dec KbdQueFlag
@4:	jsr _DoKeyboardScan

	lda alarmWarnFlag
	beq @5
	dec alarmWarnFlag

@5:	lda intTopVector
	ldx intTopVector+1
	jsr CallRoutine
	jsr _InterruptMain
	lda intBotVector
	ldx intBotVector+1
	jsr CallRoutine

	ldx #31
@6:	pla
	sta r0,x
	dex
	bpl @6
	PopW returnAddress
	PopW CallRLo

	; switch VERA back
	PopB VERA_ADDR_H
	PopB VERA_ADDR_M
	PopB VERA_ADDR_L
	PopB VERA_CTRL

.ifdef bsw128
	pla
	tay
	pla
	tax
	rts
.else
	pla
	tay
	pla
	tax
	lda tempIRQAcc
_NMIHandler:
	rti
.endif
