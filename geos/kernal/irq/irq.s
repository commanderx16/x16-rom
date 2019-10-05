; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; IRQ/NMI handlers

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"
.ifdef bsw128
.include "inputdrv.inc"
.endif

; keyboard.s
.import _DoKeyboardScan

; var.s
.import KbdQueFlag
.import alarmWarnFlag
.import tempIRQAcc

.import CallRoutine
.import GetRandom

.ifdef bsw128
.import CallAddr
.import RestoreConfig
.import CallAddr2
.import ProcessMouse
.import _DoKeyboardScan
.endif

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
@1:	PushB bank0SaveRcr
	PushB bank0SaveA
	PushB bank0SavePS
	PushW CallAddr2
	PushB CallAddr
	PushB RestoreConfig
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
	lda #1
	sta veraisr
.ifdef use2MHz
	LoadB clkreg, 0
.endif
.endif
	jsr convert_vic_to_vera

	PushW CallRLo
	PushW returnAddress
	ldx #0
@2:	lda r0,x
	pha
	inx
	cpx #32
	bne @2
	START_IO
	lda dblClickCount
	beq @3
	dec dblClickCount
@3:
.ifdef bsw128
	jsr ProcessMouse
.endif
	ldy KbdQueFlag
	beq @4
	iny
	beq @4
	dec KbdQueFlag
@4:
.ifdef bsw128
	jsr _DoKeyboardScan
	jsr SetMouse
.else
	jsr _DoKeyboardScan
.endif
	lda alarmWarnFlag
	beq @5
	dec alarmWarnFlag
@5:
.ifdef wheels_screensaver
.import ProcessMouse
	lda saverStatus
	lsr
	bcc @Y ; screensaver not running
	jsr ProcessMouse
	jsr GetRandom
	bra @X
.endif
@Y:	lda intTopVector
	ldx intTopVector+1
	jsr CallRoutine
	lda intBotVector
	ldx intBotVector+1
	jsr CallRoutine
@X:	END_IO
.ifdef use2MHz
	LoadW $fffe, IRQ2Handler
	LoadB rasreg, $fc
.endif
	ldx #31
@6:	pla
	sta r0,x
	dex
	bpl @6
	PopW returnAddress
	PopW CallRLo
.ifdef bsw128
	PopB RestoreConfig
	PopB CallAddr
	PopW CallAddr2
	PopB bank0SavePS
	PopB bank0SaveA
	PopB bank0SaveRcr
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

.ifdef use2MHz
IRQ2Handler:
	pha
	txa
	pha
	START_IO_X
	lda rasreg
	and #%11110000
	beq @1
	cmp #$f0
	bne @2
@1:	LoadB clkreg, 1
@2:	LoadB rasreg, $2c
	LoadW $fffe, _IRQHandler
	inc grirq
	END_IO_X
	pla
	tax
	pla
	rti
.endif


; convert VIC-II bitmap to VERA bitmap
convert_vic_to_vera:
	lda $9efe
	clc
	adc #1
	and #3
	sta $9efe
	beq :+
	rts
:	;inc $a000 + 7999

	PushW r0
	PushW r1
	PushW r2

	LoadW r0, $a000
	ldy #$00
	sty veralo
	lda #$40
	sta veramid
	lda #$10
	sta verahi

	LoadB r2L, 25

l4:	LoadB r1H, 8

l3:	PushW r0
	LoadB r1L, 40

l2:	lda (r0),y
	eor #$ff
	ldx #8
l1:	asl
	pha
	bcc :+
	lda #1
	.byte $2c
:	lda #0
	sta veradat
	pla
	dex
	bne l1

	AddVW 8, r0
	dec r1L
	bne l2

	PopW r0
	IncW r0
	dec r1H
	bne l3

	AddVW 320-8, r0
	dec r2L
	bne l4

	PopW r2
	PopW r1
	PopW r0
	rts

hstart  =0
hstop   =640
vstart  =0
vstop   =480
tvera_composer:
	.byte 7 << 5 | 1  ;256c bitmap, VGA
	.byte 64, 64      ;hscale, vscale
	.byte 14          ;border color
	.byte <hstart
	.byte <hstop
	.byte <vstart
	.byte <vstop
	.byte (vstop >> 8) << 5 | (vstart >> 8) << 4 | (hstop >> 8) << 2 | (hstart >> 8)
tvera_composer_end:
