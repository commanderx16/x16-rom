;----------------------------------------------------------------------
; CBDOS Command Channel
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.export set_status, acptr_status

; parse.s
.export buffer, buffer_len, buffer_overflow

; zeropage.s
.importzp krn_ptr1

; sdcard.s
.import sdcard_init

; functions.s
.export statusbuffer, status_w, status_r

MAX_STATUS_LEN = 40

.segment "cbdos_data"

; buffer for filenames and commands
buffer:
	.res 256, 0

statusbuffer:
	.res MAX_STATUS_LEN, 0

buffer_len:
	.byte 0
buffer_overflow:
	.byte 0

status_r:
	.byte 0
status_w:
	.byte 0

.segment "cbdos"

;---------------------------------------------------------------
set_status_ok:
	lda #$00
	bra set_status
set_status_writeprot:
	lda #$26
	bra set_status
set_status_synerr:
	lda #$31
	bra set_status
set_status_74:
	lda #$74

set_status:
	cmp #$01   ; FILES SCRATCHED
	beq @clr_y
	cmp #$02   ; PARTITION SELECTED
	beq @clr_y
	cmp #$77   ; SELECTED PARTITION ILLEGAL
	beq @clr_y

	ldx #0
@clr_y:
	ldy #0
	phy
	phx

	pha
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta statusbuffer
	pla
	and #$0f
	ora #$30
	sta statusbuffer + 1
	lda #','
	sta statusbuffer + 2
	pla
	ldx #0
:	cmp stcodes,x
	beq :+
	inx
	cpx #stcodes_end - stcodes
	bne :-
:	txa
	asl
	tax
	lda ststrs,x
	sta krn_ptr1
	lda ststrs + 1,x
	sta krn_ptr1 + 1
	ldx #3
	ldy #0
:	lda (krn_ptr1),y
	beq :+
	sta statusbuffer,x
	iny
	inx
	bne :-
:	lda #','
	sta statusbuffer + 0,x
	pla ; first arg
	jsr bin_to_bcd
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta statusbuffer + 1,x
	pla
	and #$0f
	ora #$30
	sta statusbuffer + 2,x
	lda #','
	sta statusbuffer + 3,x
	pla ; second arg
	jsr bin_to_bcd
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta statusbuffer + 4,x
	pla
	and #$0f
	ora #$30
	sta statusbuffer + 5,x

	txa
	clc
	adc #6
	sta status_w
	stz status_r
	rts

bin_to_bcd:
	tay
	lda #0
	sed
@loop:	cpy #0
	beq @end
	clc
	adc #1
	dey
	bra @loop
@end:	cld
	rts

stcodes:
	.byte $00, $01, $02, $20, $25, $26, $30, $31, $32, $33, $34, $49, $62, $63, $70, $71, $72, $73, $74, $77
stcodes_end:

ststrs:
	.word status_00
	.word status_01
	.word status_02
	.word status_20
	.word status_25
	.word status_26
	.word status_30
	.word status_31
	.word status_32
	.word status_33
	.word status_34
	.word status_49
	.word status_62
	.word status_63
	.word status_70
	.word status_71
	.word status_72
	.word status_73
	.word status_74
	.word status_77

;---------------------------------------------------------------
; $0x: Informational
;---------------------------------------------------------------
status_00:
	.byte "OK", 0
status_01:
	.byte " FILES SCRATCHED", 0
status_02:
	.byte "PARTITION SELECTED", 0

;---------------------------------------------------------------
; $2x: Physical disk error
;---------------------------------------------------------------

status_20:
	.byte "READ ERROR", 0 ; generic read error
status_25:
	.byte "WRITE ERROR", 0 ; generic write error
status_26:
	.byte "WRITE PROTECT ON", 0

;---------------------------------------------------------------
; $3x: Error parsing the command
;---------------------------------------------------------------

status_30: ; generic
status_31: ; invalid command
status_32: ; command buffer overflow
status_33: ; illegal filename
status_34: ; empty file name
	.byte "SYNTAX ERROR" ,0

;---------------------------------------------------------------
; $4x: Controller error (CMD addition)
;---------------------------------------------------------------

status_49:
	.byte "INVALID FORMAT", 0 ; partition present, but not FAT32

;---------------------------------------------------------------
; $5x: Relative file related error
;---------------------------------------------------------------

; unsupported

;---------------------------------------------------------------
; $6x: File error
;---------------------------------------------------------------

status_62:
	.byte " FILE NOT FOUND" ,0
status_63:
	.byte "FILE EXISTS", 0

;---------------------------------------------------------------
; $7x: Generic disk or device error
;---------------------------------------------------------------

status_70:
	.byte "NO CHANNEL", 0 ; error allocating context
status_71:
	.byte "DIRECTORY ERROR", 0 ; FAT error
status_72:
	.byte "PARTITION FULL", 0 ; filesystem full

status_73:
	.byte "CBDOS V1.0 X16", 0
status_74:
	.byte "DRIVE NOT READY", 0 ; illegal partition for any command but "CP"
status_77:
	.byte "SELECTED PARTITION ILLEGAL",0

;---------------------------------------------------------------
; Unsupported
;---------------------------------------------------------------
;   $29     DISK ID MISMATCH
;   $39     FILE NOT FOUND
;   $40-$47 CONTROLLER ERROR
;   $48     ILLEGAL JOB
;   $64     FILE TYPE MISMATCH
;   $65     NO BLOCK
;   $66/$67 ILLEGAL BLOCK
;   $75     FORMAT ERROR
;   $76     HARDWARE ERROR
;   $78     SYSTEM ERROR
; specific codes of supported strings
;   $21-$23/$27 READ ERROR
;   $28     WRITE ERROR
; unknown
;   $60     WRITE FILE OPEN
;   $61     FILE NOT OPEN
; TODO: REL files
;   $50     RECORD NOT PRESENT
;   $51     OVERFLOW IN RECORD
;   $52     FILE TOO LARGE

acptr_status:
	ldy status_r
	cpy status_w
	beq @acptr_status_eoi

	lda statusbuffer,y
	inc status_r
	clc ; !eof
	rts

@acptr_status_eoi:
	jsr set_status_ok
	lda #$0d
	sec ; eof
	rts
