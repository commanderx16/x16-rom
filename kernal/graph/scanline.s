; Commander X16 KERNAL
;
; Graphics library: misc

.export graph_init
.export graph_clear
.export GRAPH_LL_set_pixel
.export GRAPH_LL_get_pixel
.export GRAPH_LL_filter_pixels
.export GRAPH_set_window
.export GRAPH_set_options
.export GRAPH_LL_set_pixels
.export GRAPH_LL_get_pixels

.segment "GRAPH"

graph_init:
	LoadW k_dispBufferOn, ST_WR_FORE
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
	
;---------------------------------------------------------------
; GRAPH_set_options
;
; Pass:      a      options
;---------------------------------------------------------------
GRAPH_set_options:
	sta k_dispBufferOn
	rts
	
