
.global k_SetColor

.segment "GRAPH"

;---------------------------------------------------------------
; SetColor
;
; Pass:      a primary color (0-255)
;            x secondary color (0-255)
; Return:    k_col1, k_col2 - updated
;---------------------------------------------------------------
k_SetColor:
	sta k_col1   ; primary color
	stx k_col2   ; secondary color
	sty k_col_bg ; background color
	rts


