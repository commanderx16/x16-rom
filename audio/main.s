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
; API calls that leverage them. e.g. ym_loadpatch in order to configure the
; YM2151 with that instrument configuration, or notecon_midi2psg in order to
; get the result of the note table lookup.
;

; imports from fm.s
.import ym_write
.import ym_loadpatch
.import ym_playnote
.import ym_setnote
.import ym_trigger
.import ym_release
.import ym_init
.import ym_read
.import ym_setatten
.import ym_setdrum
.import ym_playdrum
.import ym_loaddefpatches
.import ym_setpan
.import ym_loadpatchlfn

; imports from psg.s
.import psg_init
.import psg_playfreq
.import psg_setvol
.import psg_setatten
.import psg_setfreq
.import psg_write
.import psg_setpan
.import psg_read

; imports from basic.s
.import bas_fmfreq
.import bas_fmnote
.import bas_fmvib
.import bas_psgfreq
.import bas_psgnote
.import bas_psgwav

; imports from noteconvert.s
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
.import notecon_bas2midi
.import notecon_fm2midi
.import notecon_freq2midi
.import notecon_psg2midi

; imports from playstring.s
.import bas_fmplaystring
.import bas_psgplaystring
.import bas_playstringvoice

.segment "API"
	jmp bas_fmfreq            ; $C000
	jmp bas_fmnote            ; $C003
	jmp bas_fmplaystring      ; $C006
	jmp bas_fmvib             ; $C009
	jmp bas_playstringvoice   ; $C00C
	jmp bas_psgfreq           ; $C00F
	jmp bas_psgnote           ; $C012
	jmp bas_psgwav            ; $C015
	jmp bas_psgplaystring     ; $C018
	jmp notecon_bas2fm        ; $C01B
	jmp notecon_bas2midi      ; $C01E
	jmp notecon_bas2psg       ; $C021
	jmp notecon_fm2bas        ; $C024
	jmp notecon_fm2midi       ; $C027
	jmp notecon_fm2psg        ; $C02A
	jmp notecon_freq2bas      ; $C02D
	jmp notecon_freq2fm       ; $C030
	jmp notecon_freq2midi     ; $C033
	jmp notecon_freq2psg      ; $C036
	jmp notecon_midi2bas      ; $C039
	jmp notecon_midi2fm       ; $C03C
	jmp notecon_midi2psg      ; $C03F
	jmp notecon_psg2bas       ; $C042
	jmp notecon_psg2fm        ; $C045
	jmp notecon_psg2midi      ; $C048
	jmp psg_init              ; $C04B
	jmp psg_playfreq          ; $C04E
	jmp psg_read              ; $C051
	jmp psg_setatten          ; $C054
	jmp psg_setfreq           ; $C057
	jmp psg_setpan            ; $C05A
	jmp psg_setvol            ; $C05D
	jmp psg_write             ; $C060
	jmp ym_init               ; $C063
	jmp ym_loaddefpatches     ; $C066
	jmp ym_loadpatch          ; $C069
	jmp ym_loadpatchlfn       ; $C06C
	jmp ym_playdrum           ; $C06F
	jmp ym_playnote           ; $C072
	jmp ym_setatten           ; $C075
	jmp ym_setdrum            ; $C078
	jmp ym_setnote            ; $C07B
	jmp ym_setpan             ; $C07E
	jmp ym_read               ; $C081
	jmp ym_release            ; $C084
	jmp ym_trigger            ; $C087
	jmp ym_write              ; $C08A
