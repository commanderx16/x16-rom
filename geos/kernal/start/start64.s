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

; The original version of GEOS 2.0 has purgeable init code
; at $5000 that is run once. It does some initialization
; and handles application auto-start.
;
; The cbmfiles version of GEOS does some init inside
; "BOOTGEOS" right after copying the components to their
; respective locations, then jumps to $500D, which contains
; a different version of the code, and skipping the first
; five instructions.
;
; This version is based on the cbmfiles version.
; "OrigResetHandle" below is the original cbmfiles code at
; $5000, and the code here at _ResetHandle is some additional
; initialization derived from the code in BOOTGEOS to make
; everything work.
;
; TODO: * REU detection seems to be currently missing.
;       * It would be best to put the original GEOS 2.0 code
;         here.
;

.global geos_init_vera

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

sprite_addr = $10000 + 320 * 200 ; after background screen

	; init sprites
	lda #$00
	sta veralo
	lda #$40
	sta veramid
	lda #$1F
	sta verahi
	lda #1
	sta veradat ; enable sprites

	lda #$00
	sta veralo
	lda #$50
	sta veramid
	lda #<(sprite_addr >> 5)
	sta veradat
	lda #1 << 7 | >(sprite_addr >> 5) ; 8 bpp
	sta veradat

	lda #<sprite_addr
	sta veralo
	lda #>sprite_addr
	sta veramid
	lda #$10 | (sprite_addr >> 16)
	sta verahi
	ldx #8
xx2:	txa
	tay
	lda #6
:	sta veradat
	dey
	bne :-
	txa
	sec
	sbc #8
	eor #$ff
	clc
	adc #1
	beq xx1
	tay
	lda #0
:	sta veradat
	dey
	bne :-
xx1:	dex
	bne xx2
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
	sta NUMDRV
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
	jsr GetDirHead
	MoveB bootSec, r1H
	MoveB bootTr, r1L
	AddVB 32, bootOffs
	bne @3
@1:	MoveB bootSec2, r1H
	MoveB bootTr2, r1L
	bne @3
	lda NUMDRV
	bne @2
	inc NUMDRV
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

.segment "RAM"

bootTr:
	.byte DIR_TRACK
bootSec:
	.byte 1
bootTr2:
	.byte 0
bootSec2:
	.byte 0
bootOffs:
	.byte 0

.segment "entry"
entry:
	jmp _ResetHandle

.segment "vectors"
stop:	.word _NMIHandler
	.word entry
	.word _IRQHandler

.if 1
.segment "RAM"

.setcpu "65c02"
imparm = 0
via1	=$9f60                  ;VIA 6522 #1
d1prb	=via1+0
d1pra	=via1+1
.global gjsrfar
gjsrfar:
	pha             ;reserve 1 byte on the stack
	php             ;save registers & status
	pha
	phx
	phy

        tsx
	lda $106,x      ;return address lo
	sta imparm
	clc
	adc #3
	sta $106,x      ;and write back with 3 added
	lda $107,x      ;return address hi
	sta imparm+1
	adc #0
	sta $107,x

	ldy #1
	lda (imparm),y  ;target address lo
	sta jmpfr+1
	iny
	lda (imparm),y  ;target address hi
	sta jmpfr+2
	cmp #$c0
	bcs @1          ;target is in ROM
; target is in RAM
	lda d1pra
	sta $0105,x     ;save original bank into reserved byte
	iny
	lda (imparm),y  ;target address bank
	sta d1pra       ;set RAM bank
	ply             ;restore registers
	plx
	pla
	plp
	jsr jmpfr
	php
	pha
	phx
	tsx
	lda $0104,x
	sta d1pra       ;restore RAM bank
	jmp @2

@1:	lda d1prb
	sta $0105,x     ;save original bank into reserved byte
	iny
	lda (imparm),y  ;target address bank
	and #$07
	sta d1prb       ;set ROM bank
	ply             ;restore registers
	plx
	pla
	plp
	jsr jmpfr
	php
	pha
	phx
	tsx
	lda $0104,x
	sta d1prb       ;restore ROM bank
	lda $0103,x     ;overwrite reserved byte...
	sta $0104,x     ;...with copy of .p
@2:	plx
	pla
	plp
	plp
	rts

jmpfr:	jmp $ffff

.endif
