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

.import DoESC_RULER
.import _GraphicsString

.import Ddec
.import CallRoutine
.import _PutCharK

.global DoBACKSPC
.global _PutChar
.global _SmallPutChar

.setcpu "65c02"

.segment "conio1"

;---------------------------------------------------------------
; PutChar
;
; Function:  Process a single character code (both escape codes
;            and printable characters)
;
; Pass:      a   character code (byte)
;            r11 x-coordinate of left of character
;            r1H y-coordinate of character baseline
; Return:    r11 x-position for next character
;            r1H unchanged
; Destroyed: a, x, y, r1L, r2-r10, r12, r13
;---------------------------------------------------------------
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

@1:	tax
	PushW r0
	PushW r1
	MoveW r11, r0
	MoveB r1H, r1L
	stz r1H
	txa
	jsr _PutCharK
	MoveW r0, r11
	PopW r1
	PopW r0
	
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

; The KERNAL version puts the cursor at the top left of the window
DoHOME:
	LoadW_ r11, 0
	sta r1H
	rts

; The KERNAL version has no control code to disable attributes individually.
DoULINEOFF:
	rmbf UNDERLINE_BIT, g_currentMode
	rts
DoREV_OFF:
	rmbf REVERSE_BIT, g_currentMode
	rts

; The following features are GEOS-specific:
; * set cursor to a new X
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
; * set cursor to a new X and Y
DoGOTOXY:
	jsr DoGOTOX
; fallthrough
; * set cursor to a new Y
DoGOTOY:
	inc r0L
	bne @1
	inc r0H
@1:	ldy #0
	lda (r0),y
	sta r1H
	rts
; * set new attributes (ignored)
DoNEWCARDSET:
	AddVW 3, r0
	rts
; * inline GraphicsString
DoESC_GRAPHICS:
	inc r0L
	bne @1
	inc r0H
@1:	jsr _GraphicsString
	ldx #r0
	jsr Ddec
	ldx #r0
	jmp Ddec
