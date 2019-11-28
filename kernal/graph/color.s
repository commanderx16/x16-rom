; Commander X16 KERNAL
;
; Graphics library: color

.export GRAPH_set_colors

.segment "GRAPH"

;---------------------------------------------------------------
; GRAPH_set_colors
;
; Pass:      a primary color
;            x secondary color
;            y background color
;---------------------------------------------------------------
GRAPH_set_colors:
	sta col1   ; primary color
	stx col2   ; secondary color
	sty col_bg ; background color
	rts
