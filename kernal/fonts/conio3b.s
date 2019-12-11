; Commander X16 KERNAL
; based on GEOS by Berkeley Softworks; reversed by Maciej Witkowiak, Michael Steil
;
; Font library: init

.export GRAPH_set_font
.export font_init

GRAPH_set_font:
	lda r0L
	ora r0H
	bne set_font2
font_init:
	LoadW r0, SystemFont
set_font2:
	ldy #0
	lda (r0),y
	sta baselineOffset
	iny
	lda (r0),y
	sta curSetWidth
	iny
	lda (r0),y
	sta curSetWidth+1
	iny
	lda (r0),y
	sta curHeight
	iny
	lda (r0),y
	sta curIndexTable
	iny
	lda (r0),y
	sta curIndexTable+1
	iny
	lda (r0),y
	sta cardDataPntr
	iny
	lda (r0),y
	sta cardDataPntr+1
	AddW r0, curIndexTable
	AddW r0, cardDataPntr
	rts
