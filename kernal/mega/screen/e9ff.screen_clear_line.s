; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; Well-known routine, described in:
;
; - [CM64] Computes Mapping the Commodore 64 - page 219
; - http:;sta.c64.org/cbm64scrfunc.html
;
; input: .X - screen line to clear
;
; Checked that original routine preserves X (convenient for loops),
; and leaves space screen code in .A, so duplicate this behaviour
;


screen_clear_line:

	; First, calculate PNT and USER
	phx_trash_a
	jsr screen_set_position
	plx_trash_a

	; Now clear the line
	ldy #39
:
	ldx COLOR
	jsr screen_set_color
	lda #$20                           ; space character screen code
	jsr screen_set_char
	; MIST: could be optimized, but would break "leaves space screen code in .A"

	dey
	bpl :-

	; Done
	rts
