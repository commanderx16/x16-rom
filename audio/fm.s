; Code by Barry Yost (a.k.a. ZeroByte) and MooingLemur
; - 2023
; This file is for code dealing with the YM2151


.include "io.inc" ; for YM2151 addresses

; for file I/O kernal calls
.include "kernal.inc"
readst = $ffb7 ; for some reason this one is commented out in kernal.inc

.importzp azp0, azp0L, azp0H

; BRAM storage
.import ymshadow, returnbank, _PMD
.import ymtmp1, ymtmp2, ym_atten
.import audio_bank_refcnt, audio_prev_bank

.import playstring_len
.import playstring_defnotelen
.import playstring_octave
.import playstring_pos
.import playstring_tempo
.import playstring_voice
.import playstring_art
.import playstring_delayrem

; Pointer to FM patch data indexes
.import patches_lo, patches_hi
.import drum_patches, drum_kc

; Import subroutines
.import notecon_bas2fm

; Import LUTs
.import fm_op_alg_carrier

.export ym_write
.export ym_read
.export ym_loadpatch
.export ym_playnote
.export ym_playdrum
.export ym_setnote
.export ym_trigger
.export ym_release
.export ym_init
.export ym_setatten
.export ym_getatten
.export ym_setdrum
.export ym_loaddefpatches
.export ym_setpan
.export ym_getpan
.export ym_loadpatchlfn

YM_TIMEOUT = 64 ; max value is 128.
MAX_PATCH = 162

.macro PRESERVE_AND_SET_BANK
.scope
	ldy ram_bank
	stz ram_bank
	beq skip_preserve
	sty audio_prev_bank
skip_preserve:
	inc audio_bank_refcnt
.endscope
.endmacro

.macro RESTORE_BANK
.scope
	dec audio_bank_refcnt
	bne skip_restore
	ldy audio_prev_bank
	stz audio_prev_bank
	sty ram_bank
skip_restore:
.endscope
.endmacro

.segment  "CODE"

;---------------------------------------------------------------
; Primary code for writing values into the YM2151 chip. Handles
; the write delay requirements, RAM shadow updates, and any
; modifications for TL values required by attenuation settings.
;---------------------------------------------------------------
; inputs    : .A = value, .X = YM register
; preserves : .A .X
; affects   : .Y
; returns   : .C clear=success, set=timeout
.proc ym_write: near
	; Make re-entrant safe by protecting tmp variables and YM state from interrupt
	php
	sei

	ldy #YM_TIMEOUT
wait:
	dey
	bmi fail
	bit YM_DATA
	bmi wait

	PRESERVE_AND_SET_BANK
	phx
	pha

	stx YM_REG

	; write the value into the YM shadow first, so that if we cook the value
	; later before writing to the chip, we have the original values here
	; but if it's an RLFBCON write, branch elsewhere to handle writing
	; all of the affected TL values if necessary
	cpx #$20
	bcc check_pmdamd
	cpx #$28
	bcc is_rlfbcon
check_pmdamd:
	cpx #$19   ; PMD/AMD register is a special case. Shadow PMD writes into $1A.
	bne storeit
	cmp #$80   ; If value >= $80 then PMD. Store in $1A
	bcc storeit
	sta _PMD
	bra write
is_rlfbcon:
	; go ahead and write it out to the chip now
	sta YM_DATA
	; check to see if we need to reapply the TLs from the shadow
	; then store this value into the shadow
	jmp ym_chk_alg_change
storeit:
	sta ymshadow,X
chk_tl_register:
	; we need to cook the value if we're writing to a TL and we have an attenuation
	; level set for this channel
	cpx #$60
	bcc write
	cpx #$80
	bcs write

	; We're about to write a TL, let's find out what channel this write is for
	; If the write is meant for a TL that is not a carrier, bail out
	; If the write is meant for a TL that is a carrier, but there is no attenuation
	;  then bail out also
	; Otherwise, apply the attenuation value
	pha
	jsr ym_get_channel_from_register
	bcc pla_then_write
	lda ym_atten, x
	beq pla_then_write
	pla

	clc
	adc ym_atten, x
	bpl :+
	lda #$7F
:
	bra write
pla_then_write:
	pla
write:
	; plenty of clocks have passed in between the write to YM_REG
	; so there's definitely no need for NOPs
	sta YM_DATA
done:
	pla
	plx
	RESTORE_BANK
	plp ; restore interrupt flag
	clc
	rts
