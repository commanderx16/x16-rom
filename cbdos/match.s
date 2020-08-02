;----------------------------------------------------------------------
; CBDOS Character Encoding, Name Matching
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "fat32/fat32.inc"
.include "fat32/regs.inc"
.include "fat32/text_input.inc"

.export filename_char_16_to_8, filename_char_8_to_16, match_name, match_type, skip_mask

.bss

skip_mask:           .byte 0

.code

;-----------------------------------------------------------------------------
; filename_char_16_to_8
;
; Convert UCS-2 character to private 8 bit encoding (ISO-8859-15)
;
; In:   a  16 bit char high
;       x  16 bit char low
; Out:  a  8 bit char
;-----------------------------------------------------------------------------
filename_char_16_to_8:
	cmp #0
	beq @from_latin_1

	; non ISO-8859-1 Unicode
	cmp #$20
	bne @not_20
	cpx #$ac
	bne @unsupported

	lda #$a4 ; U20AC '€'
	rts

@not_20:
	cmp #$01
	bne @unsupported

	cpx #$60
	bne @1
	lda #$a6 ; U0160 'Š'
	rts
@1:	cpx #$61
	bne @2
	lda #$a8 ; U0161 'š'
	rts
@2:	cpx #$7d
	bne @3
	lda #$b4 ; U017D 'Ž'
	rts
@3:	cpx #$7e
	bne @4
	lda #$b8 ; U017E 'ž'
	rts
@4:	cpx #$52
	bne @5
	lda #$bc ; U0152 'Œ'
	rts
@5:	cpx #$53
	bne @6
	lda #$bd ; U0153 'œ'
	rts
@6:	cpx #$78
	bne @unsupported
	lda #$be ; U0178 'Ÿ'
	rts


@from_latin_1:
	cpx #$a4 ; U00A4 '¤'
	beq @unsupported
	cpx #$a6 ; U00A6 '¦'
	beq @unsupported
	cpx #$a8 ; U00A8 '¨'
	beq @unsupported
	cpx #$b4 ; U00B4 '´'
	beq @unsupported
	cpx #$b8 ; U00B8 '¸'
	beq @unsupported
	cpx #$bc ; U00BC '¼'
	beq @unsupported
	cpx #$bd ; U00BD '½'
	beq @unsupported
	cpx #$be ; U00BE '¾'
	beq @unsupported

	; codes where ISO-8859-1 == ISO-8859-15
	txa
	rts

@unsupported:
	lda #'?'
	rts

;-----------------------------------------------------------------------------
; filename_char_8_to_16
;
; Convert character in private 8 bit encoding (ISO-8859-15) to UCS-2
;
; In:   a  8 bit char
; Out:  a  16 bit char low
;       x  16 bit char high
;-----------------------------------------------------------------------------
filename_char_8_to_16:
	cmp #$a4
	bne @1
	lda #$ac
	ldx #$20 ; U20AC '€'
	rts
@1:	cmp #$a6
	bne @2
	lda #$60
	ldx #$01 ; U0160 'Š'
	rts
@2:	cmp #$a8
	bne @3
	lda #$61
	ldx #$01 ; U0161 'š'
	rts
@3:	cmp #$b4
	bne @4
	lda #$7d
	ldx #$01 ; U017D 'Ž'
	rts
@4:	cmp #$b8
	bne @5
	lda #$7e
	ldx #$01 ; U017E 'ž'
	rts
@5:	cmp #$bc
	bne @6
	lda #$52
	ldx #$01 ; U0152 'Œ'
	rts
@6:	cmp #$bd
	bne @7
	lda #$53
	ldx #$01 ; U0153 'œ'
	rts
@7:	cmp #$be
	bne @8
	lda #$78
	ldx #$01 ; U0178 'Ÿ'
	rts
@8:
	; ISO-8859-1 matches ISO-8859-15
	ldx #0
	rts

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
