;----------------------------------------------------------------------
; LZSA2 Decompression
;----------------------------------------------------------------------
; (C)2019 Emmanuel Marty, Peter Ferrie, M. Steil; License: 3-clause BSD

.include "regs.inc"
.include "io.inc"
.include "mac.inc"

.export memory_decompress, memory_decompress_internal

.segment "KVAR"

nibcount:
	.res 1
nibbles:
	.res 1
offslo:	.res 1
offshi:	.res 1

.segment "LZSA"

;---------------------------------------------------------------
; memory_decompress
;
; Function:  Decompress a raw LZSA2 block.
;            Create one with
;              lzsa -r -f2 <original_file> <compressed_file>
;
; Pass:      r0   input address
;            r1   output address
;
; Return:    r1   address of last output byte + 1
;
; Note:      This code is based on decompress_small_v2.asm
;            from https://github.com/emmanuel-marty/lzsa
;            and was modified to work from ROM by rewriting
;            all self-modifying code. The original license
;            can be found at the end of this source file.
;---------------------------------------------------------------
memory_decompress:
	PushW r4
	LoadW r4, ngetsrc
	jsr memory_decompress_internal
	PopW r4
	rts

memory_decompress_internal:
	PushW r2
	PushW r3

	lda r1H
	cmp #IO_PAGE
	beq @1
	LoadW r3, putdst_ram
	bra @2
@1:	LoadW r3, putdst_io
@2:

	ldy #$00
	sty nibcount

decode_token:
	jsr getsrc                      ; read token byte: XYZ|LL|MMM
	pha                             ; preserve token on stack

	and #$18                        ; isolate literals count (LL)
	beq no_literals                 ; skip if no literals to copy
	cmp #$18                        ; LITERALS_RUN_LEN_V2?
	bcc prepare_copy_literals       ; if less, count is directly embedded in token

	jsr getnibble                   ; get extra literals length nibble
					; add nibble to len from token
	adc #$02                        ; (LITERALS_RUN_LEN_V2) minus carry
	cmp #$12                        ; LITERALS_RUN_LEN_V2 + 15 ?
	bcc prepare_copy_literals_direct; if less, literals count is complete

	jsr getsrc                      ; get extra byte of variable literals count
					; the carry is always set by the CMP above
					; GETSRC doesn't change it
	sbc #$ee                        ; overflow?
	jmp prepare_copy_literals_direct

prepare_copy_literals_large:
					; handle 16 bits literals count
					; literals count = directly these 16 bits
	jsr getlargesrc                 ; grab low 8 bits in X, high 8 bits in A
	tay                             ; put high 8 bits in Y
	bcs prepare_copy_literals_high  ; (*same as JMP PREPARE_COPY_LITERALS_HIGH but shorter)

prepare_copy_literals:
	lsr                             ; shift literals count into place
	lsr
	lsr

prepare_copy_literals_direct:
	tax
	bcs prepare_copy_literals_large ; if so, literals count is large

prepare_copy_literals_high:
	txa
	beq copy_literals
	iny

copy_literals:
	jsr getput                      ; copy one byte of literals
	dex
	bne copy_literals
	dey
	bne copy_literals

no_literals:
	pla                             ; retrieve token from stack
	pha                             ; preserve token again
	asl
	bcs repmatch_or_large_offset    ; 1YZ: rep-match or 13/16 bit offset

	asl                             ; 0YZ: 5 or 9 bit offset
	bcs offset_9_bit

					; 00Z: 5 bit offset

	ldx #$ff                        ; set offset bits 15-8 to 1

	jsr getcombinedbits             ; rotate Z bit into bit 0, read nibble for bits 4-1
	ora #$e0                        ; set bits 7-5 to 1
	bne got_offset_lo               ; go store low byte of match offset and prepare match

offset_9_bit:                           ; 01Z: 9 bit offset
	;;asl                           ; shift Z (offset bit 8) in place
	rol
	rol
	and #$01
	eor #$ff                        ; set offset bits 15-9 to 1
	bne got_offset_hi               ; go store high byte, read low byte of match offset and prepare match
					; (*same as JMP GOT_OFFSET_HI but shorter)