latefail:
	pla
	plx
	RESTORE_BANK
fail:
	plp ; restore interrupt flag
	sec
	rts
ym_chk_alg_change:
	sta ymtmp1 ; RLFBCON
	and #$07
	sta ymtmp2 ; just the CON portion
	lda ymshadow,x
	and #$07
	tay
	lda ymtmp1
	sta ymshadow,x ; we've finally shadowed this write

	; Is the old ALG the same as the new one? If so, we're done
	cpy ymtmp2
	beq done

	; Put the channel number into X
	txa
	and #$07
	tax

	; If no attenuation is set, we're done
	lda ym_atten,x
	beq done

	; get the register number for the TL into X
	txa
	clc
	adc #$60
	tax

	; reapply M1
	lda ymshadow,x
	jsr ym_write
	bcs latefail

	; reapply M2
	txa
	adc #$08
	tax
	lda ymshadow,x
	jsr ym_write
	bcs latefail

	; reapply C1
	txa
	adc #$08
	tax
	lda ymshadow,x
	jsr ym_write
	bcs latefail

	bra done
.endproc

;---------------------------------------------------------------
; Read FM register value from the RAM shadow.
;---------------------------------------------------------------
; inputs    : .X = YM register  *note that the PMD parameter is shadowed as $1A
;           : .C set   = retrieve TLs with attenuation applied (cooked)
;           :    clear = retrieve raw shadow values (as received by ym_write)
; affects   : .A, .Y
; preserves : .X
; returns   : .A = retrieved value
.proc ym_read: near
	phx
	ldy ram_bank
	stz ram_bank
	lda ymshadow,X
	bcc done
	cpx #$60
	bcc done
	cpx #$80
	bcs done
	pha
	phy
	jsr ym_get_channel_from_register
	ply
	pla
	bcc done ; not a carrier, don't cook
	clc
	adc ym_atten,x
	bpl done ; in range
	lda #$7F ; clamp to $7F
done:
	sty ram_bank
	plx
	rts
.endproc


;---------------------------------------------------------------
; Set the attenuation level for an FM channel.
;---------------------------------------------------------------
; inputs    : .A = YM channel   .X = = attenuation amount (0 is native volume)
; affects   : .Y
; preserves : .A, .X
; returns   : .C clear if success, set if failed
.proc ym_setatten: near
	PRESERVE_AND_SET_BANK
	pha
	phx

	tay
	txa
	; if unchanged, return
	cmp ym_atten,y
	beq end

	sta ym_atten,y

	; get the register number for the TL into X
	tya
	clc
	adc #$60
	tax

	; reapply M1
	lda ymshadow,x
	jsr ym_write
	bcs fail

	; reapply M2
	txa
	adc #$08
	tax
	lda ymshadow,x
	jsr ym_write
	bcs fail

	; reapply C1
	txa
	adc #$08
	tax
	lda ymshadow,x
	jsr ym_write
	bcs fail

	; reapply C2
	txa
	adc #$08
	tax
	lda ymshadow,x
	jsr ym_write
	bcs fail
end:
	RESTORE_BANK
	plx
	pla
	clc
	rts
fail:
	RESTORE_BANK
	plx
	pla
	sec
	rts
.endproc

;-----------------------------------------------------------------
; Retreive current YM attenuation setting
;-----------------------------------------------------------------
; inputs: .A = channel
; affects: .Y
; preserves: .A
; returns: .X = attenuation setting
;
.proc ym_getatten: near
	pha      ; preerve .A
	and #$07 ; mask to channel range 0-7
	tax

	PRESERVE_AND_SET_BANK
	lda ym_atten,x
	RESTORE_BANK

	tax
	pla
	rts
.endproc

;---------------------------------------------------------------
; Initialize the YM2151 with the X16 system default instruments
;---------------------------------------------------------------
; inputs: none
; affects: .A, .X, .Y
; returns: .C: clear=success, set=failed
.proc ym_loaddefpatches: near
	lda #8
loop:
	pha
	tay
	ldx patches,y
	sec
	jsr ym_loadpatch
	pla
	bcs end ; carry is propagated to calling routine
	dec
	bpl loop
	; carry is clear here
end:
	rts
