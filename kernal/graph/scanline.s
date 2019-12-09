; Commander X16 KERNAL
;
; Graphics library: misc

.export graph_init
.export graph_clear
.export GRAPH_set_window

.segment "GRAPH"

graph_init:
	rts

graph_clear:
	PushB col1
	MoveB col_bg, col1
	LoadW r0, 0
	LoadB r1L, 0
	LoadW r2, SC_PIX_WIDTH-1
	LoadB r3L, SC_PIX_HEIGHT-1
	lda #0
	jsr GRAPH_draw_rect
	PopB col1
	rts

;---------------------------------------------------------------
; GRAPH_set_window
;
; Pass:      r0     x1
;            r1     y1
;            r2     x2
;            r3     y2
;---------------------------------------------------------------
GRAPH_set_window:
	MoveW r0, leftMargin
	MoveB r1L, windowTop
	MoveW r2, rightMargin
	MoveB r3L, windowBottom
	rts

