; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Console I/O: PutChar and SmallPutChar syscalls

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.import _GetRealSize
.import FontPutChar
.import DoESC_RULER
.import _GraphicsString

.import Ddec
.import CallRoutine
.import _PutCharK

.global DoBACKSPC
.global _PutChar
.global _SmallPutChar

.segment "conio1"

_PutChar:
; codes $00-$07 are no-op (original GEOS crashed)
	cmp #8
	bcs @0
	rts

; codes $08-$1F are control codes - convert them or handle them
@0:	cmp #$20
	bcs @0a
	asl
	tay
	lda PutCharTab-2*8,y
	ldx PutCharTab-2*8+1,y
	beq @1 ; byte entries specify the KERNAL-encoded control code we should print
	jmp CallRoutine

; convert code $80 to $FF (GEOS compat. "logo" char)
@0a:	cmp #$80
	bne @1
	lda #$ff

@1:	jsr _PutCharK
	bcs @6
	rts

; string fault
@6:	ldx StringFaultVec+1
	lda StringFaultVec
	jmp CallRoutine

PutCharTab:
	.word $08            ; $08 BACKSPACE
	.word 0              ; $09 TAB          (no-op)
	.word $11            ; $0A LF           (DOWN)
	.word DoHOME         ; $0B HOME         (HOME has different semantics)
	.word $91            ; $0C UPLINE
	.word $0A            ; $0D CR           (new line, don't clear attributes)
	.word $04            ; $0E ULINEON
	.word DoULINEOFF     ; $0F ULINEOFF
	.word DoESC_GRAPHICS ; $10 ESC_GRAPHICS
	.word DoESC_RULER    ; $11 ESC_RULER
	.word $12            ; $12 REV_ON
	.word DoREV_OFF      ; $13 REV_OFF
	.word DoGOTOX        ; $14 GOTOX
	.word DoGOTOY        ; $15 GOTOY
	.word DoGOTOXY       ; $16 GOTOXY
	.word DoNEWCARDSET   ; $17 NEWCARDSET
	.word $06            ; $18 BOLDON
	.word $0B            ; $19 ITALICON
	.word $0C            ; $1A OUTLINEON
	.word $92            ; $1B PLAINTEXT

DoHOME:
	LoadW_ r11, 0
	sta r1H
	rts

DoULINEOFF:
	rmbf UNDERLINE_BIT, g_currentMode
	rts

DoREV_OFF:
	rmbf REVERSE_BIT, g_currentMode
	rts

DoGOTOX:
	inc r0L
	bne @1
	inc r0H
@1:	ldy #0
	lda (r0),y
	sta r11L
	inc r0L
	bne @2
	inc r0H
@2:	lda (r0),y
	sta r11H
	rts

DoGOTOY:
	inc r0L
	bne @1
	inc r0H
@1:	ldy #0
	lda (r0),y
	sta r1H
	rts

DoGOTOXY:
	jsr DoGOTOX
	jmp DoGOTOY

DoNEWCARDSET:
	AddVW 3, r0
	rts

DoESC_GRAPHICS:
	inc r0L
	bne @1
	inc r0H
@1:	jsr _GraphicsString
	ldx #r0
	jsr Ddec
	ldx #r0
	jmp Ddec





;-----
DoBACKSPC:
	ldx g_currentMode
	jsr _GetRealSize
	sty PrvCharWidth
	SubB PrvCharWidth, r11L
	bcs @1
	dec r11H
@1:	PushW r11
	lda #$5f
	jsr FontPutChar
	PopW r11
	rts


