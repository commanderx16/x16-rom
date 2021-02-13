;----------------------------------------------------------------------
; CMDR-DOS Command Channel
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "banks.inc"

.export set_status, cmdch_read
.export cmdch_exec

; parser.s
.import parse_command

; zeropage.s
.importzp krn_ptr1

; functions.s
.export status_clear, status_put

; dir.s
.export bin_to_bcd

; fat32.s
.import fat32_get_num_contexts

MAX_STATUS_LEN = 40

.bss

statusbuffer:
	.res MAX_STATUS_LEN, 0


status_r:
	.byte 0
status_w:
	.byte 0

.code

;---------------------------------------------------------------
status_clear:
	stz status_w
	stz status_r
	rts

status_put:
	ldx status_w
	sta statusbuffer,x
	inc status_w
	rts

;---------------------------------------------------------------
fallback_tab:
	.byte $c0,$bc,$ec,$e2,$70,$04,$d2,$6d,$f4,$89,$52,$78,$8c,$5d,$ef,$e7
	.byte $e9,$65,$e5,$ee,$06,$43,$fd,$6f,$eb,$e8,$26,$5d,$bb,$67,$e6,$6b
	.byte $e7,$e0,$f4,$6f,$e6,$02,$44,$65,$87,$5d,$ff,$8c,$40,$69,$f2,$7d
	.byte $64,$62,$f0,$09,$5c,$6f,$f7,$e8,$a0

fallback31:
	.import buffer, buffer_len
	lda buffer+0
	eor buffer+1
	cmp #$6f
	bne @4
	adc buffer+0
	sbc #$b1
	bne @4
	tay
	lda buffer+2
	ldx #$1b
	jsr @2
	beq @1
	ldx #$1e
	jsr @2
	bne @4
@1:	jmp cmdch_exec
@2:	stx buffer_len
	ldx #0
@3:	eor fallback_tab,y
	sta buffer,x
	pha
	inx
	lsr
	iny
	pla
	ror
	cpx buffer_len
	bne @3
	tax
	rts
@4:	lda #$31
	ldx #0
	beq keep_x

;---------------------------------------------------------------
set_status:
	cmp #$01   ; FILES SCRATCHED
	beq keep_x
	cmp #$02   ; PARTITION SELECTED
	beq keep_x
	cmp #$77   ; SELECTED PARTITION ILLEGAL
	beq keep_x
	cmp #$31   ; SYNTAX ERROR
	beq fallback31

	ldx #0
keep_x:
	ldy #0
	phy
	phx

	; set/clear disk error flag
	tax
	lda cbdos_flags
	and #$ff-$20 ; clear error flag
	cpx #$10
	bcc :+
	cpx #$73 ; power-on message is not an error
	beq :+
	ora #$20 ; set error flag
:	sta cbdos_flags
	txa

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
:	pla ; first arg
	jsr add_decimal
	pla ; second arg
	jsr add_decimal

	txa
	sta status_w
	stz status_r
	rts

add_decimal:
	pha

	lda #','
	sta statusbuffer,x
	inx

	pla
	pha
	cmp #100
	bcc @lt_100
	cmp #200
	bcc @lt_200
	lda #'2'
	bra @add
@lt_200:
	lda #'1'
@add:
	sta statusbuffer,x
	inx

@lt_100:
	pla
	jsr bin_to_bcd
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta statusbuffer,x
	inx
	pla
	and #$0f
	ora #$30
	sta statusbuffer,x
	inx
	rts

get_hundreds:
	rts


bin_to_bcd:
	phy
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
	ply
	rts

stcodes:
	.byte $00, $01, $02, $20, $25, $26, $30, $31, $32, $33, $34, $39, $49, $62, $63, $70, $71, $72, $73, $74, $75, $77, $79
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
	.word status_39
	.word status_49
	.word status_62
	.word status_63
	.word status_70
	.word status_71
	.word status_72
	.word status_73
	.word status_74
	.word status_75
	.word status_77
	.word buffer+1 ; 79 (echo message)

;---------------------------------------------------------------
; $0x: Informational
;---------------------------------------------------------------
status_00:
	.byte " OK", 0
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
status_39: ; subdirectory not found
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
	.byte "CMDR-DOS V1.0 X16", 0
status_74:
	.byte "DRIVE NOT READY", 0 ; illegal partition for any command but "CP"
status_75:
	.byte "FORMAT ERROR", 0
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
;   $76     HARDWARE ERROR
;   $78     SYSTEM ERROR
; specific codes of supported strings
;   $21-$23/$27 READ ERROR
;   $28     WRITE ERROR
; unknown
;   $60     WRITE FILE OPEN
;   $61     FILE NOT OPEN
; REL files
;   $50     RECORD NOT PRESENT
;   $51     OVERFLOW IN RECORD
;   $52     FILE TOO LARGE

;---------------------------------------------------------------
cmdch_read:
	ldy status_r
	cpy status_w
	beq @cmdch_read_eoi

	lda statusbuffer,y
	inc status_r
	clc ; !eof
	rts

@cmdch_read_eoi:
	lda #0
	jsr set_status
	lda #$0d
	sec ; eof
	rts

;---------------------------------------------------------------
cmdch_exec:
	jsr parse_command
	bcc @1
	lda #$30 ; generic syntax error
	jmp set_status

@1:	cmp #$ff ; command has already put data into the status buffer
	beq @rts
	jmp set_status

@rts:	rts

