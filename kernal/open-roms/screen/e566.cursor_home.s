; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE

;
; Home the cursor, described in:
;
; - [CM64] Computes Mapping the Commodore 64 - page 216
;


cursor_home:

	lda #$00
	sta PNTR                           ; current column (logical)
	sta TBLX                           ; current row

	; FALLTROUGH to the next routine

.assert * = screen_calculate_pointers, error, "cursor_home must fall through to screen_calculate_pointers"
