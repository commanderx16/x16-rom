.export mouse_config, mouse_get, mouse_scan

.segment "PS2MOUSE" ; XXX rename

; mouse
mouse_config:
	rts ; XXX

mouse_scan:
	rts ; XXX

mouse_get:
	lda #0 ; x lo
	sta 0,x
	lda #0 ; x hi
	sta 1,x
	lda #0 ; x lo
	sta 2,x
	lda #0 ; x hi
	sta 3,x
	lda #0 ; buttons
	rts