patches:
	.byte 0 ; Acoustic Piano
	.byte 5 ; Electric Piano
	.byte 11 ; Vibraphone
	.byte 35 ; Fretless Bass
	.byte 40 ; Violin
	.byte 56 ; Trumpet
	.byte 76 ; Blown Bottle
	.byte 88 ; Pad 1 "Fantasia"
.endproc

;---------------------------------------------------------------
; Load an instrument patch from ROM bank or from a RAM location
;---------------------------------------------------------------
; inputs:
;   .C clear: .A = channel # .XY = address of patch (little-endian)
;   .C set:   .A = channel # .X = index of ROM patch 0..MAX_PATCH
;
; affects: .A, .X, .Y
; returns: .C: clear=success, set=failed
;
; Note that this routine is not BankRAM-aware. If the patch is in BRAM, then
; it must be entirely contained in a single bank, and that bank must be active
; when the routine is called.
;
.proc ym_loadpatch: near
	; Make re-entrant safe by protecting tmp and pointer variables from interrupt
	php
	sei

	bcc _loadpatch
	pha
	txa
	cmp #(MAX_PATCH+1)
	bcc :+   ; Load the silent patch if we're out of bounds
	lda #$80
:	tax
	lda patches_hi,x
	tay
	lda patches_lo,x
	tax
	pla
_loadpatch:
	and #$07 ; mask channel to range 0..7
	stx azp0L  ; TODO: use the Kernal's tmp1 ZP variable and not ABI
	sty azp0H
	clc
	adc #$20 ; first byte of patch goes to YM:$20+channel
	tax

	; Preserve panning
	;
	; The read from (azp0) could be in an arbitrary banked RAM location,
	; so we must not bank AUDIOBSS/BAUDIO in until after we've read it
	;
	; We first get the incoming patch RLFBCON, and remove the L+R bits,
	; then we bank in AUDIOBSS/BAUDIO so we have access to tmp and the shadow
	; Then we merge L+R from the shadow to the bytes from the patch.
	; Then we can bank out before continuing onward with the rest of the routine
	;
	; Later on, the (azp0),y read will continue out of the bank that was
	; active when we entered ym_loadpatch
	lda (azp0)
	and #$3F

	PRESERVE_AND_SET_BANK
	sta ymtmp1
	lda ymshadow,x
	and #$C0 ; L+R bits for YM channel
	ora ymtmp1 ; Add the patch byte without L+R
	RESTORE_BANK

	jsr ym_write
	bcs fail
	ldy #0
	txa      ; ym_write preserves X (YM register)
	; Now skip over $28 and $30 by adding $10 to the register address.
	; C guaranteed clear by successful ym_write
	adc #$10
	tax      ; set up for loop
next:
	txa
	; C guaranteed clear by successful ym_write
	adc #$08
	bcs success
	iny
	tax
	lda (azp0),y
	phy      ; ym_write clobbers .Y
	jsr ym_write
	ply
	bcc next
fail:
	plp ; restore interrupt flag
	sec
	rts      ; return C set as failed patch write.
success:
	plp ; restore interrupt flag
	clc
	rts
.endproc

;---------------------------------------------------------------
; Load a percussion instrument and KC values into an FM channel
;---------------------------------------------------------------
; inputs: .A = channel, .X = Channel 10 style MIDI note for drum sound
; affects: .A .X .Y
; returns: C set on error
.proc ym_setdrum: near

	phx ; save MIDI note
	and #$07
	pha ; save channel

	; constrain to MIDI note value 0-127
	txa
	and #$7F
	tax

	lda drum_patches,x ; load patch number for drum

	tax

	pla ; load channel
	pha ; resave channel
	sec
	jsr ym_loadpatch
	bcs error

	ply ; restore channel here temporarily
	plx ; restore MIDI note
	lda drum_kc,x ; load KC value for drum sound
	tax
	tya ; set channel
	ldy #0
	jmp ym_setnote
error:
	plx
	pla
	sec
	rts

.endproc

;---------------------------------------------------------------
; Set FM pitch on a channel (both Key code and key fraction)
;---------------------------------------------------------------
; inputs: .A = channel, .X = KC (note)  .Y = KF (key fraction (pitch bend))
; affects: .A .X .Y
; returns: C set on error
.proc ym_setnote: near
	and #$07 ; mask to channel range 0..7
	phx
	phy
	ora #$30 ; select KF register + channel
	tax
	pla
	jsr ym_write
	bcs fail
	txa
	eor #$18 ; switch to register $28+channel (KC - note)
	tax
	pla
	jmp ym_write
