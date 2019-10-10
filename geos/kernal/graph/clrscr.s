; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: ClrScr

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.segment "graph1"

.import i_Rectangle
.import SetPattern

.global ClrScr

;---------------------------------------------------------------
; used by EnterDesktop
;---------------------------------------------------------------
ClrScr:
	LoadB dispBufferOn, ST_WR_FORE | ST_WR_BACK
	lda #2
	jsr SetPattern
	jsr i_Rectangle
	.byte 0   ; y1
	.byte SC_PIX_HEIGHT-1 ; y2
	.word 0   ; x1
	.word SC_PIX_WIDTH-1 ; x2
	rts
