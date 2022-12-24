; Code by Barry Yost (a.k.a. ZXeroByte)
; - 2022

; This file is for code dealing with the VERA PSG

.include "io.inc" ; for YM2151 addresses

.importzp azp0, azp0L, azp0H

; BRAM storage
.import ymshadow, returnbank, _PMD

; Pointer to FM patch data indexes
.import patches_lo, patches_hi

; Import subroutines
.import notecon_bas2fm

.export ym_write
.export ym_read
.export ym_loadpatch
.export ym_playnote
.export ym_setnote
.export ym_trigger
.export ym_release
.export ym_init

YM_TIMEOUT = 64 ; max value is 128.

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

	; write the value into the YM shadow
	ldy ram_bank
	stz ram_bank
	sty returnbank
	cpx #$19   ; PMD/AMD register is a special case. Shadow PMD writes into $1A.
	bne storeit
	cmp #$80   ; If value >= $80 then PMD. Store in $1A
	bcc storeit
	sta _PMD
	bra done
storeit:
	sta ymshadow,X
done:
	ldy returnbank
	sty ram_bank
	clc
	rts
fail:
	sec
	rts
.endproc

; inputs    : .X = YM register  *note that the PMD parameter is shadowed as $1A
; affects   : .A, .X
; preserves : .X
; returns   : .A = retreived value
.proc ym_read: near
	ldy ram_bank
	stz ram_bank
	lda ymshadow,X
	sty ram_bank
	rts
.endproc



; inputs:
;   .C clear: .A = voice # .XY = address of patch (little-endian)
;   .C set:   .A = voice # .X = index of ROM patch 0..31
;
; affects: .A, .X, .Y
; returns: .C: clear=success, set=failed
;
; Note that this routine is not BankRAM-aware. If the patch is in BRAM, then
; it must be entirely contained in a single bank, and that bank must be active
; when the routine is called.
;
.proc ym_loadpatch: near
	bcc _loadpatch
	pha
	txa
	and #$1F ; mask instrument number to range 0..31
	tax
	lda patches_hi,x
	tay
	lda patches_lo,x
	tax
	pla
_loadpatch:
	and #$07 ; mask voice to range 0..7
	stx azp0L  ; TODO: use the Kernal's tmp1 ZP variable and not ABI
	sty azp0H
	clc
	adc #$20 ; first byte of patch goes to YM:$20+voice
	tax
	lda (azp0)
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
	rts      ; return C set as failed patch write.
success:
	clc
	rts
.endproc

; inputs: .A = voice, .X = KC (note)  .Y = KF (key fraction (pitch bend))
; affects: .A .X .Y
; returns: C set on error
.proc ym_setnote: near
	and #$07 ; mask to voice range 0..7
	phx
	phy
	ora #$30 ; select KF register + voice
	tax
	pla
	jsr ym_write
	bcs fail
	txa
	eor #$18 ; switch to register $28+voice (KC - note)
	tax
	pla
	jmp ym_write
fail:
	pla
	sec
	rts
.endproc

; inputs: .A: voice  .C: set=no retrigger
; affects: .X .Y
; returns: C set if error
.proc ym_trigger: near
	and #$07      ; mask to voice range 0..7
	ldx #8        ; YM KeyON/OFF control register
	bcs no_retrigger
	jsr ym_write  ; release the voice before retriggering
	bcs fail
no_retrigger:
	ora #$78 ; key-on bits for all 4 operators.
	jsr ym_write
fail:
	rts
.endproc

; inputs: .A: voice
; affects: .X .Y
; returns: C set if error
.proc ym_release: near
	and #$07      ; mask to voice range 0..7
	ldx #8        ; YM KeyON/OFF control register
	jmp ym_write
.endproc

; inputs: .A = voice, .X = note (KC) .Y = note fraction (KF)
;         .C: set=no retrigger, clear=retrigger
; affects: .A .X .Y
; masks voice to range 0-7
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
; Re-initialize the YM-2151 to default state (everything off)
;---------------------------------------------------------------
; inputs: none
; affects: .A .X .Y
; returns: C set on failure
;
.proc ym_init: near
	; set release=max ($0F) for all operators on all voices ($E0..$FF)
	lda #$0f
	ldx #$e0
i1:
	jsr ym_write
	bcs abort       ; YM didn't respond correctly, abort
	inx
	bne i1

	; Release all 8 voices (write values 0..7 into YM register $08)
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
	lda #0
	ldx #$0f
i3:
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
