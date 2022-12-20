.include "io.inc" ; for YM2151 addresses

.import patches_lo, patches_hi

.export ym_write
.export ym_loadpatch
.export ym_loadpatch_rom
.export ym_playnote

YM_TIMEOUT = 64 ; max value is 128.

.zeropage
  r0: .res 2
  r0L := r0
  r0H := r0+1

.segment  "CODE"

; inputs    : .A = value, .X = YM register
; affects   : .Y
; preserves : .A .X
; returns   : .C clear=success, set=timeout
.proc ym_write: near
    ldy #YM_TIMEOUT
wait:
    dey
    bmi fail
    bit YM_DATA
    bmi wait
    stx YM_REG
    nop ; slight pause between selecting YM register and writing the value
    nop ; (hw-imposed restriction)
    nop
    nop
    nop
    sta YM_DATA
    clc
    rts
fail:
    sec
    rts
.endproc

; inputs: .A = voice #, .XY = address of patch (little-endian)
; affects: ABI r0
; returns: .C: clear=success, set=failed
;
; Writes first value from patch table to YM:$20, and all remaining values to
; YM:$38, $40, $48, .... $F0, $F8 (+voice # on all registers)

.proc ym_loadpatch_rom: near
    pha
    lda patches_hi,x
    tay
    lda patches_lo,x
    tax
    pla
.endproc
; fall through from _rom load routine into generic one...
.proc ym_loadpatch: near
    cmp #8
    bcs fail ; invalid voice number
		stx	r0L
		sty r0H
    ; C guaranteed clear by cmp #8
		adc	#$20 ; first byte of patch goes to YM:$20+voice
		tax
		lda	(r0)
    jsr ym_write
    bcs fail
		ldy #0
		txa ; ym_write preserves X (YM register)
    ; Now skip over $28 and $30 by adding $10 to the register address.
		; C guaranteed clear by successful ym_write
		adc #$10
    tax ; set up for loop
next:
		txa
    ; C guaranteed clear by successful ym_write
		adc #$08
		bcs	success
		iny
		tax
		lda (r0),y
    phy ; ym_write clobbers .Y
		jsr ym_write
    ply
    bcc next
fail:
		rts ; return C set as failed patch write.
success:
    clc
    rts
.endproc

.proc ym_playnote: near
    cmp #8
    bcs fail ; invalid voice number
		stx	r0L	; note
		sty r0H ; octave
    ; C guaranteed clear by cmp #8
		pha		 ; push the voice to the stack for later
		adc	#$28 ; register for the selected voice
		tax
		lda	r0L
	jsr ym_write
	
	; turn off any playing note
		ldx #$08	; key on/off register
		pla 		; should have 0s in the high 5 bits because of the cmp #8
		sta r0L		; re-use r0L for the channel
	jsr ym_write

	; turn on new note
		clc
		lda #$78
		adc r0L
		; X should have been presevered from the last write
	jsr ym_write
fail:
		rts ; return C set as failed patch write.
success:
    clc
    rts
.endproc
