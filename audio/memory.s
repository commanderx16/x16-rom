; Code by Barry Yost (a.k.a. ZeroByte), MooingLemur, and Jestin
; - 2022

; Make memory reservations in this file.

.exportzp azp0, azp0L, azp0H

.export ymshadow, returnbank, _PMD
.export psgfreqtmp, hztmp
.export psgtmp1, psg_atten, psg_volshadow
.export ymtmp1, ymtmp2, ym_atten

.export playstring_len
.export playstring_notelen
.export playstring_octave
.export playstring_pos
.export playstring_tempo
.export playstring_voice
.export playstring_art
.export playstring_tmp1
.export playstring_tmp2
.export playstring_tmp3
.export playstring_tmp4
.export playstring_ymcnt
.export playstring_defnotelen
.export playstring_delayrem

.export audio_prev_bank
.export audio_bank_refcnt

; declare 3 bytes of ZP space for audio routines
.segment "ZPAUDIO": zeropage
	azp0:   .res 2  ; 16bit pointer (in the style of r0, r0L, r0H in ABI)
	azp0L   := azp0
	azp0H   := azp0+1

.segment "AUDIOBSS"
	; noteconvert.s
	psgfreqtmp: .res 2  ; needed temp space for calculating frequencies during some	                   
	hztmp:      .res 2  ; note conversions.


	; psg.s
	psgtmp1:    .res 1  ; tmp for things that happen in psg.s
	psg_atten:  .res 16 ; attenuation levels for the 16 PSG channels
	                    ; AKA inverse channel volume
	psg_volshadow: .res 16 ; we need to shadow the intended volume
	                       ; so changes to psg_atten can be applied

	; fm.s
	ymtmp1:          .res 1  ; needed for scratch in fm.s
	ymtmp2:          .res 1  ; 
	ym_atten:        .res 8  ; attenuation levels for the 8 YM2151 channels

	; playstring.s, reuse some tmp
	playstring_tmp1 := psgfreqtmp+0
	playstring_tmp2 := psgfreqtmp+1
	playstring_tmp3 := hztmp+0
	playstring_tmp4 := hztmp+1
	playstring_ymcnt := psgtmp1 ; used in bas_fmplaystring

	playstring_len:        .res 1 ; length of string
	playstring_pos:        .res 1 ; position within string
	playstring_tempo:      .res 1 ; BPM here
	                              ; note lengths = 240 divided by note type (4=quarter note)
	playstring_notelen:    .res 1 ; transient value for note length, specified after notes
	playstring_defnotelen: .res 1 ; default value for note length, modified by `L` macro
	playstring_octave:     .res 1 ; stored octave 0-7
	playstring_voice:      .res 1 ; voice/channel
	playstring_art:        .res 1 ; amount of space between notes, 0-7
	playstring_delayrem:   .res 1 ; carryover for fractional frame delays

	; shared (for bank mgmt)
	audio_bank_refcnt: .res 1
	audio_prev_bank: .res 1	

; YM2151 is write-only. The library will keep a RAM shadow of writes in order
; to facilitate functionalities like modifying the active values of the chip.
.segment "YMSHADOW"
	ymshadow: .res $100

; define some unused YM registers as extra storage space in the AUDIO page...
; do these need to be symbols, or just a .include file? I'm thinking the latter..
	returnbank := ymshadow + $00 ; for RAM bank-swap return
	_PMD       := ymshadow + $1A ;
