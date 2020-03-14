; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak; Michael Steil
;
; Purgeable start code; first entry

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "gkernal.inc"
.include "inputdrv.inc"
.include "c64.inc"
.include "banks.inc"
.include "kernal.inc"

; main.s
.import InitGEOEnv
.import _DoFirstInitIO
.import _EnterDeskTop

; irq.s
.import _IRQHandler
.import _NMIHandler

.import LdApplic
.import GetBlock
.import EnterDeskTop
.import GetDirHead
.import FirstInit
.import i_FillRam
.import _DoUpdateTime

.import bootTr2
.import bootSec2
.import bootOffs
.import bootSec
.import bootTr

.import _Rectangle

.import MouseInit

; used by header.s
.global _ResetHandle

.ifdef usePlus60K
.import DetectPlus60K
.endif
.if .defined(useRamCart64) || .defined(useRamCart128)
.import DetectRamCart
.endif
.ifdef useRamExp
.import LoadDeskTop
.endif

.segment "start"

_ResetHandle:
	sei
	cld
	ldx #$FF
	txs

.if 0
	jsr i_FillRam
	.word $0500
	.word dirEntryBuf
	.byte 0
.endif

.import __drvcbdos_SIZE__, __drvcbdos_LOAD__, __drvcbdos_RUN__
.import _i_MoveData

	jsr _i_MoveData
	.word __drvcbdos_LOAD__
	.word __drvcbdos_RUN__
	.word __drvcbdos_SIZE__

	lda #$80
	jsr gjsrfar
	.word screen_set_mode
	.byte BANK_KERNAL

	jsr gjsrfar
	.word FB_init
	.byte BANK_KERNAL

	; Disable layer 1
	lda VERA_DC_VIDEO
	and #$DF
	sta VERA_DC_VIDEO

	; IRQ
	lda #1
	sta VERA_IEN

	jsr _DoUpdateTime

	;
	jsr FirstInit
	jsr MouseInit
	lda #currentInterleave
	sta interleave

	lda #1
	sta numDrives
	ldy $BA
	sty curDrive
	lda #DRV_TYPE ; see config.inc
	sta curType
	sta _driveType,y

; This is the original code the cbmfiles version
; has at $5000.
OrigResetHandle:
	sei
	cld
	ldx #$ff
	jsr _DoFirstInitIO
	jsr InitGEOEnv
.ifdef usePlus60K
	jsr DetectPlus60K
.endif
.if .defined(useRamCart64) || .defined(useRamCart128)
	jsr DetectRamCart
.endif

	LoadB bootTr, DIR_TRACK
	LoadB bootSec, 1

	jsr GetDirHead
	MoveB bootSec, r1H
	MoveB bootTr, r1L
	AddVB 32, bootOffs
	bne @3
@1:	MoveB bootSec2, r1H
	MoveB bootTr2, r1L
	bne @3
	lda numDrives
	bne @2
	inc numDrives
@2:	LoadW EnterDeskTop+1, _EnterDeskTop
.ifdef useRamExp
	jsr LoadDeskTop
.endif
	jmp EnterDeskTop

@3:	MoveB r1H, bootSec
	MoveB r1L, bootTr
	LoadW r4, diskBlkBuf
	jsr GetBlock
	bnex @2
	MoveB diskBlkBuf+1, bootSec2
	MoveB diskBlkBuf, bootTr2
@4:	ldy bootOffs
	lda diskBlkBuf+2,y
	beq @5
	lda diskBlkBuf+$18,y
	cmp #AUTO_EXEC
	beq @6
@5:	AddVB 32, bootOffs
	bne @4
	beq @1
@6:	ldx #0
@7:	lda diskBlkBuf+2,y
	sta dirEntryBuf,x
	iny
	inx
	cpx #30
	bne @7
	LoadW r9, dirEntryBuf
	LoadW EnterDeskTop+1, _ResetHandle
	LoadB r0L, 0
	jsr LdApplic


.segment "entry"
entry:
	.assert * = $C000, error, "GEOS entry must be at $C000"
	jmp _ResetHandle

.segment "vectors"
	.word _NMIHandler
	.word entry
	.word _IRQHandler

.segment "start"
; GEOS's entry into jsrfar
.setcpu "65c02"
.export gjsrfar
gjsrfar:
.include "jsrfar.inc"

