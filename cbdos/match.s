;----------------------------------------------------------------------
; CBDOS Name Matching
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "fat32/fat32.inc"
.include "fat32/regs.inc"
.include "fat32/text_input.inc"

.export match_name, match_type, skip_mask

.bss

skip_mask:           .byte 0

.code

;-----------------------------------------------------------------------------
; match_name
;
; Check if name matches
;
; In:   fat32_ptr   name
;       y           name offset
; Out:  c           =1: matched
;-----------------------------------------------------------------------------
match_name:
	ldx #0
@1:	lda (fat32_ptr), y
	beq @match
	cmp #'?'
	beq @char_match
	cmp #'*'
	beq @asterisk
	cmp #'/'
	beq @match
	jsr to_upper
	cmp fat32_dirent + dirent::name, x
	bne @no
@char_match:
	inx
	iny
	bra @1

; '*' found: consume excess characters in input until '/' or end
@asterisk:
	iny
	lda (fat32_ptr), y
	beq @yes
	cmp #'/'
	bne @asterisk
	bra @yes

@match:	; Search string also at end?
	lda fat32_dirent + dirent::name, x
	bne @no

@yes:
	sec
	rts
@no:
	clc
	rts

;---------------------------------------------------------------
; match_type
;
; In:   a   type
; Out:  c   =1: matched
;---------------------------------------------------------------
match_type:
	bit skip_mask
	beq @yes
	clc
	rts
@yes:	sec
	rts