fail:
	pla
	sec
	rts
.endproc

;---------------------------------------------------------------
; (re-)Trigger a note on an FM channel
;---------------------------------------------------------------
; inputs: .A: channel  .C: set=no retrigger
; affects: .X .Y
; returns: C set if error
.proc ym_trigger: near
	and #$07      ; mask to channel range 0..7
	ldx #8        ; YM KeyON/OFF control register
	bcs no_retrigger
	jsr ym_write  ; release the channel before retriggering
	bcs fail
no_retrigger:
	ora #$78 ; key-on bits for all 4 operators.
	jsr ym_write
fail:
	rts
.endproc

;---------------------------------------------------------------
; Release an FM channel
;---------------------------------------------------------------
; inputs: .A: channel
; affects: .X .Y
; returns: C set if error
.proc ym_release: near
	and #$07      ; mask to channel range 0..7
	ldx #8        ; YM KeyON/OFF control register
	jmp ym_write
.endproc

;---------------------------------------------------------------
; Set FM KC and KF values and (re-)trigger the note.
;---------------------------------------------------------------
; inputs: .A = channel, .X = note (KC) .Y = note fraction (KF)
;         .C: set=no retrigger, clear=retrigger
; affects: .A .X .Y
; masks channel to range 0-7
.proc ym_playnote: near
	php
	pha
	jsr ym_setnote
	bcs fail
	pla
	plp
	jmp ym_trigger
fail:
	pla ; clear the stack.
	plp
	sec
	rts
.endproc

;---------------------------------------------------------------
; Load percussion patch and trigger it once.
;---------------------------------------------------------------
; inputs: .A = channel, .X = drum note
; affects: .A .X .Y
; masks channel to range 0-7
.proc ym_playdrum: near
	pha
	jsr ym_setdrum
	bcs fail
	pla
	jmp ym_trigger
fail:
	pla ; clear the stack.
	; carry is already set
	rts
.endproc


;---------------------------------------------------------------
; Re-initialize the YM-2151 to default state (everything off)
; Also initializes the audio API internal state variables.
;---------------------------------------------------------------
; inputs: none
; affects: .A .X .Y
; returns: C set on failure
;
.proc ym_init: near
	; Make re-entrant safe by protecting bank varliables from interrupt
	php
	sei

	; explicit initial PRESERVE_AND_SET_BANK
	lda ram_bank
	stz ram_bank
	sta audio_prev_bank
	lda #1
	sta audio_bank_refcnt

	stz playstring_len
	stz playstring_pos
	stz playstring_voice
	stz playstring_delayrem
	lda #120
	sta playstring_tempo
	lda #60
	sta playstring_defnotelen
	lda #4
	sta playstring_octave
	lda #1
	sta playstring_art

	plp ; restore interrupt flag

	; zero out the channel attenuation
	ldx #8
att:
	stz ym_atten-1,x
	dex
	bne att
	RESTORE_BANK

	; set release=max ($0F) for all operators on all channels ($E0..$FF)
	lda #$0f
	ldx #$e0
i1:
	jsr ym_write
	bcs abort       ; YM didn't respond correctly, abort
	inx
	bne i1

	; Release all 8 channels (write values 0..7 into YM register $08)
	lda #7
	ldx #$08
i2:
	jsr ym_write
	dec
	bpl i2

	; reset lfo
	lda #$02
	ldx #$01
	jsr ym_write    ; disable LFO
	lda #$80
	ldx #$19
	jsr ym_write	  ; clear pmd  (amd will be cleared when all regs are zeroed)

	; write 0 into all registers $0F .. $FF
	; except write $C0 into registers $20-$27
	lda #0
	ldx #$0F
i3:
	cpx #$20
	bne i3a
	lda #$C0
	bra i3b
i3a:
	cpx #$28
	bne i3b
	lda #0
i3b:
	jsr ym_write    ; clear everything else $0f..$ff
	inx
	bne i3

	; re-enable LFO
	lda #$00
	ldx #$01
	jsr ym_write
abort:
	rts
.endproc

