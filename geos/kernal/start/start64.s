; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak; Michael Steil
;
; Purgeable start code; first entry

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "inputdrv.inc"
.include "c64.inc"

; main.s
.import InitGEOEnv
.import _DoFirstInitIO
.import _EnterDeskTop

; header.s
.import dateCopy

; irq.s
.import _IRQHandler
.import _NMIHandler

.import LdApplic
.import GetBlock
.import EnterDeskTop
.import GetDirHead
.import FirstInit
.import i_FillRam

.import _Rectangle, _SetColor

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

; for KERNAL
.global geos_init_graphics

geos_init_graphics:
	lda #1 ; white
	jsr _SetColor

	lda #0
	sta r3L
	sta r3H
	sta r2L
	lda #<319
	sta r4L
	lda #>319
	sta r4H
	lda #199
	sta r2H
	jsr _Rectangle

tile_base = $10000

geos_init_vera:
	lda #$00 ; layer0
	sta veralo
	lda #$20
	sta veramid
	lda #$1F
	sta verahi
	lda #7 << 5 | 1; 256c bitmap
	sta veradat
	lda #0
	sta veradat; tile_w=320px
	sta veradat; map_base_lo: ignore
	sta veradat; map_base_hi: ignore
	lda #<(tile_base >> 2)
	sta veradat; tile_base_lo
	lda #>(tile_base >> 2)
	sta veradat; tile_base_hi

	lda #$00        ;$F0000: composer registers
	sta veralo
	sta veramid
	ldx #0
px5:	lda tvera_composer,x
	sta veradat
	inx
	cpx #tvera_composer_end-tvera_composer
	bne px5

	rts

hstart  =0
hstop   =640
vstart  =0
vstop   =400
tvera_composer:
	.byte 7 << 5 | 1  ;256c bitmap, VGA
	.byte 64, 64      ;hscale, vscale
	.byte 0           ;border color
	.byte <hstart
	.byte <hstop
	.byte <vstart
	.byte <vstop
	.byte (vstop >> 8) << 5 | (vstart >> 8) << 4 | (hstop >> 8) << 2 | (hstart >> 8)
tvera_composer_end:

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

.import __RAM_SIZE__, __RAM_LOAD__, __RAM_RUN__
.import _i_MoveData

	jsr _i_MoveData
	.word __RAM_LOAD__
	.word __RAM_RUN__
	.word __RAM_SIZE__

.import __drvcbdos_SIZE__, __drvcbdos_LOAD__, __drvcbdos_RUN__
.import _i_MoveData

	jsr _i_MoveData
	.word __drvcbdos_LOAD__
	.word __drvcbdos_RUN__
	.word __drvcbdos_SIZE__

	jsr geos_init_vera

	lda #$00 ; layer1
	sta veralo
	lda #$30
	sta veramid
	lda #$1F
	sta verahi
	lda #0 ; disable
	sta veradat

	; IRQ
	lda #1
	sta veraien

	; set date
	ldy #2
@6:	lda dateCopy,y
	sta year,y
	dey
	bpl @6

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
	jmp _ResetHandle

.segment "vectors"
stop:	.word _NMIHandler
	.word entry
	.word _IRQHandler

.segment "start"
; GEOS's entry into jsrfar
.setcpu "65c02"
.import jsrfar3
.import jmpfr
.export gjsrfar
gjsrfar:
.include "../jsrfar.inc"

