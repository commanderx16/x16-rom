
.global k_SetColor

.segment "GRAPH"

;---------------------------------------------------------------
; SetColor
;
; Pass:      a primary color (0-255)
;            x secondary color (0-255)
; Return:    col1, col2 - updated
;---------------------------------------------------------------
k_SetColor:
	sta col1   ; primary color
	stx col2   ; secondary color
	sty col_bg ; background color
	rts