;---------------------------------------------------------------
; Set FM L/R Panning
;---------------------------------------------------------------
; inputs: .A = channel, .X = pan settings (0=off, 1=Left, 2=Right, 3=Both)
; affects: .A .X .Y
; returns: C set on error
;
.proc ym_setpan: near

	; Make re-entrant safe by protecting tmp variables from interrupt
	php
	sei

	and #$07
	pha ; preserve channel
	txa
	ror
	ror
	ror
	and #$C0

	PRESERVE_AND_SET_BANK

	sta ymtmp1
	pla ; restore channel
	clc
	adc #$20
	tax
	lda ymshadow,x
	and #$3F
	ora ymtmp1

	plp ; restore interrupt flag
	RESTORE_BANK

	jmp ym_write
.endproc

;-----------------------------------------------------------------
; Retreive current YM pan setting
;-----------------------------------------------------------------
; inputs: .A = channel
; affects: .Y
; preserves: .A
; returns: , .X = pan setting (0=off, 1=Left, 2=Right, 3=Both)
;
.proc ym_getpan: near
	pha
	and #$07 ; mask to channel range 0-7
	clc
	adc #$20
	tax

	PRESERVE_AND_SET_BANK
	lda ymshadow,x
	RESTORE_BANK

	rol
	rol
	rol
	and #$03
	tax
	pla
	rts
.endproc

;-----------------------------------------------------------------
; Decode YM register address into the channel it uses (if any)
; and also determine whether this channel is currently a carrier
; operator. (carriers may have their TL tweaked by attenuation settings)
;-----------------------------------------------------------------
; inputs: .X = YM2151 register
;   assumes YMSHADOW/AUDIOBSS is banked in
; affects: .A .Y
; outputs: .X = channel 0-7, or $FF if error (register < $20)
; returns with .C set if operator is a carrier in this alg
;
.proc ym_get_channel_from_register: near
	txa
	tay
	cmp #$20
	bcc fail
	and #$07
	tax ; channel number is safely in .X
	cpy #$40
	bcc end ; carry is clear
	tya
	and #$18

	; Make re-entrant safe by protecting tmp variables from interrupt
	php
	sei

	sta ymtmp1

	lda ymshadow+$20,x ; get the alg (con) out of the shadow
	and #$07
	ora ymtmp1 ; combine it with 8*op

	plp ; restore interrupt flag

	tay
	lda fm_op_alg_carrier,y ; lookup whether operator is a carrier
	ror ; set carry if true
end:
	rts
fail:
	clc
	ldx #$FF
	rts
.endproc

;-----------------------------------------------------------------
; ym_loadpatchlfn
;-----------------------------------------------------------------
; Load a patch from an open file into an FM channel
; Reads 26 bytes out of the open file or until any error
; File remains open after return
;
; inputs: .A = YM channel
;         .X = Logical File Number
; affects: .A .X .Y
; returns: .C  set if error, clear if success
;          .A contains file error if carry is set
; A       ==   0 -> YM error
; A &   3 ==   2 -> Read timeout
; A &   3 ==   3 -> File not open
; A &  64 ==  64 -> EOF
; A & 128 == 128 -> device not present
;-----------------------------------------------------------------
; This re-implements the meat of ym_loadpatch
; but via byte-by-byte file reads instead of from memory
.proc ym_loadpatchlfn: near
	; Make re-entrant safe by protecting tmp variables and channel I/O from interrupt
	php
	sei

	and #$07
	pha

	; We're done with the input .X as soon as we call this
	jsr chkin
	bcs error

	; Get the first byte (the RLFBCON) from the input file
	jsr basin
	pha
	jsr readst
	and #$C2
	bne early_error

	; Pull the L+R bits out of the shadow and OR them with the patch byte
	PRESERVE_AND_SET_BANK
	ply ; patch byte
	pla ; channel number
	clc
	adc #$20 ; RLFBCON
	tax
	lda ymshadow,x
	and #$C0
	sta ymtmp1
	tya
	and #$3F
	ora ymtmp1
	RESTORE_BANK

	; write
	jsr ym_write
	lda #0
	bcs late_error

	txa
	adc #$10
	tax
next:
	txa
	; C guaranteed clear by successful ym_write
	adc #$08
	bcs success
	pha ; push YM register
	jsr basin
	pha ; push value from file
	jsr readst
	and #$C2
	bne early_error
	pla
	plx
	jsr ym_write
	lda #0
	bcc next
	bra late_error
success:
	jsr clrch
	plp ; restore interrupt flag
	clc
	rts
early_error:
	plx
error:
	plx
late_error:
	pha
	jsr clrch
	pla
	plp ; restore interrupt flag
	sec
	rts
.endproc
