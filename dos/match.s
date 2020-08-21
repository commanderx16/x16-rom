;----------------------------------------------------------------------
; CMDR-DOS Character Encoding, Name Matching
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "fat32/fat32.inc"
.include "fat32/regs.inc"
.include "fat32/text_input.inc"

.export filename_char_ucs2_to_internal, filename_char_internal_to_ucs2
.export filename_cp437_to_internal, filename_char_internal_to_cp437
.export match_name, match_type

.export skip_mask

.bss

skip_mask:
      .byte 0
char_tmp:
	.byte 0

.code

;-----------------------------------------------------------------------------
; filename_char_ucs2_to_internal
;
; Convert UCS-2 character to internal 8 bit encoding (ISO-8859-15)
;
; In:   a  16 bit char high
;       x  16 bit char low
; Out:  a  8 bit char
;-----------------------------------------------------------------------------
filename_char_ucs2_to_internal:
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
; filename_char_internal_to_ucs2
;
; Convert character in internal 8 bit encoding (ISO-8859-15) to UCS-2
;
; In:   a  8 bit char
; Out:  a  16 bit char low
;       x  16 bit char high
;-----------------------------------------------------------------------------
filename_char_internal_to_ucs2:
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
; filename_cp437_to_internal
;
; Convert CP437 character to internal 8 bit encoding (ISO-8859-15)
;
; In:   a  CP437 char
; Out:  a  8 bit char (0= no mapping exists)
;-----------------------------------------------------------------------------
filename_cp437_to_internal:
	cmp #$80
	bcs @5
	cmp #$20
	bcs @2
	cmp #$14
	bne @1
	lda #$b6
	rts
@1:	cmp #$15
	bne @3
	lda #$a7
	rts
@2:	cmp #$7f
	bne @4
@3:	lda #0
@4:	rts
@5:	tax
	lda cp437_to_iso8859_15_tab - $80,x
	rts

;-----------------------------------------------------------------------------
; filename_char_internal_to_cp437
;
; Convert character in internal 8 bit encoding (ISO-8859-15) to CP437
;
; In:   a  8 bit char
; Out:  a  CP437 char (0= no mapping exists)
;-----------------------------------------------------------------------------
filename_char_internal_to_cp437:
	cmp #$20
	bcs @1
	lda #0
	rts
@1:	cmp #$b6
	bne @2
	lda #$14
	rts
@2:	cmp #$a7
	bne @4
	lda #$15
@3:	rts
@4:	cmp #$7f
	bcc @3
	ldx #$80
@5:	cmp cp437_to_iso8859_15_tab - $80,x
	beq @6
	inx
	bne @5
@6:	txa
	rts

cp437_to_iso8859_15_tab:
	.byte $C7,$FC,$E9,$E2,$E4,$E0,$E5,$E7,$EA,$EB,$E8,$EF,$EE,$EC,$C4,$C5
	.byte $C9,$E6,$C6,$F4,$F6,$F2,$FB,$F9,$FF,$D6,$DC,$A2,$A3,$A5,$00,$00
	.byte $E1,$ED,$F3,$FA,$F1,$D1,$AA,$BA,$BF,$00,$AC,$00,$00,$A1,$AB,$BB
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$DF,$00,$00,$00,$00,$B5,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$B1,$00,$00,$00,$00,$F7,$00,$B0,$00,$B7,$00,$00,$B2,$00,$A0

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
	cmp #'/'
	beq @match
	cmp #'?'
	beq @char_match
	cmp #'*'
	beq @asterisk
	jsr to_lower
	sta char_tmp
	lda fat32_dirent + dirent::name, x
	jsr to_lower
	cmp char_tmp
	beq @char_match
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

;
; This is the CP437 -> Unicode mapping
;
; 0,263A,263B,2665,2666,2663,2660,2022,25D8,25CB,25D9,2642,2640,266A,266B,263C,25BA
; 25C4,2195,203C,B6,A7,25AC,21A8,2191,2193,2192,2190,221F,2194,25B2,25BC,20,21,22,23
; 24,25,26,27,28,29,2A,2B,2C,2D,2E,2F,30,31,32,33,34,35,36,37,38,39,3A,3B,3C,3D,3E,3F
; 40,41,42,43,44,45,46,47,48,49,4A,4B,4C,4D,4E,4F,50,51,52,53,54,55,56,57,58,59,5A,5B
; 5C,5D,5E,5F,60,61,62,63,64,65,66,67,68,69,6A,6B,6C,6D,6E,6F,70,71,72,73,74,75,76,77
; 78,79,7A,7B,7C,7D,7E,2302,C7,FC,E9,E2,E4,E0,E5,E7,EA,EB,E8,EF,EE,EC,C4,C5,C9,E6,C6
; F4,F6,F2,FB,F9,FF,D6,DC,A2,A3,A5,20A7,192,E1,ED,F3,FA,F1,D1,AA,BA,BF,2310,AC,BD,BC
; A1,AB,BB,2591,2592,2593,2502,2524,2561,2562,2556,2555,2563,2551,2557,255D,255C,255B
; 2510,2514,2534,252C,251C,2500,253C,255E,255F,255A,2554,2569,2566,2560,2550,256C
; 2567,2568,2564,2565,2559,2558,2552,2553,256B,256A,2518,250C,2588,2584,258C,2590
; 2580,3B1,DF,393,3C0,3A3,3C3,B5,3C4,3A6,398,3A9,3B4,221E,3C6,3B5,2229,2261,B1,2265
; 2264,2320,2321,F7,2248,B0,2219,B7,221A,207F,B2,25A0,A0
