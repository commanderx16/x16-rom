; Code by Barry Yost (a.k.a. ZeroByte), MooingLemur, and Jestin.
; - 2022

; ---------------------------------
; Audio ROM bank for Commander X16.
; ---------------------------------
; This bank contains an API at $C000 for several audio utility functions.
; It also holds data tables such as lookup tables used by the code, and
; a set of FM instrument configurations for ease-of-use by programmers and users
; unfamiliar with FM instrument creation / interfacing the YM2151 chip.
;
; All audio utility routines provided by this bank are self-contained here,
; and thus not included in the main Kernal API. Programs wishing to use the
; audio bank routines will need to either switch ROM banks to the Audio bank
; or else use JSRFAR to call them.
;
; At this time, the actual locations of the FM patches and LUTs are not
; considered to be "directly accessible" and their location is not hard-coded
; into this project. It is intended that programmers should use the published
; API calls that leverage them. e.g. ym_loadpatch_rom in order to configure the
; YM2151 with that instrument configuration, or notecon_midi2psg in order to
; get the result of the note table lookup.
;

; imports from fm.s
.import ym_write, ym_loadpatch, ym_playnote, ym_setnote
.import ym_trigger, ym_release, ym_init, ym_read

; imports from psg.s
.import psg_init

; imports from basic.s
.import bas_fmnote

.import notecon_fm2bas
.import notecon_psg2bas
.import notecon_midi2bas
.import notecon_freq2bas
.import notecon_bas2fm
.import notecon_psg2fm
.import notecon_freq2fm
.import notecon_midi2fm
.import notecon_bas2psg
.import notecon_fm2psg
.import notecon_freq2psg
.import notecon_midi2psg


.segment "API"
	jmp ym_write
	jmp ym_read
	jmp ym_loadpatch
	jmp ym_playnote
	jmp ym_setnote
	jmp ym_trigger
	jmp ym_release
  jmp ym_init

  jmp psg_init

	jmp bas_fmnote

	; note that most of these are stubs that return error (.X and .Y = 0)
	jmp notecon_fm2bas
	jmp notecon_psg2bas
	jmp notecon_midi2bas
	jmp notecon_freq2bas
	jmp notecon_bas2fm
	jmp notecon_psg2fm
	jmp notecon_freq2fm
	jmp notecon_midi2fm
	jmp notecon_bas2psg
	jmp notecon_fm2psg
	jmp notecon_freq2psg
	jmp notecon_midi2psg


.include "banks.inc"
.segment "VECTORS"
 .byt $ff, $ff, $ff, $ff, <banked_irq, >banked_irq