repmatch_or_large_offset:
	asl                             ; 13 bit offset?
	bcs repmatch_or_16_bit          ; handle rep-match or 16-bit offset if not

					; 10Z: 13 bit offset

	jsr getcombinedbits             ; rotate Z bit into bit 8, read nibble for bits 12-9
	adc #$de                        ; set bits 15-13 to 1 and substract 2 (to substract 512)
	bne got_offset_hi               ; go store high byte, read low byte of match offset and prepare match
					; (*same as JMP GOT_OFFSET_HI but shorter)

repmatch_or_16_bit:                     ; rep-match or 16 bit offset
	;;asl                           ; XYZ=111?
	bmi rep_match                   ; reuse previous offset if so (rep-match)

					; 110: handle 16 bit offset
	jsr getsrc                      ; grab high 8 bits
got_offset_hi:
	tax
	jsr getsrc                      ; grab low 8 bits
got_offset_lo:
	sta offslo                      ; store low byte of match offset
	stx offshi                      ; store high byte of match offset

rep_match:

; Forward decompression - add match offset

	clc                             ; add dest + match offset
	lda r1L                         ; low 8 bits
	adc offslo
	sta r2L                         ; store back reference address
	lda offshi                      ; high 8 bits
	adc r1H
	sta r2H                         ; store high 8 bits of address

	pla                             ; retrieve token from stack again
	and #$07                        ; isolate match len (MMM)
	adc #$01                        ; add MIN_MATCH_SIZE_V2 and carry
	cmp #$09                        ; MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2?
	bcc prepare_copy_match          ; if less, length is directly embedded in token

	jsr getnibble                   ; get extra match length nibble
					; add nibble to len from token
	adc #$08                        ; (MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2) minus carry
	cmp #$18                        ; MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2 + 15?
	bcc prepare_copy_match          ; if less, match length is complete

	jsr getsrc                      ; get extra byte of variable match length
					; the carry is always set by the CMP above
					; GETSRC doesn't change it
	sbc #$e8                        ; overflow?

prepare_copy_match:
	tax
	bcc prepare_copy_match_y        ; if not, the match length is complete
	beq decompression_done          ; if EOD code, bail

					; Handle 16 bits match length
	jsr getlargesrc                 ; grab low 8 bits in X, high 8 bits in A
	tay                             ; put high 8 bits in Y

prepare_copy_match_y:
	txa
	beq copy_match_loop
	iny

copy_match_loop:
	lda (r2)                        ; get one byte of backreference
	jsr putdst                      ; copy to destination

; Forward decompression -- put backreference bytes forward

	inc r2L
	beq getmatch_adj_hi
getmatch_done:

	dex
	bne copy_match_loop
	dey
	bne copy_match_loop
	jmp decode_token

getmatch_adj_hi:
	inc r2H
	jmp getmatch_done

getcombinedbits:
	eor #$80
	asl
	php

	jsr getnibble                   ; get nibble into bits 0-3 (for offset bits 1-4)
	plp                             ; merge Z bit as the carry bit (for offset bit 0)
combinedbitz:
	rol                             ; nibble -> bits 1-4; carry(!Z bit) -> bit 0 ; carry cleared
	rts

decompression_done:
	PopW r3
	PopW r2
	rts

getnibble:
	lda nibbles
	lsr nibcount
	bcc need_nibbles
	and #$0f                        ; isolate low 4 bits of nibble
	rts

need_nibbles:
	inc nibcount
	jsr getsrc                      ; get 2 nibbles
	sta nibbles
	lsr
	lsr
	lsr
	lsr
	sec
	rts

; Forward decompression -- get and put bytes forward

getput:
	jsr getsrc
putdst:
	jmp (r3)			; dispatch RAM vs. I/O

; Store in RAM and increment
putdst_ram:
	sta (r1)
	inc r1L
	beq :+
	rts
:	inc r1H
	rts

; Store into port in I/O area, assume device auto-increments
putdst_io:
	sta (r1)
	rts

getlargesrc:
	jsr getsrc                      ; grab low 8 bits
	tax                             ; move to X
					; fall through grab high 8 bits

getsrc:
	jmp (r4)

ngetsrc:
	lda (r0)
	inc r0L
	beq :+
	rts
:	inc r0H
	rts

; -----------------------------------------------------------------------------
; Original license of decompress_small_v2.asm follows. For modifications
; in this file, see notes above.
; -----------------------------------------------------------------------------
;  Copyright (C) 2019 Emmanuel Marty, Peter Ferrie
;
;  This software is provided 'as-is', without any express or implied
;  warranty.  In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.
; -----------------------------------------------------------------------------
