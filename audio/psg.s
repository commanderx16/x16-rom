; Code by Barry Yost (a.k.a. ZXeroByte)
; - 2022

; This file is for code dealing with the VERA PSG

.include "io.inc" ; for VERA symbols

.importzp azp0, azp0L, azp0H

.export psg_init

;---------------------------------------------------------------
; Re-initialize the VERA PSG to default state (everything off).
;---------------------------------------------------------------
; inputs: none
; affects: .A
; returns: none
;
.proc psg_init: near
  ; save the state of VERA data0 / CTRL registers
  lda VERA_CTRL
  pha
  lda VERA_ADDR_L
  pha
  lda VERA_ADDR_M
  pha
  lda VERA_ADDR_H
  pha

  ; point data0 at PSG registers
  stz VERA_CTRL
  lda #<VERA_PSG_BASE
  sta VERA_ADDR_L
  lda #>VERA_PSG_BASE
  sta VERA_ADDR_M
  lda #(^VERA_PSG_BASE) | $10
  sta VERA_ADDR_H

  ; write zero into all 64 PSG registers.
  lda #64
loop:
  stz VERA_DATA0
  dec
  bne loop

  ; restore VERA data0 / CTRL
  pla
  sta VERA_ADDR_H
  pla
  sta VERA_ADDR_M
  pla
  sta VERA_ADDR_L
  pla
  and #$7F ; clear the VERA reset bit (just in case)
  sta VERA_CTRL
  rts
.endproc
