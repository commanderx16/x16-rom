;----------------------------------------------------------------------
; C64 Keyboard Driver
;----------------------------------------------------------------------
; (C)2019 Michael Steil, License: 2-clause BSD

.export kbd_clear, kbd_config, kbd_get, kbd_get_modifiers, kbd_get_stop, kbd_put, kbd_scan

.segment "PS2KBD" ; XXX rename

; set kbd layout - do nothing
kbd_config:
	rts

kbd_scan:
	rts ; XXX

kbd_clear:
	rts ; XXX

kbd_put:
	rts ; XXX

kbd_get:
	lda #0 ; XXX
	rts

kbd_get_modifiers:
	lda #0 ; XXX
	rts

kbd_get_stop:
	lda #0 ; XXX
	rts
